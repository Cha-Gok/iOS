@testable import Domain
import Foundation

public extension Waveform {
    static func stub(
        amplitudes: [Float] = [0.1, 0.2]
    ) -> Waveform {
        Waveform(amplitudes: amplitudes)
    }
}
