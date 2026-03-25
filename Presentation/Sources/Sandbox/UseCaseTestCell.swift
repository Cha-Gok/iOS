import UIKit

final class UseCaseTestCell: UITableViewCell {
    static let identifier = "UseCaseTestCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let runButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("실행", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    var onRunTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        runButton.translatesAutoresizingMaskIntoConstraints = false

        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)

        contentView.addSubview(titleLabel)
        contentView.addSubview(runButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: runButton.leadingAnchor, constant: -8),

            runButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            runButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            runButton.widthAnchor.constraint(equalToConstant: 60),
            runButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(with title: String) {
        titleLabel.text = title
    }

    @objc
    private func runTapped() {
        onRunTapped?()
    }
}
