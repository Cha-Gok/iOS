@testable import Domain
import DomainTesting
import XCTest

@MainActor
final class PlayVoiceRecordUseCaseTest: XCTestCase {}

@MainActor
extension PlayVoiceRecordUseCaseTest {
    func test_정상상태_play호출시_repositoryPlay를호출한다() throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPlayVoiceRecordUseCase(repository: repository)
        repository.setPlayResult(.success(()))
        repository.expectPlay(callCount: 1)

        try sut.execute()

        repository.verify()
    }

    func test_리포지토리play실패상태_play호출시_playFailed에러를던진다() {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPlayVoiceRecordUseCase(repository: repository)
        repository.setPlayResult(.failure(.playFailed))
        repository.expectPlay(callCount: 1)

        do {
            try sut.execute()
            XCTFail("PlayVoiceRecordUseCaseError.playFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .playFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        repository.verify()
    }
}
