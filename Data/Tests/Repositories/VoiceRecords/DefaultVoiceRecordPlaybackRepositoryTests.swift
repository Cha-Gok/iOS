@testable import Data
import Domain
import XCTest

final class DefaultVoiceRecordPlaybackRepositoryTests: XCTestCase {}

extension DefaultVoiceRecordPlaybackRepositoryTests {
    func test_prepare호출시_servicePrepare를호출하고결과를반환한다() async throws {
        let service = MockAudioPlaybackService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service)
        let stream = AsyncStream<AudioPlaybackState> { continuation in
            continuation.yield(.init(status: .idle, currentTime: 0, duration: 90))
            continuation.finish()
        }
        let audioURL = URL(fileURLWithPath: "/tmp/playback.m4a")
        await service.setPrepareResult(.success(stream))
        await service.expectPrepare(callCount: 1)

        let result = try await sut.prepare(audioFileURL: audioURL)
        let preparedURL = await service.preparedURL
        var iterator = result.makeAsyncIterator()
        let initialState = await iterator.next()

        XCTAssertEqual(initialState, .init(status: .idle, currentTime: 0, duration: 90))
        XCTAssertEqual(preparedURL, audioURL)
        await service.verify()
    }

    func test_play실패시_repositoryError로매핑한다() async {
        let service = MockAudioPlaybackService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service)
        await service.setPlayResult(.failure(.playFailed))
        await service.expectPlay(callCount: 1)

        do {
            try await sut.play()
            XCTFail("VoiceRecordPlaybackRepositoryError.playFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .playFailed = error else {
                return XCTFail("예상한 에러와 다릅니다: \(error)")
            }
        }

        await service.verify()
    }

    func test_seek호출시_serviceSeek를호출한다() async throws {
        let service = MockAudioPlaybackService()
        let sut = DefaultVoiceRecordPlaybackRepository(audioPlaybackService: service)
        await service.setSeekResult(.success(()))
        await service.expectSeek(callCount: 1)

        try await sut.seek(to: 15)
        let lastSeekTime = await service.lastSeekTime

        XCTAssertEqual(lastSeekTime, 15)
        await service.verify()
    }
}
