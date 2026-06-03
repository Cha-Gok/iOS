@testable import Presentation
import Domain
import DomainTesting
import Foundation
import XCTest

@MainActor
final class VoiceNoteViewModelSearchTest: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: VoiceNoteViewModel
        let playbackRepository: FakeVoiceRecordPlaybackRepository
    }

    private func makeSUT(
        summary: Summary? = Summary(
            text: "채용 시장의 변화\n이력서 작성 팁\n면접 기출 질문"
        ),
        transcript: Transcript? = Transcript(sections: [
            TranscriptSection(timestamp: 0, text: "채용 공고에 대한 이야기를 나눴습니다."),
            TranscriptSection(timestamp: 30, text: "요즘 채용 시장에서 채용 공고 수가 줄었다고 합니다."),
            TranscriptSection(timestamp: 90, text: "면접 관련 논의는 다음 회의에서 이어갑니다.")
        ]),
        keywords: [Keyword] = [
            Keyword(noteID: UUID(), word: "채용시장"),
            Keyword(noteID: UUID(), word: "이력서"),
            Keyword(noteID: UUID(), word: "면접")
        ],
        analysisState: AnalysisState = .completed
    ) -> SUT {
        let noteID = UUID()
        let mappedKeywords = keywords.map { Keyword(noteID: noteID, word: $0.word) }

        let voiceNote = VoiceNote.stub(
            id: noteID,
            title: "검색 테스트 노트",
            keywords: mappedKeywords,
            transcript: transcript,
            summary: summary,
            analysisState: analysisState
        )

        let playbackRepository = FakeVoiceRecordPlaybackRepository()

        let viewModel = VoiceNoteViewModel(
            voiceNote: voiceNote,
            voiceNoteUseCase: FakeVoiceNoteUseCase(voiceNote: voiceNote),
            folderUseCase: FakeFolderUseCase(),
            playbackRepository: playbackRepository,
            availableSupportModelRepository: FakeAvailableModelSupportRepository()
        )

        return SUT(viewModel: viewModel, playbackRepository: playbackRepository)
    }

    /// 플레이백 스트림이 초기 상태를 yield하고 ViewModel이 반영할 때까지 대기합니다.
    private func activatePlayback(
        _ sut: SUT,
        status: AudioPlaybackState.Status
    ) async {
        sut.playbackRepository.initialStatus = status
        sut.viewModel.onAppear()
        // AsyncStream의 yield가 ViewModel의 currentPlaybackState에 반영될 때까지 대기
        for _ in 0 ..< 20 where sut.viewModel.currentPlaybackState.status != status {
            await Task.yield()
        }
    }
}

// MARK: - 검색 모드 진입/종료

extension VoiceNoteViewModelSearchTest {
    func test_초기상태_searchMode가false이고_matchIndex는0이다() {
        // Given/When
        let sut = makeSUT()

        // Then
        XCTAssertFalse(sut.viewModel.searchMode)
        XCTAssertEqual(sut.viewModel.searchQuery, "")
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)
        XCTAssertTrue(sut.viewModel.summaryMatches.isEmpty)
        XCTAssertTrue(sut.viewModel.scriptMatches.isEmpty)
    }

    func test_검색모드진입시_재생중이면_pause된다() async {
        // Given
        let sut = makeSUT()
        await activatePlayback(sut, status: .playing)
        let pausesBefore = sut.playbackRepository.pauseCallCount

        // When
        sut.viewModel.enterSearchMode()

        // Then
        XCTAssertTrue(sut.viewModel.searchMode)
        XCTAssertEqual(sut.playbackRepository.pauseCallCount - pausesBefore, 1)
    }

    func test_검색모드종료시_재생중이었어도_재생을호출하지않는다() async {
        // Given
        let sut = makeSUT()
        await activatePlayback(sut, status: .playing)
        sut.viewModel.enterSearchMode()
        let playsBefore = sut.playbackRepository.playCallCount

        // When
        sut.viewModel.exitSearchMode()

        // Then
        XCTAssertFalse(sut.viewModel.searchMode)
        XCTAssertEqual(sut.viewModel.searchQuery, "")
        XCTAssertEqual(sut.playbackRepository.playCallCount - playsBefore, 0)
    }

    func test_검색모드종료시_재생중이아니었으면_재생을호출하지않는다() async {
        // Given
        let sut = makeSUT()
        await activatePlayback(sut, status: .idle)
        sut.viewModel.enterSearchMode()
        let playsBefore = sut.playbackRepository.playCallCount

        // When
        sut.viewModel.exitSearchMode()

        // Then
        XCTAssertEqual(sut.playbackRepository.playCallCount - playsBefore, 0)
    }
}

