import Core
import UIKit

// MARK: - ScriptContentConfiguration

struct ScriptContentConfiguration: UIContentConfiguration {
    var sectionIndex: Int = 0
    var timestamp: TimeInterval = 0
    var text: String = ""
    var isHighlighted: Bool = false
    var isEditing: Bool = false
    var onTextEdited: ((Int, String) -> Void)?
    var onTextHeightChanged: (() -> Void)?

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
        label.setTypography(style: .caption)
        label.textColor = UIColor.gray600
        return label
    }()

    private lazy var textView: UITextView = {
        let spacing = Constant.scriptCellSpacing
        let textView = TypographyTextView(typography: .body1)
        textView.textColor = UIColor.gray950
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        textView.textContainer.lineFragmentPadding = 0
        textView.layer.cornerRadius = Constant.scriptCellCornerRadius
        textView.delegate = self
        return textView
    }()

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
        addSubview(textView)

        for subview in [timeLabel, textView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        let spacing = Constant.scriptCellSpacing
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            textView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: spacing),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        timeLabel.text = config.timestamp.durationString

        textView.isEditable = config.isEditing
        textView.isSelectable = config.isEditing
        textView.isUserInteractionEnabled = config.isEditing
        textView.text = config.text
        textView.backgroundColor = config.isHighlighted ? .scriptCellHighlight : .clear
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

// MARK: - Preview

#Preview {
    let normalConfig = ScriptContentConfiguration(
        sectionIndex: 0,
        timestamp: 0,
        text: "일반 상태의 스크립트 텍스트입니다."
    )
    let highlightedConfig = ScriptContentConfiguration(
        sectionIndex: 1,
        timestamp: 12,
        text: "현재 재생 중인 하이라이트 상태의 스크립트입니다.",
        isHighlighted: true
    )
    let editingConfig = ScriptContentConfiguration(
        sectionIndex: 2,
        timestamp: 24,
        text: "편집 모드의 스크립트 — 탭하여 수정할 수 있습니다.",
        isEditing: true
    )

    let normalCell = ScriptContentView(configuration: normalConfig)
    let highlightedCell = ScriptContentView(configuration: highlightedConfig)
    let editingCell = ScriptContentView(configuration: editingConfig)

    let stack = UIStackView(arrangedSubviews: [normalCell, highlightedCell, editingCell])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = .gray100
    container.addSubview(stack)

    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
        stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])

    return container
}
