import UIKit

public final class ContentViewController: UIViewController {
    let closeButton: GlassButton = {
        let b = GlassButton.close("닫기")
        b.setCornerRadius()

        return b
    }()

    let primaryButton: GlassButton = .primary("실행")

    lazy var alert: AlertView = .init(
        title: "title",
        subTitle: "description title",
        closeButton: closeButton,
        primaryButton: primaryButton
    )

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray300
        view.addSubview(alert)

        NSLayoutConstraint.activate([
            alert.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alert.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

#Preview {
    ContentViewController()
}
