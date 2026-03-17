@testable import Domain
import Core
import XCTest

final class StartRecordingUseCaseTests: XCTestCase {
    private var recordingRepository: MockVoiceRecordStartRepository!
    private var sut: DefaultStartRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordStartRepository()
        sut = DefaultStartRecordingUseCase(
            recordingRepository: recordingRepository
        )
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension StartRecordingUseCaseTests {
    func test_execute_시작에성공하면_파형스트림을반환한다() async throws {
        // Given

        let expectedStream = AsyncStream<Waveform> { continuation in
            continuation.yield(.stub())
            continuation.finish()
        }
        await recordingRepository.setResult(.success(expectedStream))
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

// MARK: - 실패 / 에러 매핑

extension StartRecordingUseCaseTests {
    func test_execute_녹음시작에실패하면_startFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.startFailed))
        await recordingRepository.expectStartRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("StartRecordingUseCaseError.startFailed 에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .startFailed = error else {
                return XCTFail(
                    "예상한 에러는 StartRecordingUseCaseError.startFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await recordingRepository.setResult(.failure(.unknown(expectedError)))
        await recordingRepository.expectStartRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("StartRecordingUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail(
                    "예상한 에러는 StartRecordingUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError, "내부 에러 타입은 DummyError 여야 합니다.")
        }

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - Task 취소

extension StartRecordingUseCaseTests {
    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut은 반드시 설정되어야 합니다.")
        }
        // Given
        await recordingRepository.expectStartRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("StartRecordingUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error as? StartRecordingUseCaseError else {
                XCTFail("예상한 에러는 StartRecordingUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
                return
            }
        }

        // When
        await recordingRepository.verify()
    }
}
