import AVFoundation
import Core
import Domain

/// AVAudioEngine 기반 오디오 녹음 서비스
public actor DefaultAudioRecorderService: AudioRecorderService {
    private var engine: AVAudioEngine?

    public init() {}

    public func startRecording() async throws(AudioRecorderServiceError) -> AsyncStream<Waveform> {
        let engine = AVAudioEngine()
        self.engine = engine

        let (stream, continuation) = AsyncStream.makeStream(of: Waveform.self)
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(Policy.waveformTapBufferSize),
            format: format
        ) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let stride = max(1, frameLength / Policy.waveformSamplesPerBuffer)
            var samples: [Float] = []
            var index = 0
            while index < frameLength, samples.count < Policy.waveformSamplesPerBuffer {
                samples.append(abs(channelData[index]))
                index += stride
            }
            continuation.yield(Waveform(amplitudes: samples))
        }

        continuation.onTermination = { [weak self] _ in
            Task { await self?.stopEngine() }
        }

        do {
            try engine.start()
        } catch {
            AppLogger.error(error)
            continuation.finish()
            throw AudioRecorderServiceError(error)
        }

        return stream
    }

    private func stopEngine() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
    }
}
