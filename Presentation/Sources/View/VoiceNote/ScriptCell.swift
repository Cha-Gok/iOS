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
    var onTextHeightChanged: (() -> Void)?
    var onTap: ((TimeInterval) -> Void)?

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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let textBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.usesFontLeading = false
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))

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
        addSubview(timeLabel)
        addSubview(textBackground)
        textBackground.addSubview(textView)

        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            textBackground.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            textBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            textBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            textBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            textView.topAnchor.constraint(equalTo: textBackground.topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: textBackground.bottomAnchor, constant: -8),
            textView.leadingAnchor.constraint(equalTo: textBackground.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: textBackground.trailingAnchor, constant: -8)
        ])
    }

    @objc
    private func cellTapped() {
        guard let config = configuration as? ScriptContentConfiguration,
              !config.isEditing else { return }
        config.onTap?(config.timestampSeconds)
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        timeLabel.setTypography(text: config.timestamp, style: .caption)
        tapGesture.isEnabled = !config.isEditing

        textView.isEditable = config.isEditing
        textView.isSelectable = config.isEditing

        let color = textColor(isHighlighted: config.isHighlighted)
        if textView.text != config.text {
            applyTypography(text: config.text, color: color)
        } else {
            textView.textColor = color
            textView.typingAttributes[.foregroundColor] = color
        }
        textBackground.backgroundColor = config.isHighlighted
            ? UIColor.point600.withAlphaComponent(0.3)
            : .clear
    }

    private func applyTypography(text: String, color: UIColor) {
        var attributes = Typography.body1.textAttributes
        attributes[.foregroundColor] = color
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        textView.typingAttributes = attributes
    }

    private func textColor(isHighlighted: Bool) -> UIColor {
        isHighlighted ? .white : UIColor.gray600
    }
}

// MARK: - UITextViewDelegate

extension ScriptContentView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        let text = textView.text ?? ""
        config.onTextEdited?(config.sectionIndex, text)
        config.onTextHeightChanged?()
    }
}
