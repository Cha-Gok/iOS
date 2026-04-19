import UIKit

// MARK: - ScriptContentConfiguration

struct ScriptContentConfiguration: UIContentConfiguration {
    var sectionIndex: Int = 0
    var timestamp: String = ""
    var timestampSeconds: TimeInterval = 0
    var paragraphs: [String] = []
    var highlightedParagraphIndex: Int?
    var isEditing: Bool = false
    var onParagraphEdited: ((Int, Int, String) -> Void)?
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

    private let paragraphsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(timestampTapped))

    /// 문단별 (배경 컨테이너, 텍스트 레이블 또는 텍스트 뷰) 쌍. 하이라이트 직접 업데이트에 사용
    private var paragraphRows: [(background: UIView, view: UIView)] = []

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
        containerStack.addArrangedSubview(paragraphsStack)
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
              !config.isEditing else { return } // 편집 모드일 때는 탭 동작 무시
        config.onTimestampTapped?(config.timestampSeconds)
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        timeLabel.setTypography(text: config.timestamp, style: .caption)
        tapGesture.isEnabled = !config.isEditing // 편집 모드일 때는 탭 제스처 비활성화

        // 문단 내용이 바뀌거나 편집 모드가 전환될 때만 뷰 재구성
        let currentIsEditing = paragraphRows.first?.view is UITextView
        let needsRebuild = paragraphRows.isEmpty || paragraphRows.count != config.paragraphs
            .count || currentIsEditing != config.isEditing

        if needsRebuild {
            paragraphsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            paragraphRows = config.paragraphs.enumerated().map { pIdx, para in
                let contentView: UIView
                if config.isEditing {
                    let textView = UITextView()
                    textView.text = para
                    textView.font = Typography.body1.font
                    textView.textColor = UIColor.gray950
                    textView.backgroundColor = .clear
                    textView.layer.cornerRadius = 4
                    textView.isEditable = true
                    textView.isScrollEnabled = false
                    textView.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
                    textView.textContainer.lineFragmentPadding = 0
                    textView.delegate = self
                    textView.tag = pIdx
                    contentView = textView
                } else {
                    let label = UILabel()
                    label.setTypography(text: para, style: .body1)
                    label.numberOfLines = 0
                    contentView = label
                }
                contentView.translatesAutoresizingMaskIntoConstraints = false

                let background = UIView()
                background.layer.cornerRadius = 8
                background.addSubview(contentView)
                NSLayoutConstraint.activate([
                    contentView.topAnchor.constraint(equalTo: background.topAnchor, constant: 8),
                    contentView.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -8),
                    contentView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 12),
                    contentView.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12)
                ])
                paragraphsStack.addArrangedSubview(background)
                return (background, contentView)
            }
        } else {
            for (row, para) in zip(paragraphRows, config.paragraphs) {
                if let label = row.view as? UILabel {
                    label.setTypography(text: para, style: .body1)
                } else if let textView = row.view as? UITextView {
                    textView.text = para
                }
            }
        }

        applyHighlight(paragraphIndex: config.highlightedParagraphIndex)
    }

    // MARK: - Highlight

    private func applyHighlight(paragraphIndex: Int?) {
        for (index, row) in paragraphRows.enumerated() {
            let isHighlighted = paragraphIndex == index
            row.background.backgroundColor = isHighlighted ? UIColor.point600.withAlphaComponent(0.3) : .clear
            if let label = row.view as? UILabel {
                label.textColor = isHighlighted ? .white : UIColor.gray600
            } else if let textView = row.view as? UITextView {
                textView.textColor = isHighlighted ? .white : UIColor.gray600
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension ScriptContentView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        let text = textView.text ?? ""
        config.onParagraphEdited?(config.sectionIndex, textView.tag, text)

        // UITextView 높이가 바뀔 때 CollectionView 셀 높이를 재계산하도록 유도
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
