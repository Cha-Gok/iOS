import UIKit

final class AlertView: UIView {
    let closeButton: GlassButton

    let primaryButton: GlassButton

    private let title: String

    private let subTitle: String
    private var widthConstraint: NSLayoutConstraint?

    private let topContent: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bottomContent: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = Constant.alertSpacing
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var header: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: title, style: .title2)
        t.textAlignment = .center
        t.textColor = UIColor.gray950
        t.numberOfLines = 0
        return t
    }()

    private lazy var body: UILabel = {
        let d = UILabel()
        d.translatesAutoresizingMaskIntoConstraints = false
        d.setTypography(text: subTitle, style: .body1)
        d.textAlignment = .center
        d.textColor = UIColor.gray950
        d.numberOfLines = 0
        return d
    }()

    init(
        title: String,
        subTitle: String,
        closeButton: GlassButton,
        primaryButton: GlassButton,
        frame: CGRect = .zero
    ) {
        self.title = title
        self.subTitle = subTitle
        self.closeButton = closeButton
        self.primaryButton = primaryButton
        super.init(frame: frame)
        setup()
        setupButton()
        childSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - LifeCycle

extension AlertView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview else {
            widthConstraint?.isActive = false
            widthConstraint = nil
            return
        }
        guard widthConstraint == nil else { return }
        let width = widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: Constant.alertMultiplierWidth)
        width.isActive = true
        widthConstraint = width
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = Constant.cornerRadius

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constant.shadowOpacity
        layer.shadowOffset = CGSize(width: Constant.shadowOffsetWidth, height: Constant.shadowOffsetHeight)
        layer.shadowRadius = Constant.cornerRadius
        layer.shadowPath =
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: Constant.cornerRadius
            ).cgPath
    }
}

// MARK: - setUp

extension AlertView {
    /// AlertView의 전체 배경색, 테두리(border), 모서리 등 가장 기초적인 View 스타일을 설정합니다.
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .point200.withAlphaComponent(Constant.backgroundOpacity)
        layer.borderWidth = Constant.borderWidth
        layer.borderColor = UIColor.gray600.cgColor
    }

    /// AlertView에 맞게 외부 설정 값 상관 없이 내부에서 일관된 디자인을  처리합니다.
    private func setupButton() {
        // close
        closeButton.setShadow(false)
        closeButton.setCapsuleCornerRadius()
        // primary
        primaryButton.setShadow(false)
        primaryButton.setCapsuleCornerRadius()
    }

    /// AlertView 내부의 컴포넌트들(제목, 부제목, 버튼 등)을 StackView에 배치하고
    /// 오토레이아웃 제약 조건을 설정합니다.
    private func childSetup() {
        topContent.addArrangedSubview(header)
        topContent.addArrangedSubview(body)
        bottomContent.addArrangedSubview(closeButton)
        bottomContent.addArrangedSubview(primaryButton)
        addSubview(topContent)
        addSubview(bottomContent)

        NSLayoutConstraint.activate([
            topContent.topAnchor.constraint(equalTo: topAnchor, constant: Constant.alertTopAndBottomValueForTopContent),
            topContent.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constant.alertLeftAndRightValueForTopContent
            ),
            topContent.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constant.alertLeftAndRightValueForTopContent
            ),
            topContent.bottomAnchor.constraint(
                equalTo: bottomContent.topAnchor,
                constant: -Constant.alertTopAndBottomContentSpacing
            ),
            bottomContent.heightAnchor.constraint(equalToConstant: Constant.alertBottomContentHeight),
            bottomContent.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Constant.alertTopAndBottomValueForTopContent
            ),
            bottomContent.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constant.alertLeftAndRightValueForBottomContent
            ),
            bottomContent.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constant.alertLeftAndRightValueForBottomContent
            )
        ])
    }
}
