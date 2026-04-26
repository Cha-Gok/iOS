import Core
import UIKit

/// 투명한 글래스 효과(Glassmorphism)가 적용된 커스텀 버튼 클래스입니다.
/// UIButton.Configuration의 prominentClearGlass 스타일을 기반으로 하며, 커스텀 테두리 및 배경색 설정을 지원합니다.
final class GlassButton: UIButton {
    var isShadow: Bool = true
    var cornerRadius: CGFloat = Constant.cornerRadius

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
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
        layer.shadowOffset = CGSize(
            width: Constant.shadowOffsetWidth, height: Constant.shadowOffsetHeight
        )
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

        if let unifiedView = configuration?.background.customView as? UnifiedGradientView {
            unifiedView.updateCornerRadius(cornerRadius)
        }
    }
}

// MARK: - 내부 Helper 함수

extension GlassButton {
    /// 버튼 초기 생성 시 호출되어 기본적인 생성자 함수
    private func setupStyle() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
    }

    /// GlassButton의 전반적인 디자인(텍스트, 폰트, 테두리, 배경색, 이미지 등)을 세부적으로 구성합니다.
    /// 단일 색상(Solid Color)뿐만 아니라 배열 형태의 그라데이션(Gradient) 색상 적용도 투명 효과와 함께 지원합니다.
    ///
    /// - Parameters:
    ///   - title: 버튼 내부에 표시될 텍스트 문자열입니다. 타이틀이 필요 없을 경우 nil을 전달합니다.
    ///   - typography: 애플리케이션 공통 폰트 지정 열거형(`Typography`)으로 폰트 스타일을 적용합니다.
    ///   - border: 필요에 따라 테두리를 지정하는 `Border` 구조체를 전달합니다. 단색 또는 그라데이션(`GradientSet`), 두께를 설정할 수 있습니다.
    ///   - image: 버튼 내에 들어갈 아이콘 이미지(`ImageAsset`)를 지정합니다. 리소스 형식과 SFSymbol 형식을 모두 지정 가능합니다.
    ///   - backgroundColor: 버튼의 배경색을 결정하는 `GradientSet` 열거형입니다. 단색 또는 여러 색상 배열의 그라데이션을 사용할 수 있습니다. (기본값:
    /// `.color(.point600)`)
    ///   - foregroundColor: 버튼 텍스트 및 이미지의 기본 색상입니다. (기본값: `.white`)
    func configure(
        type: UIButton.Configuration = .prominentGlass(),
        _ title: String?,
        typography: Typography,
        border: Border? = nil,
        image: ImageAsset? = nil,
        backgroundColor: GradientSet = .color(.point600),
        foregroundColor: UIColor = .white
    ) {
        var config: UIButton.Configuration = type

        config.title = title
        config.baseForegroundColor = foregroundColor
        config.background.cornerRadius = cornerRadius
        config.cornerStyle = .fixed
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = typography.font
            return outgoing
        }

        if let image {
            switch image.type {
            case .resource:
                config.image = UIImage(named: image.imageName)
            case .system:
                config.image = UIImage(systemName: image.imageName, withConfiguration: image.configuration)
            }
        }

        var needsCustomView = false
        var bgColors: [UIColor]? = nil
        var bgColor: UIColor? = nil
        var borderColors: [UIColor]? = nil

        switch backgroundColor {
        case .color(let color):
            bgColor = color
            config.baseBackgroundColor = color
        case .gradient(let colors):
            bgColors = colors
            config.baseBackgroundColor = .clear
            needsCustomView = true
        }

        if let border {
            switch border.color {
            case .color(let color):
                config.background.strokeColor = color
                config.background.strokeWidth = border.width
            case .gradient(let colors):
                borderColors = colors
                config.background.strokeWidth = 0
                needsCustomView = true
            }
        }

        if needsCustomView {
            let unifiedView = UnifiedGradientView(
                bgColor: bgColors == nil ? bgColor : nil,
                bgColors: bgColors,
                borderColors: borderColors,
                borderWidth: border?.width ?? 0,
                cornerRadius: cornerRadius
            )
            config.background.customView = unifiedView

            if bgColors == nil {
                config.baseBackgroundColor = .clear
            }
        }

        configuration = config
    }

    /// 그림자 적용 여부를 판단합니다. 그림자가 필요 없는 경우 호출하여 비활성화합니다.
    func setShadow(_ val: Bool) {
        isShadow = val
    }

    /// Policy에 정의된 Capsule CornerRadius 값을 버튼 모서리에 전역으로 지정합니다.
    /// 알약처럼 둥근 모서리 디자인이 요구될 경우 호출하세요.
    func setCapsuleCornerRadius() {
        cornerRadius = Constant.capsuleCornerRadius
        setNeedsUpdateConfiguration()
    }
}

