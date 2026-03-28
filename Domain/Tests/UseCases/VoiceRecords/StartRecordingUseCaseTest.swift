@testable import Domain
import Core
import XCTest

final class StartRecordingUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension StartRecordingUseCaseTest {
    func test_정상상태_녹음시작시_파형스트림을반환한다() async throws {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultStartRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        let expectedStream = AsyncStream<Waveform> { continuation in
            continuation.yield(.stub())
            continuation.finish()
        }
        await recordingRepository.setStartResult(.success(expectedStream))
        await recordingRepository.expectStartRecording(callCount: 1)

        // When
        let stream = try await sut.execute()

        // Then
        var collected: [Waveform] = []
        for await waveform in stream {
            collected.append(waveform)
        }
        XCTAssertEqual(collected.map(\.amplitudes), [Waveform.stub().amplitudes])
        await recordingRepository.verify()
    }
}

// MARK: - 에러 케이스

extension StartRecordingUseCaseTest {
    func test_리포지토리시작실패상태_녹음시작시_startFailed에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultStartRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.setStartResult(.failure(.startFailed))
        await recordingRepository.expectStartRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("StartRecordingUseCaseError.startFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .startFailed = error else {
                return XCTFail(
                    "예상한 에러는 StartRecordingUseCaseError.startFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await recordingRepository.verify()
    }

    func test_리포지토리알수없는에러상태_녹음시작시_unknown에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultStartRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await recordingRepository.setStartResult(.failure(.unknown(expectedError)))
        await recordingRepository.expectStartRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("StartRecordingUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail(
                    "예상한 에러는 StartRecordingUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await recordingRepository.verify()
    }
}

// MARK: - 취소 케이스

extension StartRecordingUseCaseTest {
    func test_태스크취소상태_녹음시작시_cancelled에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultStartRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.expectStartRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("StartRecordingUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? StartRecordingUseCaseError else {
                return XCTFail(
                    "예상한 에러는 StartRecordingUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await recordingRepository.verify()
    }
}
