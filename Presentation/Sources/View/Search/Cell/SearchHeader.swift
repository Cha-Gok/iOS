import UIKit

final class SearchHeader: UICollectionReusableView {
    static let elementKind: String = "SearchHeader"

    // MARK: - Component

    private let container: UIStackView = {
        let search = UIStackView()
        search.translatesAutoresizingMaskIntoConstraints = false
        search.axis = .horizontal
        search.spacing = 2

        return search
    }()

    private let searchResultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "검색 결과", style: .title3)
        label.textColor = .gray800

        return label
    }()

    private let resultCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .point700

        return label
    }()

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setup() {
        let spacer = UIView()
        container.addArrangedSubview(searchResultLabel)
        container.addArrangedSubview(resultCountLabel)
        container.addArrangedSubview(spacer)
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    func configure(
        resultCount: Int
    ) {
        resultCountLabel.setTypography(text: String(resultCount), style: .title3)
    }
}
