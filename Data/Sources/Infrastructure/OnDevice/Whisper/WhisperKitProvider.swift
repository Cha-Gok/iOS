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

        #if DEBUG
        // ⚠️ 디버깅용 시뮬레이션: 에러 상황별 핸들링을 안전하게 테스트하기 위한 디버그 스위치입니다.
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        // [옵션 1] 네트워크 오류 시뮬레이션 (networkFailed)
        // -> 활성화 시 "네트워크 연결이 유실되었습니다" 문구가 노출됩니다.
        // throw URLError(.notConnectedToInternet)
        
        // [옵션 2] 알 수 없는 시스템 오류 시뮬레이션 (unknown)
        // -> 활성화 시 "다운로드에 실패했습니다" 문구와 상세 에러 문구가 노출됩니다.
        throw NSError(
            domain: "SimulatedErrorDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "알 수 없는 기기 내부 디스크 쓰기 오류가 발생했습니다. (Simulated)"]
        )
        #endif

        let path = try await WhisperKit.download(
            variant: recommendedModel,
            useBackgroundSession: false,
            progressCallback: progressHandler
        )

        // 다운로드 복귀 직후 태스크 취소 상태 감지 (레이스 컨디션 봉쇄)
        if Task.isCancelled {
            AppLogger.info("WhisperKit 다운로드 완료 복귀 후 취소 상태 감지 - 즉각 강제 소거 및 에러 방출")
            try? storageService.delete(fileURL: path)
            throw CancellationError()
        }

        modelDirectory = path
        AppLogger.info("WhisperKit 모델 위치 : \(modelDirectory?.path() ?? "없음")")
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
        
        let configPath = "\(relativePath)/config.json"
        let vocabPath = "\(relativePath)/vocab.json"

        // 디렉토리 존재뿐만 아니라 핵심 구성 파일(config.json, vocab.json)의 완결성 검사를 수행하여 부분 다운로드 및 비정상 종료된 찌꺼기를 필터링합니다.
        if storageService.exists(relativePath: relativePath),
           storageService.exists(relativePath: configPath),
           storageService.exists(relativePath: vocabPath) {
            modelDirectory = defaultPath
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
            audioPath: audioPath.path,
            decodeOptions: decodingOptions
        )
    }

    public func delete() async throws {
        defer {
            modelDirectory = nil
        }
        do {
            // 캐시된 경로가 있거나 디스크 감지가 되는 경우 해당 경로를 사용
            let downloadURL: URL
            if let path = try? await getDownloadPath() {
                downloadURL = path
            } else {
                // 다운로드 중 취소된 경우 등의 대비를 위해 기본 임시/일부 다운로드 경로 계산
                let model = recommendedModel ?? WhisperKit.recommendedModels().default
                let relativePath = "huggingface/models/argmaxinc/whisperkit-coreml/\(model)"
                downloadURL = storageService.absoluteURL(for: relativePath)
            }

            do {
                try storageService.delete(fileURL: downloadURL)
            } catch {
                // error는 자동으로 StorageServiceError로 강하게 추론됩니다.
                guard case .fileNotFound = error else {
                    throw error
                }
            }
            AppLogger.info("WhisperKit 모델/임시 폴더 삭제 완료: \(downloadURL.path)")

            await clearCache()
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
