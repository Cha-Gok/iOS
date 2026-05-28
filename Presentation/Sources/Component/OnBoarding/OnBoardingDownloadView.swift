import Core
import Domain
import SwiftUI
import UIKit

final class OnBoardingDownloadView: UIStackView {
    // MARK: - State

    var vm: OnBoardingViewModel
    private let headlineText: String
    private let bodyText: String

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
        label.numberOfLines = Constant.onBoardingLabelNumberOfLines
        label.setTypography(text: bodyText, style: .subtitle1)
        label.textColor = .gray950
        return label
    }()

    private let progressView = ImmutableProgressView()

    private let downloadMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "다운로드 상태 표기", style: .body2)
        return label
    }()
    
    private lazy var modelLabel: UIStackView = createLabel("Gemma-4", symbolName: "internaldrive")
    
    private lazy var modelCard: UIStackView = {
        let card = UIStackView(arrangedSubviews: [modelLabel, progressView, downloadMessageLabel])
        card.translatesAutoresizingMaskIntoConstraints = false
        card.axis = .vertical
        card.spacing = 8
        card.applyGlassEffect(tintColor: .point200.withAlphaComponent(0.2))
        card.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        card.isLayoutMarginsRelativeArrangement = true
        return card
    }()

    /// 남는 수직 공간을 흡수하는 빈 뷰 (OnBoardingCardView의 imageContainer 역할)
    private let spacerView = UIView()

    // MARK: - LifeCycle

    init(
        headline: String,
        body: String,
        vm: OnBoardingViewModel,
        frame: CGRect = .zero
    ) {
        headlineText = headline
        bodyText = body
        self.vm = vm
        super.init(frame: frame)
        setup()
        setupHierarchy()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateProperties() {
        super.updateProperties()
        let state = vm.status.storage
        
        switch state {
        case .notDownloaded:
            progressView.isHidden = true
            downloadMessageLabel.isHidden = true
        case .downloading:
            progressView.isHidden = false
            downloadMessageLabel.isHidden = false
            downloadMessageLabel.setTypography(text: "다운로드 중...", style: .body2)
            downloadMessageLabel.textColor = .gray950
        case .downloaded:
            progressView.isHidden = true
            downloadMessageLabel.isHidden = true
        case .failed:
            progressView.isHidden = true
            downloadMessageLabel.setTypography(text: vm.errorMessage, style: .body2)
            downloadMessageLabel.textColor = .danger
        }
    }
}

// MARK: - Private

extension OnBoardingDownloadView {
    func createLabel(_ modelName: String, symbolName: String) -> UIStackView {
        let container = UIStackView()
        let imageView = UIImageView()
        let nameLabel = UILabel()
        
        [container, imageView, nameLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // nameLabel
        nameLabel.setTypography(text: modelName, style: .body2)
        nameLabel.textColor = UIColor.gray950
        // imageView
        let config: UIImage.SymbolConfiguration = .init(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.gray950
        // container (return)
        container.axis = .horizontal
        container.spacing = 8
        // spacer
        let spacer = UIView()
        [imageView, nameLabel, spacer].forEach {
            container.addArrangedSubview($0)
        }
        
        return container
    }
}

// MARK: - Set up

extension OnBoardingDownloadView {
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = Constant.onBoardingContentSpacing
        
        // headline·body는 intrinsic size만 차지하고,
        // 남는 수직 공간은 imageContainer가 흡수하도록 설정
        headlineLabel.setContentHuggingPriority(.required, for: .vertical)
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)
        modelCard.setContentHuggingPriority(.required, for: .vertical)
        
        // progressView 높이 설정
        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func setupHierarchy() {
        addArrangedSubview(headlineLabel)
        addArrangedSubview(bodyLabel)
        addArrangedSubview(modelCard)
        addArrangedSubview(spacerView)
    }
}
