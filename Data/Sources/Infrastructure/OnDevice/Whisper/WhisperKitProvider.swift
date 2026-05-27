import Core
import Domain
import Foundation
import WhisperKit

@MainActor
public final class WhisperKitProvider: WhisperDataSource {
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
        languageRepository: any LanguageRepository
    ) {
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
    }

    public func getWhisper() async throws(WhisperDataSourceError) -> WhisperKit {
        if let cached = cachedWhisper {
            return cached
        }

        do {
            guard let downloadBase = modelDirectory else { throw WhisperDataSourceError.notFound }
            AppLogger.info("WhisperKit 모델 로드 시작: \(downloadBase.path)")
            guard let recommendedModel = self.recommendedModel else { throw WhisperDataSourceError.notRecommendedModel }
            
            let config = WhisperKitConfig(
                model: recommendedModel,
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
            throw .loadFailed
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

    public func clearCache() async {
        guard let cachedWhisper = cachedWhisper else { return }
        await cachedWhisper.unloadModels()
    }
    
    /// 모델이 설치된 경로를  전달 하기 위한 함수
    public func getDownloadPath() async throws(WhisperDataSourceError) -> URL {
        guard let path = self.modelDirectory else { throw .notFound }
        return path
    }
    
    public func getDocodingOptions() -> DecodingOptions {
        return decodingOptions
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
