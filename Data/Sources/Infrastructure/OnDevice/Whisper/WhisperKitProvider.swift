import Core
import Domain
import Foundation
import WhisperKit

public actor WhisperKitProvider: WhisperDataSource {
    private let storageService: any StorageService
    private let languageRepository: any LanguageRepository

    // MARK: - Configuration

    private var recommendedModel: String?
    private var cachedWhisper: WhisperKit?
    private var modelDirectory: URL?
    private var decodingOptions: DecodingOptions {
        DecodingOptions(
            language: whisperLanguageCode(for: languageRepository.fetchLanguage()),
            skipSpecialTokens: true
        )
    }

    public init(
        storageService: any StorageService,
        languageRepository: any LanguageRepository
    ) {
        self.storageService = storageService
        self.languageRepository = languageRepository
    }

    public func download(progressHandler: @Sendable @escaping (Progress) -> Void) async throws {
        let recommendedModel = WhisperKit.recommendedModels().default
        self.recommendedModel = recommendedModel
        AppLogger.info("WhisperKit 추천 모델 : \(recommendedModel)")
        AppLogger.info("WhisperKit 모델 다운로드 시작")
        modelDirectory = try await WhisperKit.download(
            variant: recommendedModel,
            useBackgroundSession: true,
            progressCallback: progressHandler
        )
        AppLogger.info("WhisperKit 모델 위치 : \(modelDirectory?.absoluteString)")
    }

    private func getWhisper() async throws(WhisperDataSourceError) -> WhisperKit {
        if let cached = cachedWhisper {
            return cached
        }

        do {
            let downloadBase = try await getDownloadPath()
            AppLogger.info("WhisperKit 모델 로드 시작: \(downloadBase.path)")
            let modelName = recommendedModel ?? WhisperKit.recommendedModels().default

            let config = WhisperKitConfig(
                model: modelName,
                downloadBase: downloadBase,
                modelFolder: downloadBase.path,
                tokenizerFolder: downloadBase,
                download: false
            )

            let whisper = try await WhisperKit(config)

            cachedWhisper = whisper
            AppLogger.info("WhisperKit 모델 로드 완료")
            try await whisper.prewarmModels() // preload
            return whisper
        } catch is CancellationError {
            throw .cancelled
        } catch let error as WhisperDataSourceError {
            AppLogger.error(error)
            throw error
        } catch {
            AppLogger.error(error)
            throw .unknown(error)
        }
    }

    public func preload() async {
        do {
            _ = try await getDownloadPath()
            _ = try await getWhisper()
        } catch {
            AppLogger.error(error)
        }
    }

    public func loadModel() async throws(WhisperDataSourceError) {
        do {
            let whisper = try await getWhisper()
            try await whisper.loadModels()
        } catch is CancellationError {
            throw .cancelled
        } catch let error as WhisperDataSourceError {
            AppLogger.error(error)
            throw error
        } catch {
            AppLogger.error(error)
            throw .loadFailed
        }
    }

    public func clearCache() async {
        guard let cachedWhisper else { return }
        await cachedWhisper.unloadModels()
    }

    /// 모델이 설치된 경로를  전달 하기 위한 함수
    public func getDownloadPath() async throws(WhisperDataSourceError) -> URL {
        if let path = modelDirectory {
            AppLogger.info("whisper 저장 위치 (캐시) : \(path)")
            return path
        }

        // 앱 재시작 시 메모리 초기화에 대응하기 위해 디스크의 물리적인 경로 체크
        let recommendedModel = WhisperKit.recommendedModels().default
        let relativePath = "huggingface/models/argmaxinc/whisperkit-coreml/\(recommendedModel)"
        let defaultPath = storageService.absoluteURL(for: relativePath)

        if storageService.exists(relativePath: relativePath) {
            self.modelDirectory = defaultPath
            self.recommendedModel = recommendedModel
            AppLogger.info("whisper 저장 위치 (디스크 감지) : \(defaultPath)")
            return defaultPath
        }

        throw .notFound
    }

    public func getDocodingOptions() -> DecodingOptions {
        return decodingOptions
    }

    public func transcribe(audioPath: URL) async throws -> [TranscriptionResult] {
        let whisper = try await getWhisper()

        AppLogger.info("오디오 전사 실행: \(audioPath)")
        return try await whisper.transcribe(
            audioPath: audioPath.absoluteString,
            decodeOptions: decodingOptions
        )
    }

    public func delete() async throws {
        do {
            let downloadURL = try await getDownloadPath()
            try storageService.delete(fileURL: downloadURL)
            AppLogger.info(downloadURL.absoluteString)
            await clearCache()
            modelDirectory = nil
        } catch {
            AppLogger.error(error)
            throw error
        }
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