// MARK: - 매치 계산

extension VoiceNoteViewModelSearchTest {
    func test_검색쿼리가비어있으면_매치가0개다() {
        // Given
        let sut = makeSUT()

        // When
        sut.viewModel.enterSearchMode()

        // Then
        XCTAssertTrue(sut.viewModel.summaryMatches.isEmpty)
        XCTAssertTrue(sut.viewModel.scriptMatches.isEmpty)
    }

    func test_대소문자다른쿼리로도_매치를찾는다() {
        // Given
        let sut = makeSUT(
            transcript: Transcript(sections: [
                TranscriptSection(timestamp: 0, text: "iOS와 ios 모두 표기됩니다.")
            ])
        )
        sut.viewModel.enterSearchMode()

        // When
        sut.viewModel.updateCurrentPage(.script)
        sut.viewModel.updateSearchQuery("ios")

        // Then
        XCTAssertEqual(sut.viewModel.scriptMatches.count, 2)
    }

    func test_핵심포인트와키워드에서만_요약매치가계산된다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()

        // When
        sut.viewModel.updateSearchQuery("채용")

        // Then
        // 핵심 포인트 "채용 시장의 변화"에서 1건, 키워드 "채용시장"에서 1건
        // (keywords는 정렬되므로 "면접","이력서","채용시장" 순 → "채용시장"은 index 2)
        XCTAssertEqual(sut.viewModel.summaryMatches.count, 2)

        guard sut.viewModel.summaryMatches.count == 2 else { return }
        XCTAssertEqual(sut.viewModel.summaryMatches[0].location, .keyPoint(index: 0))
        XCTAssertEqual(sut.viewModel.summaryMatches[1].location, .keyword(index: 2))
    }

    func test_스크립트매치는_섹션순서와내부위치순서로정렬된다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()

        // When
        sut.viewModel.updateSearchQuery("채용")

        // Then
        // 섹션 0: 1개, 섹션 1: 2개 (채용 시장에서 / 채용 공고) → 총 3
        let matches = sut.viewModel.scriptMatches
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].location, .script(sectionIndex: 0))
        XCTAssertEqual(matches[1].location, .script(sectionIndex: 1))
        XCTAssertEqual(matches[2].location, .script(sectionIndex: 1))
        XCTAssertLessThan(matches[1].range.location, matches[2].range.location)
    }
}

// MARK: - 매치 이동

extension VoiceNoteViewModelSearchTest {
    func test_다음매치이동시_인덱스가순환한다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()
        sut.viewModel.updateCurrentPage(.script)
        sut.viewModel.updateSearchQuery("채용") // 3개

        // When / Then
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)

        sut.viewModel.nextMatch()
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 1)

        sut.viewModel.nextMatch()
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 2)

        sut.viewModel.nextMatch()
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)
    }

    func test_이전매치이동시_첫매치에서_마지막으로순환한다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()
        sut.viewModel.updateCurrentPage(.script)
        sut.viewModel.updateSearchQuery("채용") // 3개

        // When
        sut.viewModel.previousMatch()

        // Then
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 2)
    }

    func test_매치가없으면_next및previous는noop이다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()
        sut.viewModel.updateSearchQuery("절대없는단어xyz")

        // When
        sut.viewModel.nextMatch()
        sut.viewModel.previousMatch()

        // Then
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)
    }

    func test_페이지전환시_currentMatchIndex가0으로리셋된다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()
        sut.viewModel.updateSearchQuery("채용")
        sut.viewModel.nextMatch() // index = 1

        // When
        sut.viewModel.updateCurrentPage(.script)

        // Then
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)
    }

    func test_검색쿼리변경시_currentMatchIndex가0으로리셋된다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.enterSearchMode()
        sut.viewModel.updateSearchQuery("채용")
        sut.viewModel.nextMatch() // 1

        // When
        sut.viewModel.updateSearchQuery("면접")

        // Then
        XCTAssertEqual(sut.viewModel.currentMatchIndex, 0)
    }
}

