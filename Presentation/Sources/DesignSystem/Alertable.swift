import UIKit

@MainActor
public protocol Alertable: UIViewController {
    func showAlert(message: String)
}

public extension Alertable {
    func showAlert(message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func showAlert(title: String, message: String, onDismiss: @escaping () -> Void) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in onDismiss() })
        present(alert, animated: true)
    }
}
