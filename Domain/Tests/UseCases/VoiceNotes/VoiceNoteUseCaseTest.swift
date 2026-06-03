@testable import Domain
import Core
import DomainTesting
import XCTest

@MainActor
final class VoiceNoteUseCaseTest: XCTestCase {
    private struct SUT {
        let useCase: VoiceNoteUseCase
        let repository: MockVoiceNoteRepository
        let folderRepository: MockFolderRepository
        let analysisService: MockVoiceNoteAnalysisService
    }

    private func makeSUT() -> SUT {
        let repository = MockVoiceNoteRepository()
        let folderRepository = MockFolderRepository()
        let analysisService = MockVoiceNoteAnalysisService()
        let useCase = DefaultVoiceNoteUseCase(
            repository: repository,
            folderRepository: folderRepository,
            analysisService: analysisService
        )
        return SUT(
            useCase: useCase,
            repository: repository,
            folderRepository: folderRepository,
            analysisService: analysisService
        )
    }
}

// MARK: - Create

extension VoiceNoteUseCaseTest {
    func test_create_정상호출시_리포지토리를호출하고결과를반환한다() throws {
        let sut = makeSUT()
        let voiceRecord = VoiceRecord.stub()
        let defaultFolder = Folder.stub(name: "기본 폴더", kind: .default)
        let expectedNote = VoiceNote.stub(voiceRecord: voiceRecord)

        sut.folderRepository.setFetchByKindResult(.default, result: .success([defaultFolder]))
        sut.repository.setCreateResult(.success(expectedNote))
        sut.repository.expectCreate(callCount: 1)
        sut.analysisService.expectEnqueue(callCount: 1)

        let result = try sut.useCase.create(voiceRecord)

        XCTAssertEqual(result.id, expectedNote.id)
        sut.repository.verify()
        sut.analysisService.verify()
    }
}

// MARK: - Update

extension VoiceNoteUseCaseTest {
    func test_update_제목이비어있으면_invalidTitle에러를던진다() {
        let sut = makeSUT()
        let voiceNote = VoiceNote.stub(title: "")

        do {
            _ = try sut.useCase.update(voiceNote)
            XCTFail("에러가 발생해야 합니다.")
        } catch {
            guard case VoiceNoteUseCaseError.invalidTitle = error else {
                return XCTFail("잘못된 에러 타입: \(error)")
            }
        }
    }

    func test_update_정상호출시_리포지토리를호출하고결과를반환한다() throws {
        let sut = makeSUT()
        let voiceNote = VoiceNote.stub(title: "수정된 제목")
        sut.repository.setUpdateResult(.success(voiceNote))
        sut.repository.expectUpdate(callCount: 1)

        let result = try sut.useCase.update(voiceNote)

        XCTAssertEqual(result.title, "수정된 제목")
        sut.repository.verify()
    }
}

// MARK: - Regenerate

extension VoiceNoteUseCaseTest {
    func test_regenerateSummary_호출시_분석서비스의regenerate를호출한다() {
        let sut = makeSUT()
        let id = UUID()
        sut.analysisService.expectRegenerate(callCount: 1)

        sut.useCase.regenerateSummary(id: id)

        sut.analysisService.verify()
    }
}
