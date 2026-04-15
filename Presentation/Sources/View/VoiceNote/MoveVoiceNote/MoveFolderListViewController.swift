import UIKit

final class MoveFolderListViewController: UIViewController {
    let titleStack = UIView()
    let folderList = UIView()
    let moveButton = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        titleStack.backgroundColor = .red
        folderList.backgroundColor = .blue
        moveButton.backgroundColor = .green
    }

    private func setupUI() {
        for view in [titleStack, folderList, moveButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)
        }

        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            titleStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleStack.heightAnchor.constraint(equalToConstant: 24),

            folderList.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 24),
            folderList.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            folderList.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            moveButton.topAnchor.constraint(equalTo: folderList.bottomAnchor, constant: 53),
            moveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            moveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            moveButton.heightAnchor.constraint(equalToConstant: 54),
            moveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -74),
        ])
    }
}

#Preview {
    MoveFolderListViewController()
}
