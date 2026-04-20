import Core
import Domain
import UIKit

/// 언어 선택을 위한 라디오 버튼 스타일의 피커 컴포넌트입니다.
final class LanguagePicker: UIStackView {
    // MARK: - State

    private(set) var selectedLanguage: Language
    var onLanguageChanged: ((Language) -> Void)?
    var showAlert: Bool

    private var itemViews: [LanguageItemView] = []

    // MARK: - LifeCycle

    init(selected: Language, axis: NSLayoutConstraint.Axis = .vertical, showAlert: Bool = false) {
        selectedLanguage = selected
        self.showAlert = showAlert
        super.init(frame: .zero)
        setup(axis: axis)
        createItems()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set up

    private func setup(axis: NSLayoutConstraint.Axis) {
        self.axis = axis
        spacing = axis == .horizontal ? 12 : Constant.languagePickerSpacing
        alignment = .fill
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Helper

    private func createItems() {
        let leftSpacer = UIView()
        let rightSpacer = UIView()

        if axis == .horizontal {
            leftSpacer.translatesAutoresizingMaskIntoConstraints = false
            rightSpacer.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(leftSpacer)
        }

        for language in Language.allCases {
            let itemView = LanguageItemView(language: language, isSelected: language == selectedLanguage, showAlert: showAlert)
            itemView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
            )
            addArrangedSubview(itemView)
            itemViews.append(itemView)
        }

        if axis == .horizontal {
            addArrangedSubview(rightSpacer)
            leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor).isActive = true
        }
    }

    @objc
    private func itemTapped(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view as? LanguageItemView else { return }
        let newLanguage = itemView.language

        guard newLanguage != selectedLanguage else { return }

        selectedLanguage = newLanguage
        updateSelectionState()
        onLanguageChanged?(newLanguage)
    }

    // MARK: - Update Properties

    private func updateSelectionState() {
        itemViews.forEach { $0.setSelected($0.language == selectedLanguage, showAlert: showAlert) }
    }
}

// MARK: - Internal Item

private final class LanguageItemView: UIView {
    // MARK: - State

    let language: Language
    private(set) var isSelected: Bool

    // MARK: - Component

    private let indicatorView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = Constant.languagePickerIndicatorSize / 2
        v.clipsToBounds = true
        v.backgroundColor = .gray900
        return v
    }()

    private let innerIndicatorView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = Constant.languagePickerInnerIndicatorSize / 2
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .gray950
        return l
    }()

    // MARK: - LifeCycle

    init(language: Language, isSelected: Bool, showAlert: Bool) {
        self.language = language
        self.isSelected = isSelected
        super.init(frame: .zero)
        setUp()
        setupConstraints()
        setSelected(isSelected, showAlert: showAlert)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Constraints

    private func setUp() {
        indicatorView.addSubview(innerIndicatorView)
        addSubview(indicatorView)
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: Constant.languagePickerIndicatorSize),
            indicatorView.heightAnchor.constraint(equalToConstant: Constant.languagePickerIndicatorSize),

            innerIndicatorView.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor),
            innerIndicatorView.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor),
            innerIndicatorView.widthAnchor.constraint(equalToConstant: Constant.languagePickerInnerIndicatorSize),
            innerIndicatorView.heightAnchor.constraint(equalToConstant: Constant.languagePickerInnerIndicatorSize),

            titleLabel.leadingAnchor.constraint(
                equalTo: indicatorView.trailingAnchor,
                constant: Constant.languagePickerTitleSpacing
            ),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Update Properties

    private func languageText(showAlert: Bool = false) -> String {
        switch language {
        case .ko:
            return "한국어\(showAlert ? "" : " (기본설정)")"
        case .en:
            return "영어"
        }
    }

    func setSelected(_ selected: Bool, showAlert: Bool) {
        isSelected = selected
        innerIndicatorView.backgroundColor = selected ? .point600 : .gray900
        titleLabel.textColor = selected ? .gray900 : .gray750
        titleLabel.setTypography(text: languageText(showAlert: showAlert), style: .subtitle1)
    }
}