// MARK: GlassButton Factory

extension GlassButton {
    /// 기본 스타일의 GlassButton 인스턴스를 생성하여 반환합니다.
    /// - Parameter title: 버튼에 표시될 텍스트
    /// - Returns: 설정이 완료된 GlassButton 인스턴스
    static func `default`(_ title: String) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            title,
            typography: .subtitle1,
            border: Border(color: .color(UIColor.gray600), width: Constant.borderWidth),
            backgroundColor: .color(UIColor.point200.withAlphaComponent(Constant.backgroundOpacity)),
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
            backgroundColor: .color(UIColor.point600),
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
            backgroundColor: .color(UIColor.danger),
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
            backgroundColor: .color(UIColor.gray300),
            foregroundColor: UIColor.gray750
        )
        return btn
    }

    /// 64x64 크기의 둥근 플로팅 액션 버튼(FAB) 형태인 GlassButton 인스턴스를 생성하여 반환합니다.
    /// 배경과 테두리에 기본적으로 음성 녹음 관련 그라데이션 컬러 매핑이 적용되어 있습니다.
    ///
    /// - Parameter image: 버튼 중앙에 표시할 아이콘 이미지 (`ImageAsset`)
    /// - Returns: 기본 제약조건(Width, Height) 및 그라데이션 스타일이 적용된 GlassButton 인스턴스
    static func floating(image: ImageAsset) -> GlassButton {
        let btn = GlassButton()
        btn.configure(
            nil,
            typography: .body1,
            border: .init(color: .gradient([.point900, .point1000]), width: 1),
            image: image,
            backgroundColor: .gradient([.point800, .point600]),
            foregroundColor: UIColor.gray950
        )
        btn.widthAnchor.constraint(equalToConstant: Constant.floatingButtonSize).isActive = true
        btn.heightAnchor.constraint(equalToConstant: Constant.floatingButtonSize).isActive = true

        return btn
    }
}

// MARK: Data 구조

extension GlassButton {
    struct Border {
        let color: GradientSet
        let width: CGFloat
    }

    struct ImageAsset {
        let imageName: String
        let type: GlassImageType
        let configuration: UIImage.SymbolConfiguration?

        init(imageName: String, type: GlassImageType, configuration: UIImage.SymbolConfiguration? = nil) {
            self.imageName = imageName
            self.type = type
            self.configuration = configuration
        }
    }

    enum GlassImageType {
        case resource
        case system
    }

    enum GradientSet {
        case color(UIColor)
        case gradient([UIColor])
    }
}

// MARK: - Gradient 커스텀 뷰

private final class UnifiedGradientView: UIView {
    private let backgroundGradientLayer = CAGradientLayer()
    private let borderGradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()

    private var currentCornerRadius: CGFloat

    init(
        bgColor: UIColor?,
        bgColors: [UIColor]?,
        borderColors: [UIColor]?,
        borderWidth: CGFloat,
        cornerRadius: CGFloat
    ) {
        currentCornerRadius = cornerRadius
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        if let bgColor {
            backgroundColor = bgColor
        }

        if let bgColors {
            backgroundGradientLayer.colors = bgColors.map(\.cgColor)
            backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            layer.addSublayer(backgroundGradientLayer)
        }

        if let borderColors {
            borderGradientLayer.colors = borderColors.map(\.cgColor)
            borderGradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
            borderGradientLayer.endPoint = CGPoint(x: 0.5, y: 0)

            borderMaskLayer.fillColor = UIColor.clear.cgColor
            borderMaskLayer.strokeColor = UIColor.black.cgColor
            borderMaskLayer.lineWidth = borderWidth
            borderGradientLayer.mask = borderMaskLayer

            layer.addSublayer(borderGradientLayer)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func updateCornerRadius(_ radius: CGFloat) {
        currentCornerRadius = radius
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if backgroundGradientLayer.superlayer != nil {
            backgroundGradientLayer.frame = bounds
            backgroundGradientLayer.cornerRadius = currentCornerRadius
        }

        if borderGradientLayer.superlayer != nil {
            borderGradientLayer.frame = bounds
            let inset = borderMaskLayer.lineWidth / 2
            let path = UIBezierPath(
                roundedRect: bounds.insetBy(dx: inset, dy: inset),
                cornerRadius: max(currentCornerRadius - inset, 0)
            )
            borderMaskLayer.path = path.cgPath
        }
    }
}