// MARK: - Fakes

@MainActor
private final class FakeVoiceRecordPlaybackRepository: VoiceRecordPlaybackRepository {
    var initialStatus: AudioPlaybackState.Status = .idle
    var playCallCount = 0
    var pauseCallCount = 0
    var seekCallCount = 0
    var stopCallCount = 0

    func prepare(audioFilePath _: String) throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        let status = initialStatus
        return AsyncStream { continuation in
            continuation.yield(AudioPlaybackState(status: status, currentTime: 0, duration: 100))
            continuation.finish()
        }
    }

    func play() throws(VoiceRecordPlaybackRepositoryError) {
        playCallCount += 1
    }

    func pause() throws(VoiceRecordPlaybackRepositoryError) {
        pauseCallCount += 1
    }

    func seek(to _: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {
        seekCallCount += 1
    }

    func stop() throws(VoiceRecordPlaybackRepositoryError) {
        stopCallCount += 1
    }
}

private struct FakeVoiceNoteUseCase: VoiceNoteUseCase {
    let voiceNote: VoiceNote

    func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
        VoiceNote.stub(voiceRecord: voiceRecord)
    }

    func fetch(byId _: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
        voiceNote
    }

    func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
        voiceNote
    }

    func observe(id _: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
        AsyncStream { continuation in
            continuation.yield(voiceNote)
            continuation.finish()
        }
    }

    func observe(folderID _: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        AsyncStream { continuation in
            continuation.yield([voiceNote])
            continuation.finish()
        }
    }

    func observeRecent(limit _: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        AsyncStream { continuation in
            continuation.yield([voiceNote])
            continuation.finish()
        }
    }

    func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        AsyncStream { $0.finish() }
    }

    func regenerateSummary(id _: UUID) {}

    func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
    func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
    func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
}

private struct FakeFolderUseCase: FolderUseCase {
    func create(name: String) throws(FolderUseCaseError) -> Folder {
        Folder(name: name, kind: .custom)
    }

    func createDefault() throws(FolderUseCaseError) -> Folder {
        Folder(name: "기본 폴더", kind: .default)
    }

    func createTrash() throws(FolderUseCaseError) -> Folder {
        Folder(name: "휴지통", kind: .trash)
    }

    func fetchAll() throws(FolderUseCaseError) -> [Folder] {
        [Folder(name: "기본 폴더", kind: .default)]
    }

    func fetchDefault() throws(FolderUseCaseError) -> Folder {
        Folder(name: "기본 폴더", kind: .default)
    }

    func fetchTrash() throws(FolderUseCaseError) -> Folder {
        Folder(name: "휴지통", kind: .trash)
    }

    func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
        []
    }

    func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
        Folder(name: "기본 폴더", kind: .default)
    }

    func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
        folder
    }

    func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
        AsyncStream { $0.finish() }
    }

    func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
    func restore(folderID _: UUID) throws(FolderUseCaseError) {}
    func delete(folderID _: UUID) throws(FolderUseCaseError) {}
}

private struct FakeAvailableModelSupportRepository: AvailableModelSupportRepository {
    func checkMLXSupportModel() async -> ChaGokModelSupport {
        ChaGokModelSupport(ramSizeGB: 8, isProUser: false)
    }

    func fetchSupportModels() async -> [ChaGokModelState] {
        []
    }
}
