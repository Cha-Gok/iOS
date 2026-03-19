import Foundation

public enum Policy {
    /// 제목 최대 글자 수
    static let maxNameLength: Int = 50

    /// AVAudioEngine installTap 버퍼 크기 (프레임 수)
    /// 44100 Hz 기준 약 93ms/buffer → ~10.7 Waveform/sec
    static let waveformTapBufferSize: Int = 4096

    /// Waveform 당 amplitude 샘플 수 (파형 막대 개수)
    static let waveformSamplesPerBuffer: Int = 100
}
