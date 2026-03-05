import Foundation

/// 음성 메모 생성 유스케이스에서 발생할 수 있는 에러.
public enum CreateVoiceNoteUseCaseError: Error, LocalizedError, Sendable {

    /// 녹음 길이가 유효하지 않음 (0 미만).
    case invalidDuration(duration: Double)

    /// 오디오 파일 경로가 유효하지 않음 (file URL이 아니거나 path가 비어 있음).
    case invalidAudioFilePath(URL)

    /// 리포지토리 생성 실패 (저장/디스크/권한 등).
    case repositoryFailed

    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "녹음 길이가 올바르지 않습니다."
        case .invalidAudioFilePath:
            return "오디오 파일 경로가 올바르지 않습니다."
        case .repositoryFailed:
            return "리포지토리 생성에 실패했습니다."
        case .unknown:
            return "알 수 없는 에러가 발생했습니다."
        }
    }
}
