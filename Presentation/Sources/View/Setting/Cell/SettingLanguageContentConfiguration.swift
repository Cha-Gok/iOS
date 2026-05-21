import UIKit
import Domain

struct SettingLanguageContentConfiguration: UIContentConfiguration {
    let title: String
    let subtitle: String?
    let language: Language
    let action: (Language) -> Void
    
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
    
    // MARK: - State
    
    private var settingConfig: SettingLanguageContentConfiguration? {
        configuration as? SettingLanguageContentConfiguration
    }
    
    private var languageCheckmarks: [Language: UIImageView] = [:]
    
    // MARK: - Component
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setTypography(text: settingConfig?.title, style: .title3)
        title.textColor = UIColor.gray950
        return title
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let subTitle = UILabel()
        subTitle.translatesAutoresizingMaskIntoConstraints = false
        subTitle.setTypography(text: settingConfig?.subtitle, style: .caption)
        subTitle.textColor = UIColor.gray700
        return subTitle
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    // MARK: - Initialize
    
    init(configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Setup
    
    private func setup() {
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            // subTitle
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            // Container
            mainStackView.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 24),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        for lang in Language.allCases {
            let (rowStack, checkmark) = makeLanguageRow(language: lang)
            
            rowStack.addTapGesture { [weak self] in
                guard let self else { return }
                settingConfig?.action(lang)
            }
            
            mainStackView.addArrangedSubview(rowStack)
            languageCheckmarks[lang] = checkmark
        }
    }
    
    private func makeLanguageRow(language: Language) -> (stackView: UIStackView, checkmarkView: UIImageView) {
        let checkmarkView = UIImageView()
        
        let titleLabel = UILabel()
        let name: String = switch language {
        case .ko: "한국어"
        case .en: "영어"
        }
        titleLabel.setTypography(text: name, style: .title2)
        titleLabel.textColor = UIColor.gray950
        
        // spacer
        let spacer = UIView()
        
        let rowStack = UIStackView(arrangedSubviews: [checkmarkView, titleLabel, spacer])
        rowStack.axis = .horizontal
        rowStack.spacing = 16
        rowStack.alignment = .center
        rowStack.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        rowStack.isLayoutMarginsRelativeArrangement = true
        
        let tintColor: UIColor = .point200.withAlphaComponent(0.2)
        rowStack.applyGlassEffect(isInteractive: true, tintColor: tintColor)
        
        return (rowStack, checkmarkView)
    }
    
    // MARK: - Apply
    
    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? SettingLanguageContentConfiguration else { return }
        
        let baseConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        for (lang, checkmark) in languageCheckmarks {
            let isSelected = (lang == config.language)
            
            if isSelected {
                // 선택됨
                let paletteConfig = baseConfig.applying(UIImage.SymbolConfiguration(paletteColors: [.white, .point800]))
                checkmark.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: paletteConfig)
            } else {
                // 선택 안 됨
                let normalConfig = baseConfig.applying(UIImage.SymbolConfiguration(paletteColors: [.gray600]))
                checkmark.image = UIImage(systemName: "circle.fill", withConfiguration: normalConfig)
            }
        }
    }
}
