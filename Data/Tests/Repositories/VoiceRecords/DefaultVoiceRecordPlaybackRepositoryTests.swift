@testable import Data
import Domain
import XCTest

@MainActor
final class DefaultVoiceRecordPlaybackRepositoryTests: XCTestCase {}

@MainActor
extension DefaultVoiceRecordPlaybackRepositoryTests {
    func test_prepare호출시_servicePrepare를호출하고결과를반환한다() async throws {
        let service = MockAudioPlaybackService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service, storageService: storageService)
        let stream = AsyncStream<AudioPlaybackState> { continuation in
            continuation.yield(.init(status: .idle, currentTime: 0, duration: 90))
            continuation.finish()
        }
        let audioFilePath = "VoiceRecords/playback.m4a"
        let expectedAbsoluteURL = storageService.absoluteURL(for: audioFilePath)
        service.setPrepareResult(.success(stream))
        service.expectPrepare(callCount: 1)

        let result = try sut.prepare(audioFilePath: audioFilePath)
        let preparedURL = service.preparedURL
        var iterator = result.makeAsyncIterator()
        let initialState = await iterator.next()

        XCTAssertEqual(initialState, .init(status: .idle, currentTime: 0, duration: 90))
        XCTAssertEqual(preparedURL, expectedAbsoluteURL)
        service.verify()
    }

    func test_play실패시_repositoryError로매핑한다() {
        let service = MockAudioPlaybackService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service, storageService: MockStorageService())
        service.setPlayResult(.failure(.playFailed))
        service.expectPlay(callCount: 1)

        do {
            try sut.play()
            XCTFail("VoiceRecordPlaybackRepositoryError.playFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .playFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        service.verify()
    }

    func test_seek호출시_serviceSeek를호출한다() throws {
        let service = MockAudioPlaybackService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service, storageService: MockStorageService())
        service.setSeekResult(.success(()))
        service.expectSeek(callCount: 1)

        try sut.seek(to: 15)
        let lastSeekTime = service.lastSeekTime

        XCTAssertEqual(lastSeekTime, 15)
        service.verify()
    }
}
