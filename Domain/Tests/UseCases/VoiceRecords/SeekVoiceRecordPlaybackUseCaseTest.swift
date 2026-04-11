@testable import Domain
import DomainTesting
import XCTest

@MainActor
final class SeekVoiceRecordPlaybackUseCaseTest: XCTestCase {}

@MainActor
extension SeekVoiceRecordPlaybackUseCaseTest {
    func test_정상상태_seek호출시_repositorySeek를호출한다() throws {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultSeekVoiceRecordPlaybackUseCase(repository: repository)
        repository.setSeekResult(.success(()))
        repository.expectSeek(callCount: 1)

        try sut.execute(time: 15)
        let lastSeekTime = repository.lastSeekTime

        XCTAssertEqual(lastSeekTime, 15)
        repository.verify()
    }

    func test_리포지토리seek실패상태_seek호출시_seekFailed에러를던진다() {
        let repository = MockVoiceRecordPlaybackRepository()
        let sut = DefaultSeekVoiceRecordPlaybackUseCase(repository: repository)
        repository.setSeekResult(.failure(.seekFailed))
        repository.expectSeek(callCount: 1)

        do {
            try sut.execute(time: 15)
            XCTFail("SeekVoiceRecordPlaybackUseCaseError.seekFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .seekFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        repository.verify()
    }
}
