import Foundation

/// 지원하는 오디오 파일 형식 열거형.
public enum AudioFileFormat: String, CaseIterable, Sendable {
    case m4a
    case wav
    case mp3
    case caf
    case aac
    case aiff
    case aif

    /// 파일 확장자 문자열로부터 AudioFileFormat을 생성합니다. (대소문자 구분 없음)
    public init?(extension: String) {
        self.init(rawValue: `extension`.lowercased())
    }
}
