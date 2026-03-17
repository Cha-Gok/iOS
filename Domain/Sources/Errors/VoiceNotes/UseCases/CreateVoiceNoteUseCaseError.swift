import Foundation

/// 음성 메모 생성 유스케이스에서 발생할 수 있는 에러.
public enum CreateVoiceNoteUseCaseError: LocalizedError, Sendable {
    /// 검증 실패: 녹음 길이가 유효하지 않음 (0 이하).
    case invalidDuration(duration: Double)
    /// 검증 실패: 오디오 파일 경로가 유효하지 않음.
    case invalidAudioFilePath(URL)
    /// 검증 실패: 파일명이 비어있음.
    case emptyFileName
    /// 검증 실패: 지원하지 않는 파일 확장자.
    case unsupportedExtension(String)
    /// 음성 메모 생성 실패 (저장/디스크/권한 등).
    case createFailed
    /// 취소됨.
    case cancelled
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "녹음 길이가 올바르지 않습니다."
        case .invalidAudioFilePath:
            return "오디오 파일 경로가 올바르지 않습니다."
        case .emptyFileName:
            return "파일 이름이 비어있습니다."
        case .unsupportedExtension(let ext):
            return "지원하지 않는 파일 확장자입니다: \(ext)"
        case .createFailed:
            return "음성 메모 생성에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
