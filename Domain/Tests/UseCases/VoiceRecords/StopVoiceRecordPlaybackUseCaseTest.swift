@testable import Domain
import DomainTesting
import XCTest

@MainActor
final class StopVoiceRecordPlaybackUseCaseTest: XCTestCase {}

@MainActor
extension StopVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_stop호출시_repositoryStop을호출한다() throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultStopVoiceRecordPlaybackUseCase(repository: repository)
        repository.setStopResult(.success(()))
        repository.expectStop(callCount: 1)

        try sut.execute()

        repository.verify()
    }

    func test_리포지토리stop실패상태_stop호출시_stopFailed에러를던진다() {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultStopVoiceRecordPlaybackUseCase(repository: repository)
        repository.setStopResult(.failure(.stopFailed))
        repository.expectStop(callCount: 1)

        do {
            try sut.execute()
            XCTFail("StopVoiceRecordPlaybackUseCaseError.stopFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .stopFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        repository.verify()
    }
}
