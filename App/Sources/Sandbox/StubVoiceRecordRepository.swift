import Domain
import Foundation

/// PR2에서 DefaultVoiceRecordRepository 추가 전까지 사용하는 임시 Stub
/// 모든 메서드에서 에러를 throw합니다.
struct StubVoiceRecordRepository: VoiceRecordRepository {
    func checkMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }

    func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }

    func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }

    func pauseRecording() async throws(VoiceRecordRepositoryError) {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }

    func resumeRecording() async throws(VoiceRecordRepositoryError) {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }

    func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
        throw .unknown(NSError(domain: "StubVoiceRecordRepository", code: -1))
    }
}
