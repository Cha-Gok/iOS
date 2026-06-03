import Core
import Domain
import Foundation

#if DEBUG
    extension SettingViewModel {
        static var preview: SettingViewModel {
            SettingViewModel(
                languageRepository: PreviewLanguageRepository(language: .ko),
                availableModelRepository: PreviewAvailableModelSupportRepository(),
                onDeviceStatusUseCase: PreviewOnDeviceStatusUseCase()
            )
        }

        final class PreviewLanguageRepository: LanguageRepository, @unchecked Sendable {
            var language: Language

            init(language: Language) {
                self.language = language
            }

            func fetchLanguage() -> Language {
                language
            }

            func saveLanguage(_ language: Language) {
                self.language = language
            }
        }

        struct PreviewAvailableModelSupportRepository: AvailableModelSupportRepository {
            func checkMLXSupportModel() async -> ChaGokModelSupport {
                ChaGokModelSupport(ramSizeGB: 8, isProUser: false)
            }

            func fetchSupportModels() async -> [ChaGokModelState] {
                [
                    ChaGokModelState(
                        title: "Gemma-4",
                        subTitle: "AI 요약 모델",
                        model: .gemma4_e2b_4bit,
                        status: OnDeviceStatus(storage: .downloaded)
                    ),
                    ChaGokModelState(
                        title: "Whisper",
                        subTitle: "음성 전사 모델",
                        model: .whisper,
                        status: OnDeviceStatus(storage: .downloaded)
                    )
                ]
            }
        }

        actor PreviewOnDeviceStatusUseCase: OnDeviceStatusUseCase {
            func checkStatus(model: Domain.ChaGokModel) async -> Domain.OnDeviceStatus {
                .init(storage: .downloaded)
            }

            func cancelDownload(model: Domain.ChaGokModel) async {}

            func subscribe(model: ChaGokModel) async -> AsyncStream<OnDeviceStatus> {
                AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
                    continuation.yield(OnDeviceStatus(storage: .downloaded))
                    continuation.finish()
                }
            }

            func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {}

            func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {}
        }
    }
#endif
