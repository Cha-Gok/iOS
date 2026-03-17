import Foundation

public struct Waveform: Sendable {
    public let amplitudes: [Float]

    public init(amplitudes: [Float]) {
        self.amplitudes = amplitudes
    }
}
