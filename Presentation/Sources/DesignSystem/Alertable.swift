import UIKit

@MainActor
public protocol Alertable: UIViewController {
    func showAlert(message: String)
}

public extension Alertable {
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
