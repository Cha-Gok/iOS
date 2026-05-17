import Core
import Domain
import UIKit
import SwiftUI

final class OnBoardingDownloadView: UIStackView {
    // MARK: - State
    var vm: OnBoardingViewModel
    private let headlineText: String

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
        label.textColor = .gray950
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .gray200
        progressView.progressTintColor = .point900
        progressView.progress = 0
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    private let progressPercentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "0%", style: .title3)
        label.textColor = .point800
        label.textAlignment = .right
        return label
    }()
    
    private lazy var modelCard: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 글래스 효과 적용
        container.applyGlassEffect(cornerRadius: 24, tintColor: .point200.withAlphaComponent(0.4))
        
        // 내부 레이아웃용 스택뷰
        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        
        // 1. 상단 정보 (아이콘 + 모델명 + %)
        let infoHeader = createListLabelText(
            symbol: "cpu.fill",
            text: "온디바이스 AI 모델",
            text2: "0%"
        )
        
        // 2. 하단 상태 메시지
        [infoHeader, progressView].forEach { contentStack.addArrangedSubview($0) }
        
        container.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            // 카드 내부 여백 설정
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            
            // 프로그레스 바 두께 조절
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        // 프로그레스 바 내부 레이어 코너 라운딩 처리
        progressView.subviews.forEach { subview in
            subview.layer.cornerRadius = 4
            subview.clipsToBounds = true
        }
        
        return container
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
        self.vm = vm
        super.init(frame: frame)
        setup()
        setupHierarchy()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle

    override func updateProperties() {
        super.updateProperties()
        updateView()
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
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        modelCard.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupHierarchy() {
        addArrangedSubview(headlineLabel)
        addArrangedSubview(bodyLabel)
        addArrangedSubview(modelCard)
        addArrangedSubview(spacerView)
        updateView()
    }
}

// MARK: - Helper

extension OnBoardingDownloadView {
    private func createListLabelText(symbol: String? = nil, text: String, text2: String) -> UIStackView {
        let listLabel = UIStackView()
        let imageView = UIImageView()
        let label = UILabel()
        let spacerView = UIView()
        [listLabel, imageView, label, progressPercentLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        // listLabel
        listLabel.spacing = 8
        listLabel.axis = .horizontal
        // image
        if let symbol = symbol {
            let symbolConfig: UIImage.SymbolConfiguration = .init(pointSize: 12, weight: .bold)
            imageView.image = UIImage(systemName: symbol, withConfiguration: symbolConfig)
            imageView.tintColor = .gray200
            imageView.contentMode = .scaleAspectFit
        }
        // label
        label.setTypography(text: text, style: .body2)
        label.textColor = .gray950
        label.numberOfLines = 2
        // progress label
        progressPercentLabel.setTypography(text: text2, style: .title3)
        progressPercentLabel.setContentHuggingPriority(.required, for: .horizontal)
        progressPercentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // result
        listLabel.addArrangedSubview(imageView)
        listLabel.addArrangedSubview(label)
        listLabel.addArrangedSubview(spacerView)
        listLabel.addArrangedSubview(progressPercentLabel)
        return listLabel
    }
}

// MARK: - Update Method

extension OnBoardingDownloadView {
    private func updateView() {
        bodyLabel.setTypography(text: vm.downloadStatus.message,style: .subtitle1)
        modelCard.isHidden = vm.modelCardIsHidden
        progressView.setProgress(Float(vm.downloadStatus.progress), animated: true)
        progressPercentLabel.setTypography(
            text: vm.progressPercentText,
            style: .title3
        )
    }
}
