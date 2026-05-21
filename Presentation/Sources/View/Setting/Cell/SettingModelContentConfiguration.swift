import UIKit
import Domain

// MARK: - SettingModelCardData

struct SettingModelCardData {
    let title: String
    let description: String
    let iconName: String
}

// MARK: - SettingModelContentConfiguration

struct SettingModelContentConfiguration: UIContentConfiguration {
    let title: String
    let model: ChaGokModelSupport
    
    // Presentation 영역에서 직접 ChaGokModel(도메인 엔티티)에 의존하여 UI 전용 메타데이터를 switch 분기 처리
    var cards: [SettingModelCardData] {
        var result: [SettingModelCardData] = []
        switch model.model {
        case .whisper:
            result.append(
                SettingModelCardData(
                    title: "Whisper",
                    description: "기기에서 음성을 텍스트로 변환하기 위한 필수 모델이에요.",
                    iconName: "internaldrive"
                )
            )
        case .gemma4_e2b_4bit:
            result.append(
                SettingModelCardData(
                    title: "Gemma-4",
                    description: "젬마4에 대한 설명",
                    iconName: "internaldrive"
                )
            )
        case .none:
            break
        }
        
        return result
    }
    
    func makeContentView() -> any UIView & UIContentView {
        SettingModelContent(configuration: self)
    }
    
    func updated(for state: any UIConfigurationState) -> Self {
        self
    }
}

// MARK: - SettingModelContent

final class SettingModelContent: UIView, UIContentView {
    var configuration: any UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }
    
    // MARK: - Components
    
    // titleLabel은 변하지 않는 값이므로 lazy closure를 통해 생성 시점에 한 번만 타이포그래피 설정
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray950
        if let config = configuration as? SettingModelContentConfiguration {
            label.setTypography(text: config.title, style: .title2)
        }
        return label
    }()
    
    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    // 각 카드 뷰를 한 번만 생성하여 참조를 보관합니다.
    private var cardViews: [(data: SettingModelCardData, view: UIView)] = []
    
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
        addSubview(cardsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            cardsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            cardsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            cardsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // 모든 가능한 카드를 한 번만 생성하고 글래스 이펙트를 적용합니다.
        guard let config = configuration as? SettingModelContentConfiguration else { return }
        for cardData in config.cards {
            let card = makeModelCard(cardData: cardData)
            cardsStackView.addArrangedSubview(card)
            cardViews.append((data: cardData, view: card))
        }
    }
    
    // MARK: - Apply
    
    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? SettingModelContentConfiguration else { return }
        
        let activeCardTitles = Set(config.cards.map { $0.title })
        
        for (data, view) in cardViews {
            view.isHidden = !activeCardTitles.contains(data.title)
        }
    }
    
    // MARK: - Card View Factory
    
    private func makeModelCard(cardData: SettingModelCardData) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. Outermost Horizontal Stack (InnerVerticalStack + TrashButton)
        let containerStack = UIStackView()
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.axis = .horizontal
        containerStack.spacing = 16
        containerStack.alignment = .center
        
        // 2. Inner Vertical Stack (TitleHorizontalStack + DescriptionLabel)
        let innerVerticalStack = UIStackView()
        innerVerticalStack.axis = .vertical
        innerVerticalStack.spacing = 8
        innerVerticalStack.alignment = .leading
        
        // 3. Title Horizontal Stack (Icon + Title)
        let titleHorizontalStack = UIStackView()
        titleHorizontalStack.axis = .horizontal
        titleHorizontalStack.spacing = 8
        titleHorizontalStack.alignment = .center
        
        // Left Icon (Storage drive next to the model title)
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: cardData.iconName, withConfiguration: iconConfig)
        iconImageView.tintColor = .gray950
        iconImageView.contentMode = .scaleAspectFit
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.setTypography(text: cardData.title, style: .subtitle2)
        titleLabel.textColor = .gray950
        
        titleHorizontalStack.addArrangedSubview(iconImageView)
        titleHorizontalStack.addArrangedSubview(titleLabel)
        
        // Description Label (Under the icon + title stack)
        let descLabel = UILabel()
        descLabel.setTypography(text: cardData.description, style: .caption)
        descLabel.textColor = .gray750
        descLabel.numberOfLines = 0
        
        innerVerticalStack.addArrangedSubview(titleHorizontalStack)
        innerVerticalStack.addArrangedSubview(descLabel)
        
        // Right Trash Button
        let trashButton = UIButton(type: .system)
        trashButton.translatesAutoresizingMaskIntoConstraints = false
        let trashConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        trashButton.setImage(UIImage(systemName: "trash", withConfiguration: trashConfig), for: .normal)
        trashButton.tintColor = .danger
        
        containerStack.addArrangedSubview(innerVerticalStack)
        containerStack.addArrangedSubview(trashButton)
        
        card.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            trashButton.widthAnchor.constraint(equalToConstant: 24),
            trashButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Apply Premium Glass Effect
        let tintColor: UIColor = .point200.withAlphaComponent(0.2)
        card.applyGlassEffect(tintColor: tintColor)
        
        return card
    }
}
