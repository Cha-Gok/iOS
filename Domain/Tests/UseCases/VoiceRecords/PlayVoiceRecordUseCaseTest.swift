@testable import Domain
import XCTest

final class PlayVoiceRecordUseCaseTest: XCTestCase {}

extension PlayVoiceRecordUseCaseTest {
    func test_정상상태_play호출시_repositoryPlay를호출한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPlayVoiceRecordUseCase(repository: repository)
        await repository.setPlayResult(.success(()))
        await repository.expectPlay(callCount: 1)

        try await sut.execute()

        await repository.verify()
    }

    func test_리포지토리play실패상태_play호출시_playFailed에러를던진다() async {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultPlayVoiceRecordUseCase(repository: repository)
        await repository.setPlayResult(.failure(.playFailed))
        await repository.expectPlay(callCount: 1)

        do {
            try await sut.execute()
            XCTFail("PlayVoiceRecordUseCaseError.playFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .playFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await repository.verify()
    }
}
