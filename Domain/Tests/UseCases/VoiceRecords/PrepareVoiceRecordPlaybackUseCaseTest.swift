@testable import Domain
import XCTest

final class PrepareVoiceRecordPlaybackUseCaseTest: XCTestCase {}

extension PrepareVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_prepare호출시_preparedPlayback을반환한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPrepareVoiceRecordPlaybackUseCase(repository: repository)
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        let stream = AsyncStream<AudioPlaybackState> { continuation in
            continuation.yield(.stub(duration: 42))
            continuation.finish()
        }
        await repository.setPrepareResult(.success(stream))
        await repository.expectPrepare(callCount: 1)

        let result = try await sut.execute(audioFileURL: audioURL)
        let preparedAudioFileURL = await repository.preparedAudioFileURL
        var iterator = result.makeAsyncIterator()
        let initialState = await iterator.next()

        XCTAssertEqual(initialState, .stub(duration: 42))
        XCTAssertEqual(preparedAudioFileURL, audioURL)
        await repository.verify()
    }

    func test_리포지토리prepare실패상태_prepare호출시_prepareFailed에러를던진다() async {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPrepareVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setPrepareResult(.failure(.prepareFailed))
        await repository.expectPrepare(callCount: 1)

        do {
            _ = try await sut.execute(audioFileURL: URL(fileURLWithPath: "/tmp/test.m4a"))
            XCTFail("PrepareVoiceRecordPlaybackUseCaseError.prepareFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .prepareFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await repository.verify()
    }
}
