import UIKit

// MARK: - WarningContentConfiguration

public struct WarningContentConfiguration: UIContentConfiguration {
    let regenerateAction: () -> Void

    public init(regenerateAction: @escaping () -> Void) {
        self.regenerateAction = regenerateAction
    }

    public func makeContentView() -> any UIView & UIContentView {
        WarningContentView(configuration: self)
    }

    public func updated(for state: any UIConfigurationState) -> WarningContentConfiguration {
        self
    }
}

// MARK: - WarningContentView

public final class WarningContentView: UIView, UIContentView {
    public var configuration: any UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - UI Components

    private let warningIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .semibold)
        iv.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title2, alignment: .center)
        label.textColor = UIColor.gray950
        label.text = "요약을 생성하지 못했어요"
        label.numberOfLines = 0
        return label
    }()

    private let subTitle: TypographyLabel = {
        let label = TypographyLabel(typography: .body2, alignment: .center)
        label.textColor = UIColor.gray950
        label.text = "일시적인 오류가 발생했어요\n잠시 후 다시 시도해주세요"
        label.numberOfLines = 0
        return label
    }()

    private let regenerateButton: GlassButton = {
        let button: GlassButton = .default("재 생성")
        button.setCapsuleCornerRadius()
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        return button
    }()

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 100,
            leading: 24,
            bottom: 100,
            trailing: 24
        )
        return stack
    }()

    // MARK: - Init

    public init(configuration: any UIContentConfiguration) {
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
        containerStack.addArrangedSubview(warningIconView)
        containerStack.addArrangedSubview(titleLabel)
        containerStack.setCustomSpacing(16, after: titleLabel)
        containerStack.addArrangedSubview(subTitle)
        containerStack.setCustomSpacing(24, after: subTitle)
        containerStack.addArrangedSubview(regenerateButton)
        addSubview(containerStack)

        containerStack.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = containerStack.topAnchor.constraint(equalTo: topAnchor)
        let bottomConstraint = containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        // UIKit 셀 초기화/디큐 시점의 임시 52pt 높이 제약조건과의 충돌을 방지하기 위해 세로 제약의 우선순위를 미세하게 낮춥니다.
        topConstraint.priority = .init(999)
        bottomConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            topConstraint,
            bottomConstraint
        ])
    }

    // MARK: - Apply

    private func apply(configuration: any UIContentConfiguration) {
        guard let config = configuration as? WarningContentConfiguration else { return }
        
        // 버튼 터치 액션 바인딩 및 중복 등록 방지 처리
        regenerateButton.removeTarget(nil, action: nil, for: .allEvents)
        regenerateButton.addAction(UIAction { _ in
            config.regenerateAction()
        }, for: .touchUpInside)
    }
}
