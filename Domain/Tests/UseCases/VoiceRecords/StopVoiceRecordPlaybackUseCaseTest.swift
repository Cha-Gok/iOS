@testable import Domain
import DomainTesting
import XCTest

final class StopVoiceRecordPlaybackUseCaseTest: XCTestCase {}

extension StopVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_stop호출시_repositoryStop을호출한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultStopVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setStopResult(.success(()))
        await repository.expectStop(callCount: 1)

        try await sut.execute()

        await repository.verify()
    }

    func test_리포지토리stop실패상태_stop호출시_stopFailed에러를던진다() async {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultStopVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setStopResult(.failure(.stopFailed))
        await repository.expectStop(callCount: 1)

        do {
            try await sut.execute()
            XCTFail("StopVoiceRecordPlaybackUseCaseError.stopFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .stopFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await repository.verify()
    }
}
