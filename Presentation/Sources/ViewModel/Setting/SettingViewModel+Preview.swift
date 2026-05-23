import Core
import Domain
import Foundation

#if DEBUG
    extension SettingViewModel {
        static var preview: SettingViewModel {
            return SettingViewModel(
                languageRepository: PreviewLanguageRepository(
                    language: .ko
                ),
                mlxRepository: PreviewAvailableModelSupportRepository(),
                sttRepository: PreviewSTTRepository(),
                deleteModelRepository: PreviewDeleteModelRepository()
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
            func deleteWhisperModel() async throws(Domain.AvailableModelSupportRepositoryError) {}

            func deleteMLXModel() async throws(Domain.AvailableModelSupportRepositoryError) {}

            func fetchSupportModels() async -> [ChaGokModelState] {
                [
                    ChaGokModelState(title: "Gemma-4", subTitle: "내용", model: .gemma4_e2b_4bit),
                    ChaGokModelState(title: "whisper", subTitle: "내용", model: .whisper)
                ]
            }

            func checkSupportModel() -> ChaGokModelSupport {
                ChaGokModelSupport(ramSizeGB: 4, isProUser: false)
            }

            func downloadModel(
                progressHandler: @Sendable @escaping (Progress) -> Void
            ) async throws(AvailableModelSupportRepositoryError) {
                let progress = Progress(totalUnitCount: 100)
                for value in [10, 30, 55, 80, 100] {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    progress.completedUnitCount = Int64(value)
                    progressHandler(progress)
                }
            }

            var isModelLoaded: Bool {
                true
            }
        }

        struct PreviewSTTRepository: STTRepository {
            func transcribe(audioFilePath: String) async throws(Domain.STTRepositoryError) -> Domain.Transcript {
                Transcript()
            }

            func checkSTTPermission() -> Domain.PermissionStatus {
                return .authorized
            }

            func requestSTTPermission() async throws(Domain.STTPermissionRepositoryError) -> Domain.PermissionStatus {
                return .authorized
            }
        }

        struct PreviewDeleteModelRepository: DeleteOnDeviceRepository {
            func whisperModel() async throws(Domain.DeleteOnDeviceRepositoryError) {}

            func mlxModel() async throws(Domain.DeleteOnDeviceRepositoryError) {}
        }
    }
#endif
