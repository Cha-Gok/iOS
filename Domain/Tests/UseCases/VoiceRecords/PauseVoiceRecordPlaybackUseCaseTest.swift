@testable import Domain
import DomainTesting
import XCTest

@MainActor
final class PauseVoiceRecordPlaybackUseCaseTest: XCTestCase {}

@MainActor
extension PauseVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_pause호출시_repositoryPause를호출한다() throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPauseVoiceRecordPlaybackUseCase(repository: repository)
        repository.setPauseResult(.success(()))
        repository.expectPause(callCount: 1)

        try sut.execute()

        repository.verify()
    }

    func test_리포지토리pause실패상태_pause호출시_pauseFailed에러를던진다() {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPauseVoiceRecordPlaybackUseCase(repository: repository)
        repository.setPauseResult(.failure(.pauseFailed))
        repository.expectPause(callCount: 1)

        do {
            try sut.execute()
            XCTFail("PauseVoiceRecordPlaybackUseCaseError.pauseFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .pauseFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        repository.verify()
    }
}
