import Foundation

public protocol VoiceRecordPermissionRepository: Sendable {
    func checkRecordingPermission() async throws(VoiceRecordRepositoryError)
}

public protocol VoiceRecordStartRepository: Sendable {
    /// 녹음을 시작하고, 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 스트림.
    /// - Throws: `VoiceRecordStartRepositoryError.startFailed`
    func startRecording() async throws(VoiceRecordStartRepositoryError) -> AsyncStream<Waveform>
}

public protocol VoiceRecordPauseRepository: Sendable {
    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `VoiceRecordPauseRepositoryError.notRecording`, `VoiceRecordPauseRepositoryError.pauseFailed`
    func pauseRecording() async throws(VoiceRecordPauseRepositoryError)
}

public protocol VoiceRecordResumeRepository: Sendable {
    func resumeRecording() async throws(VoiceRecordRepositoryError)
}

public protocol VoiceRecordFinishRepository: Sendable {
    func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord
}

public protocol VoiceRecordRepository: VoiceRecordPermissionRepository,
    VoiceRecordStartRepository,
    VoiceRecordPauseRepository,
    VoiceRecordResumeRepository,
    VoiceRecordFinishRepository
{}
