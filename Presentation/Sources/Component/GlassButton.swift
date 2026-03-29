import Core
import UIKit

/// 투명한 글래스 효과(Glassmorphism)가 적용된 커스텀 버튼 클래스입니다.
/// UIButton.Configuration의 prominentClearGlass 스타일을 기반으로 하며, 커스텀 테두리 및 배경색 설정을 지원합니다.
final class GlassButton: UIButton {
    var isShadow: Bool = true
    var cornerRadius: CGFloat = Constant.cornerRadius

    struct Border {
        let color: UIColor
        let width: CGFloat
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override var isHighlighted: Bool {
        didSet {
            updateStyle()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateStyle()
        }
    }

    private func updateStyle() {}

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isShadow else { return }
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constant.shadowOpacity
        layer.shadowOffset = CGSize(width: Constant.shadowOffsetWidth, height: Constant.shadowOffsetHeight)
        layer.shadowRadius = cornerRadius

        layer.shadowPath =
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: cornerRadius
            ).cgPath
    }

    override func updateConfiguration() {
        super.updateConfiguration()
        configuration?.background.cornerRadius = cornerRadius
    }
}

// MARK: - 내부 Helper 함수

extension GlassButton {
    /// 버튼 초기 생성 시 호출되어 기본적인 생성자 함수
    private func setupStyle() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
    }

    /// GlassButton의 전반적인 디자인(텍스트, 폰트, 테두리, 배경색 등)을 세부적으로 구성합니다.
    ///
    /// - Parameters:
    ///   - title: 버튼 내부에 표시될 텍스트 문자열입니다.
    ///   - typography: 애플리케이션 공통 폰트 지정 열거형(`Typography`)으로 폰트 스타일을 적용합니다.
    ///   - border: 필요에 따라 테두리(색상, 두께)를 지정하는 `Border` 구조체를 전달합니다. 옵셔널 값입니다.
    ///   - backgroundColor: 버튼의 기본 배경색 (기본값: `.point600`).
    ///   - foregroundColor: 버튼 텍스트의 기본 색상 (기본값: `.white`).
    func configure(
        _ title: String,
        typography: Typography,
        border: Border? = nil,
        backgroundColor: UIColor = .point600,
        foregroundColor: UIColor = .white
    ) {
        var config: UIButton.Configuration = .prominentGlass()

        config.title = title
        config.baseForegroundColor = foregroundColor
        config.baseBackgroundColor = backgroundColor
        config.background.cornerRadius = cornerRadius
        config.cornerStyle = .fixed
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = typography.font
            return outgoing
        }

        if let border {
            config.background.strokeColor = border.color
            config.background.strokeWidth = border.width
        }

        configuration = config
        automaticallyUpdatesConfiguration = false
    }

    /// 그림자 적용 여부를 토글합니다. 그림자가 필요 없는 경우 호출하여 비활성화합니다.
    func setShadow() {
        isShadow.toggle()
    }

    /// Policy에 정의된 Capsule CornerRadius 값을 버튼 모서리에 전역으로 지정합니다.
    /// 알약처럼 둥근 모서리 디자인이 요구될 경우 호출하세요.
    func setCornerRadius() {
        cornerRadius = Constant.capsuleCornerRadius
        setNeedsUpdateConfiguration()
    }
}

extension GlassButton {
    /// 기본 스타일의 GlassButton 인스턴스를 생성하여 반환합니다.
    /// - Parameter title: 버튼에 표시될 텍스트
    /// - Returns: 설정이 완료된 GlassButton 인스턴스
    static func `default`(_ title: String) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            title,
            typography: .subtitle1,
            border: Border(color: UIColor.gray600, width: Constant.borderWidth),
            backgroundColor: UIColor.point200.withAlphaComponent(Constant.backgroundOpacity),
            foregroundColor: UIColor.gray900
        )

        return btn
    }

    /// 주 배경색(point600)이 적용된 기본 스타일의 GlassButton 인스턴스를 생성하여 반환합니다.
    /// - Parameter title: 버튼에 표시될 텍스트
    /// - Returns: 설정이 완료된 GlassButton 인스턴스
    static func primary(_ title: String) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            title,
            typography: .subtitle1,
            backgroundColor: UIColor.point600,
            foregroundColor: .white
        )

        return btn
    }

    /// danger 배경색을 적용한 기본 스타일의 GlassButton 인스턴스를 생성하여 반환 합니다.
    /// - Parameter title: 버튼에 표시될 텍스트
    /// - Returns: 설정이 완료된 GlassButton 인스턴스
    static func danger(_ title: String) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            title,
            typography: .subtitle1,
            backgroundColor: UIColor.danger,
            foregroundColor: .white
        )
        return btn
    }

    /// 취소, 닫기 등 보조적인 액션을 위한 회색 계열(gray300)의 GlassButton 인스턴스를 생성하여 반환합니다.
    /// - Parameter title: 버튼에 표시될 텍스트
    /// - Returns: 설정이 완료된 GlassButton 인스턴스
    static func close(_ title: String) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            title,
            typography: .body1,
            backgroundColor: UIColor.gray300,
            foregroundColor: UIColor.gray750
        )
        return btn
    }
}
