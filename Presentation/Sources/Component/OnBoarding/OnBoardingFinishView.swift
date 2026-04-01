import Core
import Domain
import UIKit

final class OnBoardingFinishView: UIStackView {
    // MARK: - State

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
        label.setTypography(text: bodyText, style: .subtitle1)
        label.numberOfLines = Constant.onBoardingLabelNumberOfLines
        label.textColor = .gray950
        return label
    }()

    private let languagePicker: LanguagePicker
    private var onLanguageChanged: ((Language) -> Void)?

    /// 남는 수직 공간을 흡수하는 빈 뷰 (OnBoardingCardView의 imageContainer 역할)
    private let spacerView = UIView()

    // MARK: - LifeCycle

    init(
        headline: String,
        body: String,
        selectedLanguage: Language,
        onLanguageChanged: ((Language) -> Void)? = nil,
        frame: CGRect = .zero
    ) {
        headlineText = headline
        bodyText = body
        languagePicker = .init(selected: selectedLanguage)
        self.onLanguageChanged = onLanguageChanged
        super.init(frame: frame)
        setup()
        setupHierarchy()

        languagePicker.onLanguageChanged = { [weak self] lang in
            self?.onLanguageChanged?(lang)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Set up

extension OnBoardingFinishView {
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = Constant.onBoardingContentSpacing

        // headline·body는 intrinsic size만 차지하고,
        // 남는 수직 공간은 imageContainer가 흡수하도록 설정
        headlineLabel.setContentHuggingPriority(.required, for: .vertical)
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupHierarchy() {
        addArrangedSubview(headlineLabel)
        addArrangedSubview(bodyLabel)
        addArrangedSubview(languagePicker)
        addArrangedSubview(spacerView)
    }
}
