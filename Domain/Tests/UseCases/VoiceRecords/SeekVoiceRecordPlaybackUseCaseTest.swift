@testable import Domain
import DomainTesting
import XCTest

final class SeekVoiceRecordPlaybackUseCaseTest: XCTestCase {}

extension SeekVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_seek호출시_repositorySeek를호출한다() async throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultSeekVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setSeekResult(.success(()))
        await repository.expectSeek(callCount: 1)

        try await sut.execute(time: 15)
        let lastSeekTime = await repository.lastSeekTime

        XCTAssertEqual(lastSeekTime, 15)
        await repository.verify()
    }

    func test_리포지토리seek실패상태_seek호출시_seekFailed에러를던진다() async {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultSeekVoiceRecordPlaybackUseCase(repository: repository)
        await repository.setSeekResult(.failure(.seekFailed))
        await repository.expectSeek(callCount: 1)

        do {
            try await sut.execute(time: 15)
            XCTFail("SeekVoiceRecordPlaybackUseCaseError.seekFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .seekFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await repository.verify()
    }
}
