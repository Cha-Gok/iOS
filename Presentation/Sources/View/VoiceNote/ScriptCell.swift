import UIKit

// MARK: - ScriptContentConfiguration

struct ScriptContentConfiguration: UIContentConfiguration {
    var sectionIndex: Int = 0
    var timestamp: String = ""
    var timestampSeconds: TimeInterval = 0
    var text: String = ""
    var isHighlighted: Bool = false
    var isEditing: Bool = false
    var onTextEdited: ((Int, String) -> Void)?
    /// 타임스탬프 탭 콜백
    var onTimestampTapped: ((TimeInterval) -> Void)?

    func makeContentView() -> UIView & UIContentView {
        ScriptContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ScriptContentConfiguration {
        self
    }
}

// MARK: - ScriptContentView

final class ScriptContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - UI Components

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray600
        label.isUserInteractionEnabled = true
        return label
    }()

    private let textBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = Typography.body1.font
        textView.textColor = UIColor.gray950
        textView.backgroundColor = .clear
        textView.layer.cornerRadius = 4
        textView.isEditable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(timestampTapped))

    // MARK: - Init

    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setupUI() {
        containerStack.addArrangedSubview(timeLabel)
        containerStack.addArrangedSubview(textBackground)
        addSubview(containerStack)

        containerStack.addGestureRecognizer(tapGesture)
        containerStack.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc
    private func timestampTapped() {
        guard let config = configuration as? ScriptContentConfiguration,
              !config.isEditing else { return }
        config.onTimestampTapped?(config.timestampSeconds)
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        timeLabel.setTypography(text: config.timestamp, style: .caption)
        tapGesture.isEnabled = !config.isEditing

        installContentView(isEditing: config.isEditing)

        if config.isEditing {
            if textView.text != config.text { textView.text = config.text }
        } else {
            textLabel.setTypography(text: config.text, style: .body1)
        }

        applyHighlight(isHighlighted: config.isHighlighted, isEditing: config.isEditing)
    }

    private func installContentView(isEditing: Bool) {
        let contentView: UIView = isEditing ? textView : textLabel
        guard contentView.superview !== textBackground else { return }

        textBackground.subviews.forEach { $0.removeFromSuperview() }
        textBackground.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: textBackground.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: textBackground.bottomAnchor, constant: -8),
            contentView.leadingAnchor.constraint(equalTo: textBackground.leadingAnchor, constant: 12),
            contentView.trailingAnchor.constraint(equalTo: textBackground.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Highlight

    private func applyHighlight(isHighlighted: Bool, isEditing: Bool) {
        textBackground.backgroundColor = isHighlighted ? UIColor.point600.withAlphaComponent(0.3) : .clear
        let textColor: UIColor = isHighlighted ? .white : UIColor.gray600
        if isEditing {
            textView.textColor = textColor
        } else {
            textLabel.textColor = textColor
        }
    }
}

// MARK: - UITextViewDelegate

extension ScriptContentView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        let text = textView.text ?? ""
        config.onTextEdited?(config.sectionIndex, text)

        if let collectionView = firstAvailableViewController()?.view.subviews
            .first(where: { $0 is UICollectionView }) as? UICollectionView
        {
            UIView.performWithoutAnimation {
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
}

private extension UIView {
    func firstAvailableViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}
