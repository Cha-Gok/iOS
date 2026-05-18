import Core
import Domain
import Foundation
import WhisperKit

public actor WhisperKitProvider: WhisperDataSource {
    private let storageService: any StorageService
    private let languageRepository: any LanguageRepository

    // MARK: - Configuration

    private var cachedWhisper: WhisperKit?
    private static let modelDirectory = "WhisperModels"
    private var decodingOptions: DecodingOptions {
        DecodingOptions(
            language: whisperLanguageCode(for: languageRepository.fetchLanguage()),
            skipSpecialTokens: true
        )
    }

    public var downloadedBaseURL: URL {
        storageService.absoluteURL(for: Self.modelDirectory)
    }

    public init(
        storageService: any StorageService,
        languageRepository: any LanguageRepository
    ) {
        self.storageService = storageService
        self.languageRepository = languageRepository
    }

    public static func isModelDownloaded(storageService: any StorageService) -> Bool {
        let downloadBase = storageService.absoluteURL(for: Self.modelDirectory)
        let recommendedModel = WhisperKit.recommendedModels().default
        let modelPath = downloadBase
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
            .appendingPathComponent(recommendedModel)

        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: modelPath.path, isDirectory: &isDirectory) && isDirectory
            .boolValue
    }

    private func getOrLoadWhisper() async throws -> WhisperKit {
        if let cached = cachedWhisper {
            return cached
        }

        let downloadBase = storageService.absoluteURL(for: Self.modelDirectory)
        try FileManager.default.createDirectory(at: downloadBase, withIntermediateDirectories: true, attributes: nil)
        let recommendedModel = WhisperKit.recommendedModels().default
        let modelFolderPath = downloadBase
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
            .appendingPathComponent(recommendedModel)

        AppLogger.info("WhisperKit 모델 로드 시작: \(modelFolderPath.path)")

        let config = WhisperKitConfig(
            model: recommendedModel,
            downloadBase: downloadBase,
            modelFolder: modelFolderPath.path,
            tokenizerFolder: downloadBase,
            download: false
        )
        let whisper = try await WhisperKit(config)

        cachedWhisper = whisper
        AppLogger.info("WhisperKit 모델 로드 완료")
        return whisper
    }

    public func transcribe(audioFilePath: String) async throws -> [TranscriptionResult] {
        let whisper = try await getOrLoadWhisper()
        let audioURL = storageService.absoluteURL(for: audioFilePath)
        AppLogger.info("오디오 전사 실행: \(audioURL.lastPathComponent)")
        return try await whisper.transcribe(audioPath: audioURL.path, decodeOptions: decodingOptions)
    }

    public func preload() async {
        _ = try? await getOrLoadWhisper()
    }

    public func clearCache() {
        cachedWhisper = nil
    }
}

// MARK: - Helper ( Private )

private extension WhisperKitProvider {
    func whisperLanguageCode(for language: Language) -> String {
        switch language {
        case .ko:
            return "ko"
        case .en:
            return "en"
        }
    }
}
