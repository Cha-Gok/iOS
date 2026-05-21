import UIKit
import Domain

struct SettingModelContentConfiguration: UIContentConfiguration {
    let model: ChaGokModelSupport
    
    func makeContentView() -> any UIView & UIContentView {
        SettingModelContent(configuration: self)
    }
    
    func updated(for state: any UIConfigurationState) -> SettingModelContentConfiguration {
        self
    }
}

final class SettingModelContent: UIView, UIContentView {
    var configuration: any UIContentConfiguration {
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
        guard let configuration = configuration as? SettingModelContentConfiguration else { return }
    }
}
