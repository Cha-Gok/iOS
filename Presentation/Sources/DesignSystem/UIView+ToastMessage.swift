import UIKit

extension UIView {
    
    enum ToastType: Hashable {
        case normal
        case action
    }
    
    func makeToast(
        type: ToastType = .action,
        _ message: String,
        duration: TimeInterval = 3.0,
        action: (() -> Void)? = nil
    ) {
        let toastContainer = UIView()
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.backgroundColor = UIColor.gray100
        toastContainer.layer.borderColor = UIColor.gray350.cgColor
        toastContainer.layer.borderWidth = 1.0
        toastContainer.layer.cornerRadius = 20
        toastContainer.alpha = 0.0
        
        let msgLabel = UILabel()
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        msgLabel.textColor = UIColor.gray800
        msgLabel.numberOfLines = 1
        msgLabel.setTypography(text: message, style: .body2, textAlignment: type == .normal ? .center : .left)
        
        let cancelButton = UIButton()
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.titleLabel?.setTypography(style: .body2)
        cancelButton.setTitleColor(.danger, for: .normal)
        cancelButton.backgroundColor = .clear
        cancelButton.isHidden = type == .normal
        // 액션 버튼을 눌렀을 때 이벤트 처리
        if type == .action {
            cancelButton.addAction(UIAction { _ in
                action?()
                
                // 버튼을 누르면 대기(delay)를 무시하고 곧바로 내려가면서 사라지도록 처리합니다.
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState]) {
                    toastContainer.alpha = 0.0
                    toastContainer.transform = CGAffineTransform(translationX: 0, y: 50)
                } completion: { _ in
                    toastContainer.removeFromSuperview()
                }
            }, for: .touchUpInside)
        }
        
        toastContainer.addSubview(msgLabel)
        toastContainer.addSubview(cancelButton)
        
        let targetView: UIView
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            targetView = window
        } else {
            targetView = self
        }
        
        targetView.addSubview(toastContainer)
        
        // 타입에 따라 AutoLayout 제약조건 분기
        var constraints: [NSLayoutConstraint] = [
            toastContainer.bottomAnchor.constraint(equalTo: targetView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastContainer.leadingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: -20),
            toastContainer.heightAnchor.constraint(equalToConstant: 52),
            
            msgLabel.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor),
            msgLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 16)
        ]
        
        if type == .normal {
            constraints.append(msgLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16))
        } else {
            constraints.append(contentsOf: [
                msgLabel.trailingAnchor.constraint(lessThanOrEqualTo: cancelButton.leadingAnchor, constant: -10),
                cancelButton.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor),
                cancelButton.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        toastContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        
        // 1. 나타날 때 (.allowUserInteraction 옵션 필수! 안 넣으면 delay 중첩 시간 동안 버튼 터치가 완전 무시됩니다.)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction]) {
            toastContainer.alpha = 1.0
            toastContainer.transform = .identity
        }
        
        // 2. 유지 및 사라질 때 (Task를 사용하여 명시적으로 딜레이시킴으로써 Hit Target 유실 방지)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            await MainActor.run {
                guard toastContainer.superview != nil else { return }
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                    toastContainer.alpha = 0.0
                    toastContainer.transform = CGAffineTransform(translationX: 0, y: 50)
                }) { _ in
                    toastContainer.removeFromSuperview()
                }
            }
        }
    }
}
