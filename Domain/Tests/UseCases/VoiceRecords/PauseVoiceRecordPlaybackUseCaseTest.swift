@testable import Domain
import XCTest

final class PauseVoiceRecordPlaybackUseCaseTest: XCTestCase {}

extension PauseVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_pause호출시_repositoryPause를호출한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPauseVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setPauseResult(.success(()))
        await repository.expectPause(callCount: 1)

        try await sut.execute()

        await repository.verify()
    }

    func test_리포지토리pause실패상태_pause호출시_pauseFailed에러를던진다() async {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPauseVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setPauseResult(.failure(.pauseFailed))
        await repository.expectPause(callCount: 1)

        do {
            try await sut.execute()
            XCTFail("PauseVoiceRecordPlaybackUseCaseError.pauseFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .pauseFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await repository.verify()
    }
}
