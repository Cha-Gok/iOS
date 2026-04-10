@testable import Data
import Domain
import Foundation
import XCTest

actor MockAudioPlaybackService: AudioPlaybackService {
    private var prepareResult: Result<AsyncStream<AudioPlaybackState>, AudioPlaybackServiceError>?
    private var playResult: Result<Void, AudioPlaybackServiceError>?
    private var pauseResult: Result<Void, AudioPlaybackServiceError>?
    private var seekResult: Result<Void, AudioPlaybackServiceError>?
    private var stopResult: Result<Void, AudioPlaybackServiceError>?

    private var prepareCallCount = 0
    private var playCallCount = 0
    private var pauseCallCount = 0
    private var seekCallCount = 0
    private var stopCallCount = 0

    private var expectedPrepareCallCount: Int?
    private var expectedPlayCallCount: Int?
    private var expectedPauseCallCount: Int?
    private var expectedSeekCallCount: Int?
    private var expectedStopCallCount: Int?

    private(set) var preparedURL: URL?
    private(set) var lastSeekTime: TimeInterval?

    func setPrepareResult(_ result: Result<AsyncStream<AudioPlaybackState>, AudioPlaybackServiceError>) {
        prepareResult = result
    }

    func setPlayResult(_ result: Result<Void, AudioPlaybackServiceError>) {
        playResult = result
    }

    func setPauseResult(_ result: Result<Void, AudioPlaybackServiceError>) {
        pauseResult = result
    }

    func setSeekResult(_ result: Result<Void, AudioPlaybackServiceError>) {
        seekResult = result
    }

    func setStopResult(_ result: Result<Void, AudioPlaybackServiceError>) {
        stopResult = result
    }

    func expectPrepare(callCount: Int) {
        expectedPrepareCallCount = callCount
    }

    func expectPlay(callCount: Int) {
        expectedPlayCallCount = callCount
    }

    func expectPause(callCount: Int) {
        expectedPauseCallCount = callCount
    }

    func expectSeek(callCount: Int) {
        expectedSeekCallCount = callCount
    }

    func expectStop(callCount: Int) {
        expectedStopCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expectedPrepareCallCount {
            XCTAssertEqual(prepareCallCount, expectedPrepareCallCount, file: file, line: line)
        }
        if let expectedPlayCallCount {
            XCTAssertEqual(playCallCount, expectedPlayCallCount, file: file, line: line)
        }
        if let expectedPauseCallCount {
            XCTAssertEqual(pauseCallCount, expectedPauseCallCount, file: file, line: line)
        }
        if let expectedSeekCallCount {
            XCTAssertEqual(seekCallCount, expectedSeekCallCount, file: file, line: line)
        }
        if let expectedStopCallCount {
            XCTAssertEqual(stopCallCount, expectedStopCallCount, file: file, line: line)
        }
    }

    func preparePlayback(at fileURL: URL) async throws(AudioPlaybackServiceError) -> AsyncStream<AudioPlaybackState> {
        prepareCallCount += 1
        preparedURL = fileURL
        guard let prepareResult else {
            XCTFail("prepareResult가 설정되지 않았습니다.")
            throw .prepareFailed
        }
        return try prepareResult.get()
    }

    func play() async throws(AudioPlaybackServiceError) {
        playCallCount += 1
        guard let playResult else {
            XCTFail("playResult가 설정되지 않았습니다.")
            throw .playFailed
        }
        _ = try playResult.get()
    }

    func pause() async throws(AudioPlaybackServiceError) {
        pauseCallCount += 1
        guard let pauseResult else {
            XCTFail("pauseResult가 설정되지 않았습니다.")
            throw .pauseFailed
        }
        _ = try pauseResult.get()
    }

    func seek(to time: TimeInterval) async throws(AudioPlaybackServiceError) {
        seekCallCount += 1
        lastSeekTime = time
        guard let seekResult else {
            XCTFail("seekResult가 설정되지 않았습니다.")
            throw .seekFailed
        }
        _ = try seekResult.get()
    }

    func stop() async throws(AudioPlaybackServiceError) {
        stopCallCount += 1
        guard let stopResult else {
            XCTFail("stopResult가 설정되지 않았습니다.")
            throw .stopFailed
        }
        _ = try stopResult.get()
    }
}
