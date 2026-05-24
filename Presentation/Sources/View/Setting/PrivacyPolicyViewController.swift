import UIKit
import WebKit

/// 개인정보 처리 방침 WebView Controller
public final class PrivacyPolicyViewController: UIViewController, WKUIDelegate {
    // MARK: - Component

    private let backItem: NavigationItemButton = .init(
        normalItem: .init(title: "개인정보 처리 방침", imageName: "chevron.left"),
        selectedItem: .init(title: "개인정보 처리 방침", imageName: "chevron.left"),
        attributedString: Typography.header2.textAttributes
    )

    private var webView: WKWebView!

    override public func loadView() {
        super.loadView()
        view = UIView()
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupWebView()
    }

    private func setupNavigation() {
        backItem.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backItem)
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
    }

    private func setupWebView() {
        guard let privacyUrl = URL(string: Constant.privacyPolicy) else { return }
        let request = URLRequest(url: privacyUrl)
        webView.load(request)
    }
}

#Preview {
    UINavigationController(
        rootViewController: PrivacyPolicyViewController()
    )
}
