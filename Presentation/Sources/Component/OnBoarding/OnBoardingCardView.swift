import Core
import UIKit

final class OnBoardingCardView: UIStackView {
    // MARK: - State

    private let headlineText: String
    private let bodyText: String
    private let image: UIImage?

    // MARK: - Component

    private lazy var headlineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: headlineText, style: .header1)
        label.numberOfLines = Constant.onBoardingLabelNumberOfLines
        label.textColor = .gray950
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: bodyText, style: .subtitle1)
        label.numberOfLines = Constant.onBoardingLabelNumberOfLines
        label.textColor = .gray950
        return label
    }()

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let imageContainer = UIView()

    // MARK: - LifeCycle

    init(headline: String, body: String, image: UIImage?, frame: CGRect = .zero) {
        headlineText = headline
        bodyText = body
        self.image = image
        super.init(frame: frame)
        setup()
        setupHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Set up

extension OnBoardingCardView {
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = Constant.onBoardingContentSpacing

        // headline·body는 intrinsic size만 차지하고,
        // 남는 수직 공간은 imageContainer가 흡수하도록 설정
        headlineLabel.setContentHuggingPriority(.required, for: .vertical)
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)
        imageContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupHierarchy() {
        addArrangedSubview(headlineLabel)
        addArrangedSubview(bodyLabel)
        setCustomSpacing(Constant.onBoardingCardImageTopSpacing, after: bodyLabel)

        imageContainer.addSubview(imageView)
        addArrangedSubview(imageContainer)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageContainer.leadingAnchor)
        ])
    }
}
