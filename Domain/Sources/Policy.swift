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

    /// 온보딩 완료 시 자동 생성되는 기본 폴더 이름
    public static let defaultFolderName: String = "기본 폴더"

    /// 녹음 PCM 버퍼 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let audioBufferStreamBufferLimit: Int = 8

    /// UI 파형 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let waveformStreamBufferLimit: Int = 8

    /// 최근 기록 탭에서 표시할 최대 VoiceNote 개수
    public static let recentVoiceNoteLimit: Int = 5

    /// 재생 상태 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let playbackStateStreamBufferLimit: Int = 8

    /// 재생 진행률 업데이트 주기 (나노초, 0.1초)
    public static let playbackProgressUpdateInterval: UInt64 = 100_000_000

    /// 재생 빨리감기/뒤로가기 이동 간격 (초)
    public static let playbackSkipInterval: TimeInterval = 5

    /// 세그먼트 간 공백이 이 값(초)을 초과하면 새 섹션으로 분리
    public static let scriptGroupingPauseThreshold: TimeInterval = 2.0
}
