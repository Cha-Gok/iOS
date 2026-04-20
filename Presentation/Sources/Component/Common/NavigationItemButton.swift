import UIKit

final class NavigationItemButton: UIButton {

    typealias Attribute = [NSAttributedString.Key: Any]

    // MARK: - State

    private let normalItem: Item
    private let selectedItem: Item
    private let attributedString: Attribute
    private let normalForegroundColor: UIColor
    private let selectedForegroundColor: UIColor

    // MARK: - Initialize

    init(
        normalItem: Item,
        selectedItem: Item,
        attributedString: Attribute,
        normalForegroundColor: UIColor = .gray950,
        selectedForegroundColor: UIColor = .gray950,
        frame: CGRect = .zero
    ) {
        self.normalItem = normalItem
        self.selectedItem = selectedItem
        self.attributedString = attributedString
        self.normalForegroundColor = normalForegroundColor
        self.selectedForegroundColor = selectedForegroundColor
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setup() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.automaticallyUpdateForSelection = false
        self.configuration = config

        self.configurationUpdateHandler = { [weak self] button in
            guard let self, var config = button.configuration else { return }
            let symbolConfig = UIImage.SymbolConfiguration(weight: .bold)

            if button.isSelected {
                config.image = selectedItem.imageName.flatMap { UIImage(systemName: $0)?.withConfiguration(symbolConfig) }
                config.title = selectedItem.title
                config.baseForegroundColor = selectedForegroundColor
            } else {
                config.image = normalItem.imageName.flatMap { UIImage(systemName: $0)?.withConfiguration(symbolConfig) }
                config.title = normalItem.title
                config.baseForegroundColor = normalForegroundColor
            }

            if let title = config.title {
                config.attributedTitle = AttributedString(
                    title,
                    attributes: AttributeContainer(attributedString)
                )
            } else {
                config.attributedTitle = nil
            }
            config.background.backgroundColor = .clear
            button.configuration = config
        }
    }
}

// MARK: - Data 구조

extension NavigationItemButton {
    struct Item {
        let title: String?
        let imageName: String?

        init(title: String? = nil, imageName: String? = nil) {
            self.title = title
            self.imageName = imageName
        }
    }
}
