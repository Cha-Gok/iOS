import UIKit

public final class MoveFolderListViewController: UIViewController {
    private let viewModel: MoveFolderListViewModel = .init()

    private lazy var leftTitleLable: UILabel = {
        let label = UILabel()
        label.setTypography(text: viewModel.state.leftTitle, style: .title3)
        label.textColor = .gray950

        return label
    }()

    private lazy var addFolderButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = viewModel.state.addFolderButtonTitle
        configuration.image = UIImage(systemName: "plus")
        configuration.baseForegroundColor = .gray800
        configuration.contentInsets = .zero

        return UIButton(configuration: configuration)
    }()

    private lazy var titleStack: UIStackView = {
        let stackView = UIStackView()
        [leftTitleLable, addFolderButton].forEach { stackView.addArrangedSubview($0) }
        stackView.distribution = .equalSpacing

        return stackView
    }()

    private let folderList = UIView()
    private let moveButton = UIView()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        folderList.backgroundColor = .blue
        moveButton.backgroundColor = .green
    }

    private func setupUI() {
        view.backgroundColor = .gray100

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

@MainActor
@Observable
public final class MoveFolderListViewModel {
    public struct State {
        public let leftTitle = "이동할 폴더 선택"
        public let addFolderButtonTitle = "새 폴더"
    }

    private(set) var state: State = .init()
}

#Preview {
    MoveFolderListViewController()
}
