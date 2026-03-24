import Foundation

public enum Policy {
    /// 제목 최대 글자 수
    static let maxNameLength: Int = 50

    /// AVAudioEngine installTap 버퍼 크기 (프레임 수)
    /// 44100 Hz 기준 약 93ms/buffer → ~10.7 Waveform/sec
    public static let waveformTapBufferSize: Int = 4096

    /// Waveform 당 amplitude 샘플 수 (파형 막대 개수)
    public static let waveformSamplesPerBuffer: Int = 20

    /// 앱 언어 설정을 저장하기 위한 UserDefaults 키
    public static let appSelectedLanguageKey: String = "app_selected_language"
    /// 기존 사용자 여부를 확인하기 위한 UserDefaults 키
    public static let isExistingUserKey: String = "isExistingUser"
}
