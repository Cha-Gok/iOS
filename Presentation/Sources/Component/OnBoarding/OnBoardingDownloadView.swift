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

    private lazy var downloadModelCard = DownloadModelCard(
        symbolName: "externaldrive",
        modelName: "Gemma-4",
        style: .immutable,
        storage: vm.status.storage,
        modelSize: vm.modelSize
    )

    private lazy var timeLineGuideLabel: TimelineGuideLabel = .init(state: .notDownloaded)

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
        let storage = vm.status.storage
        downloadModelCard.updateStatus(storage, errorMessage: vm.errorMessage)
        timeLineGuideLabel.updateLabelState(storage)
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
        downloadModelCard.setContentHuggingPriority(.required, for: .vertical)
        timeLineGuideLabel.setContentHuggingPriority(.required, for: .vertical)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)

        // 텍스트 및 카드 찌그러짐 방지 제약조건 추가
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        downloadModelCard.setContentCompressionResistancePriority(.required, for: .vertical)
        timeLineGuideLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func setupHierarchy() {
        addArrangedSubview(headlineLabel)
        addArrangedSubview(bodyLabel)
        addArrangedSubview(downloadModelCard)
        setCustomSpacing(0, after: downloadModelCard)
        addArrangedSubview(spacerView)
        setCustomSpacing(0, after: spacerView)
        addArrangedSubview(timeLineGuideLabel)
    }
}
