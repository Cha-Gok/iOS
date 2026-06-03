import UIKit

// MARK: UIViewController

public class ViewController: UIViewController {
    lazy var chagokBackgroundView: ChaGokBackgroundView = .init()

    override public func loadView() {
        view = chagokBackgroundView
    }
}

public extension UIViewController {
    func updateNavigationBarAppearance(isTransparent: Bool) {
        let appearance = UINavigationBarAppearance()
        if isTransparent {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.gray50
        }

        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }
}

// MARK: UICollectionViewController

public class CollectionViewController: UICollectionViewController {
    lazy var chagokBackgroundView: ChaGokBackgroundView = .init()

    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundView = chagokBackgroundView
        collectionView.backgroundColor = .clear
    }
}

// MARK: UICollectionView

public class CollectionView: UICollectionView {
    lazy var chagokBackgroundView: ChaGokBackgroundView = .init()

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundView = chagokBackgroundView
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundView = chagokBackgroundView
    }
}

// MARK: UITableViewController

public class TableViewController: UITableViewController {
    lazy var chagokBackgroundView: ChaGokBackgroundView = .init()

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = chagokBackgroundView
        tableView.backgroundColor = .clear
    }
}

// MARK: UITableView

public class TableView: UITableView {
    lazy var chagokBackgroundView: ChaGokBackgroundView = .init()

    override public init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        backgroundView = chagokBackgroundView
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundView = chagokBackgroundView
    }
}

// MARK: - Background 커스텀 뷰

final class ChaGokBackgroundView: UIView {
    let ellipseFirst: UIView = {
        let e = UIView()
        e.translatesAutoresizingMaskIntoConstraints = false
        return e
    }()

    let ellipseSecond: UIView = {
        let e = UIView()
        e.translatesAutoresizingMaskIntoConstraints = false
        return e
    }()

    // 제약조건(Constraint)을 애니메이션 시점에 변경하기 위해 참조를 유지합니다.
    private var ellipseFirstHeightConstraint: NSLayoutConstraint?
    private var ellipseSecondHeightConstraint: NSLayoutConstraint?

    var animationValue: AnimationValue = .init()
    var amplitude: Amplitude = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupEllipseFirst()
        setupEllipseSecond()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ellipseFirstStyle()
        ellipseSecondStyle()
    }

    override func updateProperties() {
        super.updateProperties()
        let amp = CGFloat(amplitude.value)

        // 속성(Properties) 업데이트: Blur 반경
        let firstBlur = animationValue.ellipseFirstBlur + (amp * Constant.ellipseFirstBlurAmplitudeMultiplier)
        let secondBlur = animationValue.ellipseSecondBlur + (amp * Constant.ellipseSecondBlurAmplitudeMultiplier)
        ellipseFirst.layer.shadowRadius = firstBlur
        ellipseSecond.layer.shadowRadius = secondBlur
        // background Color
        ellipseFirst.layer.shadowColor = amp == 0.0 ? UIColor.point300.cgColor : UIColor.point500.cgColor
        ellipseSecond.layer.shadowColor = amp == 0.0 ? UIColor.point500.cgColor : UIColor.point600.cgColor
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()
        let amp = CGFloat(amplitude.value)
        // 제약조건(Constraints) 업데이트: 높이
        ellipseFirstHeightConstraint?.constant = animationValue
            .ellipseFirstHeight + (amp * Constant.ellipseFirstHeightAmplitudeMultiplier)
        ellipseSecondHeightConstraint?.constant = animationValue
            .ellipseSecondHeight + (amp * Constant.ellipseSecondHeightAmplitudeMultiplier)
    }

    private func setup() {
        backgroundColor = UIColor.gray50
        addSubview(ellipseFirst)
        addSubview(ellipseSecond)
    }

    private func setupEllipseFirst() {
        let heightConstraint = ellipseFirst.heightAnchor.constraint(equalToConstant: animationValue.ellipseFirstHeight)
        ellipseFirstHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            ellipseFirst.centerXAnchor.constraint(equalTo: centerXAnchor),
            ellipseFirst.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constant.ellipseFirstLeadingOffset),
            ellipseFirst.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: Constant.ellipseFirstTrailingOffset
            ),
            heightConstraint,
            ellipseFirst.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constant.ellipseFirstBottomOffset)
        ])
    }

    private func setupEllipseSecond() {
        let heightConstraint = ellipseSecond.heightAnchor
            .constraint(equalToConstant: animationValue.ellipseSecondHeight)
        ellipseSecondHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            ellipseSecond.centerXAnchor.constraint(equalTo: centerXAnchor),
            ellipseSecond.leadingAnchor.constraint(equalTo: leadingAnchor),
            ellipseSecond.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint,
            ellipseSecond.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constant.ellipseSecondBottomOffset)
        ])
    }
}

// MARK: Ellipse Data 구조

extension ChaGokBackgroundView {
    @Observable
    final class Amplitude {
        var value: Float

        init(value: Float = 0.0) {
            self.value = value
        }
    }

    struct AnimationValue {
        // 제약조건의 높이 최소/최대 (원하시는 수치로 언제든 수정 가능합니다)
        var ellipseFirstHeight: CGFloat = Constant.ellipseFirstHeight
        var ellipseSecondHeight: CGFloat = Constant.ellipseSecondHeight
        // Blur(그림자 흐림 반경)
        var ellipseFirstBlur: CGFloat = Constant.ellipseFirstBlur
        var ellipseSecondBlur: CGFloat = Constant.ellipseSecondBlur
    }
}

// MARK: Ellipse Style

extension ChaGokBackgroundView {
    private func ellipseFirstStyle() {
        let path = UIBezierPath(ovalIn: ellipseFirst.bounds)
        ellipseFirst.backgroundColor = .clear
        ellipseFirst.layer.shadowOpacity = 1.0
        ellipseFirst.layer.shadowOffset = .zero
        ellipseFirst.layer.shadowPath = path.cgPath
    }

    private func ellipseSecondStyle() {
        let rectForHalfEllipse = CGRect(
            x: 0,
            y: 0,
            width: ellipseSecond.bounds.width,
            height: ellipseSecond.bounds.height * 2
        )
        // 반타원 패스
        let path = UIBezierPath(ovalIn: rectForHalfEllipse)
        ellipseSecond.backgroundColor = .clear
        ellipseSecond.layer.shadowOpacity = 1.0
        ellipseSecond.layer.shadowOffset = .zero
        ellipseSecond.layer.shadowPath = path.cgPath
    }
}
