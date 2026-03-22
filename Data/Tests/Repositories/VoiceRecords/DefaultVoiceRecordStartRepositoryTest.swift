@testable import Data
import Domain
import XCTest

final class DefaultVoiceRecordStartRepositoryTest: XCTestCase {}

// MARK: - 성공 케이스

extension DefaultVoiceRecordStartRepositoryTest {
    func test_정상상태_녹음시작시_서비스의startRecording을호출한다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordStartRepository(service: service)

        // Given
        let stubStream = AsyncStream<Waveform> { _ in }
        await service.setStartResult(.success(stubStream))
        await service.expectStart(callCount: 1)

        // When
        _ = try await sut.startRecording()

        // Then
        await service.verify()
    }
}

// MARK: - 에러 케이스

extension DefaultVoiceRecordStartRepositoryTest {
    func test_서비스실패상태_녹음시작시_startFailed에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordStartRepository(service: service)

        // Given
        await service.setStartResult(.failure(.startFailed))
        await service.expectStart(callCount: 1)

        // When & Then
        do {
            _ = try await sut.startRecording()
            XCTFail("VoiceRecordStartRepositoryError.startFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .startFailed = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordStartRepositoryError.startFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}

// MARK: - 취소 케이스

extension DefaultVoiceRecordStartRepositoryTest {
    func test_태스크취소상태_녹음시작시_cancelled에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordStartRepository(service: service)

        // Given
        await service.expectStart(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.startRecording()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordStartRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordStartRepositoryError else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordStartRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}
