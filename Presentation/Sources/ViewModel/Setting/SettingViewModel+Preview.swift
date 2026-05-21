import Foundation
import Domain
import Core

#if DEBUG
    extension SettingViewModel {
        static var preview: SettingViewModel {
            return SettingViewModel(
                languageRepository: PreviewLanguageRepository(
                    language: .ko
                )
            )
        }
        
        final class PreviewLanguageRepository: LanguageRepository, @unchecked Sendable {
            var language: Language
            
            init(language: Language) {
                self.language = language
            }
            
            func fetchLanguage() -> Language {
                self.language
            }

            func saveLanguage(_ language: Language) {
                self.language = language
            }
        }
    }
#endif
