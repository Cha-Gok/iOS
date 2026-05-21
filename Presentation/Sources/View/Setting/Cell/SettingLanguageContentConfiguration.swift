import UIKit
import Domain

struct SettingLanguageContentConfiguration: UIContentConfiguration {
    let language: Language
    
    func makeContentView() -> any UIView & UIContentView {
        SettingLanguageContent(configuration: self)
    }
    
    func updated(for state: any UIConfigurationState) -> Self {
        self
    }
}

final class SettingLanguageContent: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }
    
    init(configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    private func apply(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? SettingLanguageContentConfiguration else { return }
        
    }
}
