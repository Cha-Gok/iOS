import Foundation

public struct Waveform {
    public let amplitudes: [Float]

    public init(amplitudes: [Float]) {
        self.amplitudes = amplitudes
    }
}

extension Waveform: Sendable {}
