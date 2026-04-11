@testable import Domain
import XCTest

@MainActor
public final class MockVoiceRecordPlaybackRepository: VoiceRecordPlaybackRepository {
    public init() {}

    private var prepareResult: Result<AsyncStream<AudioPlaybackState>, VoiceRecordPlaybackRepositoryError>?
    private var playResult: Result<Void, VoiceRecordPlaybackRepositoryError>?
    private var pauseResult: Result<Void, VoiceRecordPlaybackRepositoryError>?
    private var seekResult: Result<Void, VoiceRecordPlaybackRepositoryError>?
    private var stopResult: Result<Void, VoiceRecordPlaybackRepositoryError>?

    private var actualPrepareCallCount = 0
    private var actualPlayCallCount = 0
    private var actualPauseCallCount = 0
    private var actualSeekCallCount = 0
    private var actualStopCallCount = 0

    private var expectedPrepareCallCount: Int?
    private var expectedPlayCallCount: Int?
    private var expectedPauseCallCount: Int?
    private var expectedSeekCallCount: Int?
    private var expectedStopCallCount: Int?

    public private(set) var preparedAudioFileURL: URL?
    public private(set) var lastSeekTime: TimeInterval?

    public func setPrepareResult(_ result: Result<
        AsyncStream<AudioPlaybackState>,
        VoiceRecordPlaybackRepositoryError
    >) {
        prepareResult = result
    }

    public func setPlayResult(_ result: Result<Void, VoiceRecordPlaybackRepositoryError>) {
        playResult = result
    }

    public func setPauseResult(_ result: Result<Void, VoiceRecordPlaybackRepositoryError>) {
        pauseResult = result
    }

    public func setSeekResult(_ result: Result<Void, VoiceRecordPlaybackRepositoryError>) {
        seekResult = result
    }

    public func setStopResult(_ result: Result<Void, VoiceRecordPlaybackRepositoryError>) {
        stopResult = result
    }

    public func expectPrepare(callCount: Int) {
        expectedPrepareCallCount = callCount
    }

    public func expectPlay(callCount: Int) {
        expectedPlayCallCount = callCount
    }

    public func expectPause(callCount: Int) {
        expectedPauseCallCount = callCount
    }

    public func expectSeek(callCount: Int) {
        expectedSeekCallCount = callCount
    }

    public func expectStop(callCount: Int) {
        expectedStopCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(actualPrepareCallCount, expectedPrepareCallCount, "prepare", file, line)
        assertCount(actualPlayCallCount, expectedPlayCallCount, "play", file, line)
        assertCount(actualPauseCallCount, expectedPauseCallCount, "pause", file, line)
        assertCount(actualSeekCallCount, expectedSeekCallCount, "seek", file, line)
        assertCount(actualStopCallCount, expectedStopCallCount, "stop", file, line)
    }

    private func assertCount(
        _ actual: Int,
        _ expected: Int?,
        _ label: String,
        _ file: StaticString,
        _ line: UInt
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "\(label) 호출 횟수 불일치", file: file, line: line)
    }

    public func prepare(audioFileURL: URL) throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        actualPrepareCallCount += 1
        preparedAudioFileURL = audioFileURL
        switch prepareResult {
        case .success(let stream): return stream
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordPlaybackRepository.prepareResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func play() throws(VoiceRecordPlaybackRepositoryError) {
        actualPlayCallCount += 1
        switch playResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordPlaybackRepository.playResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func pause() throws(VoiceRecordPlaybackRepositoryError) {
        actualPauseCallCount += 1
        switch pauseResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordPlaybackRepository.pauseResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func seek(to time: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {
        actualSeekCallCount += 1
        lastSeekTime = time
        switch seekResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordPlaybackRepository.seekResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func stop() throws(VoiceRecordPlaybackRepositoryError) {
        actualStopCallCount += 1
        switch stopResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordPlaybackRepository.stopResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
