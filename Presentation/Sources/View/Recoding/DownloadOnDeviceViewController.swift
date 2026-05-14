import Foundation
import UIKit

public final class DownloadOnDeviceViewController: UIViewController, Alertable {
    // MARK: Componenet

    private lazy var titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: "차곡 모델 다운로드", style: .title2)
        t.textColor = UIColor.gray950
        return t
    }()

    private lazy var subTitleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(
            text: "차곡은 AI를 당신의 다비아스에서 실행 합니다.\n덕분에", style: .body1
        )
        t.numberOfLines = 0
        t.textColor = UIColor.gray800
        return t
    }()

    private lazy var subTitle2Label: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(
            text: "모델을 통해 압도적인 정확도와 음성 인식 및 AI 요약을 경험해보세요.", style: .label
        )
        t.numberOfLines = 2
        t.textColor = UIColor.gray800
        return t
    }()

    private var cancelButton: GlassButton = {
        let button = GlassButton.close("나중에")
        button.isExclusiveTouch = true
        return button
    }()

    private var primaryButton: GlassButton = .primary("다운로드")
    private var cancelDownloadButton: GlassButton = .primary("취소")
    private let bottomArea: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var bottomContainer: UIStackView = {
        let bottom = UIStackView()
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.axis = .horizontal
        bottom.spacing = 12
        return bottom
    }()

    private let progressTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "모델 다운로드 중", style: .subtitle2)
        label.textColor = .gray950
        return label
    }()

    private let progressPercentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "0%", style: .subtitle2)
        label.textColor = .gray950
        label.textAlignment = .right
        return label
    }()

    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .gray500
        progressView.progressTintColor = .point900
        progressView.progress = 0
        return progressView
    }()

    private lazy var progressHeaderStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressTitleLabel, progressPercentLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    private lazy var progressContainer: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressHeaderStack, progressView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.isHidden = true
        return stack
    }()

    // MARK: - Initialize

    private let vm: DownloadOnDeviceViewModel

    public init(vm: DownloadOnDeviceViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray200
        setup()
        setupActions()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        vm.cancelDownload()
    }

    override public func updateProperties() {
        super.updateProperties()
        applyDownloadState()
    }

    private func setup() {
        let firstList = createListLabelText(text: "무료로 계속 사용 가능합니다")
        let secondList = createListLabelText(text: "데이터가 외부로 유출되지 않고 안전하게 사용 가능합니다.")
        for item in [titleLabel, subTitleLabel, firstList, secondList, subTitle2Label] {
            view.addSubview(item)
        }

        bottomContainer.addArrangedSubview(cancelButton)
        bottomContainer.addArrangedSubview(primaryButton)
        view.addSubview(bottomArea)
        bottomArea.addSubview(bottomContainer)
        bottomArea.addSubview(cancelDownloadButton)
        view.addSubview(progressContainer)

        NSLayoutConstraint.activate([
            // titleLabel
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // subTitleLabel
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // firstList
            firstList.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 10),
            firstList.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstList.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // secondList
            secondList.topAnchor.constraint(equalTo: firstList.bottomAnchor, constant: 8),
            secondList.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            secondList.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // subTitleLabel2
            subTitle2Label.topAnchor.constraint(equalTo: secondList.bottomAnchor, constant: 10),
            subTitle2Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subTitle2Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // bottomArea
            bottomArea.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomArea.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomArea.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomArea.heightAnchor.constraint(equalToConstant: Constant.commonButtonHeight),
            // bottomContainer
            bottomContainer.topAnchor.constraint(equalTo: bottomArea.topAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: bottomArea.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: bottomArea.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: bottomArea.bottomAnchor),
            // cancelDownloadButton
            cancelDownloadButton.topAnchor.constraint(equalTo: bottomArea.topAnchor),
            cancelDownloadButton.leadingAnchor.constraint(equalTo: bottomArea.leadingAnchor),
            cancelDownloadButton.trailingAnchor.constraint(equalTo: bottomArea.trailingAnchor),
            cancelDownloadButton.bottomAnchor.constraint(equalTo: bottomArea.bottomAnchor),
            // progressContainer
            progressContainer.bottomAnchor.constraint(equalTo: bottomArea.topAnchor, constant: -12),
            progressContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // progressView
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
}

// MARK: - Helper

extension DownloadOnDeviceViewController {
    /// 장점을 표현하기 위한 list label을 생성 하는 함수
    private func createListLabelText(symbol: String = "checkmark", text: String) -> UIStackView {
        let listLabel = UIStackView()
        let imageView = UIImageView()
        let label = UILabel()
        [listLabel, imageView, label].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        // listLabel
        listLabel.spacing = 8
        // image
        let symbolConfig: UIImage.SymbolConfiguration = .init(pointSize: 12, weight: .bold)
        imageView.image = UIImage(systemName: symbol, withConfiguration: symbolConfig)
        imageView.tintColor = .point900
        imageView.contentMode = .scaleAspectFit
        // label
        label.setTypography(text: text, style: .label)
        label.textColor = .gray950
        label.numberOfLines = 2
        listLabel.addArrangedSubview(imageView)
        listLabel.addArrangedSubview(label)

        return listLabel
    }
}

// MARK: - Bindings

private extension DownloadOnDeviceViewController {
    func setupActions() {
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.vm.dismiss()
        }, for: .touchUpInside)

        primaryButton.addAction(UIAction { [weak self] _ in
            self?.vm.download()
        }, for: .touchUpInside)

        cancelDownloadButton.addAction(UIAction { [weak self] _ in
            self?.vm.cancelDownload()
        }, for: .touchUpInside)
    }

    /// 다운로드 진행 상태값을 업데이트 합니다.
    func applyDownloadState() {
        let isDownloading = vm.isDownloading
        cancelButton.isExclusiveTouch = isDownloading
        bottomContainer.isHidden = isDownloading
        cancelDownloadButton.isExclusiveTouch = !isDownloading
        cancelDownloadButton.isHidden = !isDownloading
        progressContainer.isHidden = !isDownloading

        guard isDownloading else {
            progressView.setProgress(0, animated: false)
            progressPercentLabel.setTypography(text: "0%", style: .subtitle2)
            return
        }
        let fraction = Float(vm.progressFraction ?? 0)
        progressView.setProgress(fraction, animated: true)
        progressPercentLabel.setTypography(text: vm.progressPercentText, style: .subtitle2)
    }
}
