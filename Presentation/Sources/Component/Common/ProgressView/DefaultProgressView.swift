import UIKit

final class DefaultProgressView: UIProgressView {
    // MARK: - Properties

    private var lastSize: CGSize = .zero

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        // 불변 프로그레스 바(ImmutableProgressView)와 일치하는 트랙 컬러 설정
        trackTintColor = .gray600
        // 코너 라운딩 적용
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = bounds.height / 2
        layer.cornerRadius = cornerRadius

        // UIProgressView의 트랙 및 프로그레스 채움 뷰 모두 코너 라운딩 처리 적용
        for subview in subviews {
            subview.layer.cornerRadius = cornerRadius
            subview.clipsToBounds = true
        }

        // 프레임 크기가 유효하고, 이전 크기와 다를 때만 그라데이션 이미지를 새로 생성하여 적용 (성능 최적화)
        if bounds.width > 0, bounds.height > 0, bounds.size != lastSize {
            lastSize = bounds.size

            let colors: [UIColor] = [.gray700, .point1000]
            if let gradientImage = UIImage(bounds: bounds, colors: colors, orientation: .horizontal) {
                progressImage = gradientImage
            }
        }
    }
}
