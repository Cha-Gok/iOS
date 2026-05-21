import Foundation

#if DEBUG
    extension SettingViewModel {
        static var preview: SettingViewModel {
            return SettingViewModel()
        }
    }
#endif
