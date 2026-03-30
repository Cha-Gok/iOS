import Core
import UIKit

final class OnBoardingPagingView: UIScrollView {
    // MARK: - Component

    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - LifeCycle

    init(pages: [UIView]) {
        super.init(frame: .zero)
        setup()
        configure(pages: pages)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Set up

extension OnBoardingPagingView {
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false

        addSubview(containerStackView)

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            containerStackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ])
    }

    private func configure(pages: [UIView]) {
        for cardView in pages {
            containerStackView.addArrangedSubview(cardView)

            // 각 카드의 너비를 자신(UIScrollView)의 프레임과 일치시켜 페이징 구현
            NSLayoutConstraint.activate([
                cardView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor)
            ])
        }
    }
}
