import UIKit

/// 그라데이션이 채워진 프로그레스 바의 게이지 바(Indicator) 역할을 하는 커스텀 뷰.
/// 코너 라운딩 및 좌우 가로형 그라데이션을 가집니다.
/// 배경색: .gray600, 그라데이션: .gray600 -> .point1000
public final class ImmutableIndicator: UIView {
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.0, y: 0.5) // 가로 방향 시작
        layer.endPoint = CGPoint(x: 1.0, y: 0.5) // 가로 방향 종료
        layer.locations = [0, 1.0]
        return layer
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        clipsToBounds = true
        layer.addSublayer(gradientLayer)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor.gray600.cgColor,
            UIColor.point1000.cgColor,
            UIColor.gray600.cgColor
        ]
    }
}
