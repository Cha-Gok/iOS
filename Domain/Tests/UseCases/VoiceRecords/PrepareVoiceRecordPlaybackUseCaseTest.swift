@testable import Domain
import DomainTesting
import XCTest

@MainActor
final class PrepareVoiceRecordPlaybackUseCaseTest: XCTestCase {}

@MainActor
extension PrepareVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_prepare호출시_preparedPlayback을반환한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPrepareVoiceRecordPlaybackUseCase(repository: repository)
        let audioFilePath = "VoiceRecords/test.m4a"
        let stream = AsyncStream<AudioPlaybackState> { continuation in
            continuation.yield(.stub(duration: 42))
            continuation.finish()
        }
        repository.setPrepareResult(.success(stream))
        repository.expectPrepare(callCount: 1)

        let result = try sut.execute(audioFilePath: audioFilePath)
        let preparedAudioFilePath = repository.preparedAudioFilePath
        var iterator = result.makeAsyncIterator()
        let initialState = await iterator.next()

        XCTAssertEqual(initialState, .stub(duration: 42))
        XCTAssertEqual(preparedAudioFilePath, audioFilePath)
        repository.verify()
    }

    func test_리포지토리prepare실패상태_prepare호출시_prepareFailed에러를던진다() {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPrepareVoiceRecordPlaybackUseCase(repository: repository)
        repository.setPrepareResult(.failure(.prepareFailed))
        repository.expectPrepare(callCount: 1)

        do {
            _ = try sut.execute(audioFilePath: "VoiceRecords/test.m4a")
            XCTFail("PrepareVoiceRecordPlaybackUseCaseError.prepareFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .prepareFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        repository.verify()
    }
}
