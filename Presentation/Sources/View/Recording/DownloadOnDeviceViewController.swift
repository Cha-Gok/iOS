import Foundation
import UIKit

public final class DownloadOnDeviceViewController: UIViewController, Alertable {
    // MARK: Componenet

    private lazy var titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: "음성을 글로 옮길 준비가 필요해요", style: .header2)
        t.textColor = UIColor.gray950
        return t
    }()

    private lazy var subTitleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(
            text: "녹음과 요약을 모두 기기 안에서\n처리하기 위해 AI모델이 필요해요",
            style: .subtitle2
        )
        t.numberOfLines = 0
        t.textColor = UIColor.gray800
        return t
    }()

    private lazy var subTitle2Label: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(
            text: "Wi-Fi연결을 권장하며 몇 분 정도 걸려요.", style: .subtitle2
        )
        t.numberOfLines = 1
        t.textColor = UIColor.gray950
        t.textAlignment = .center
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

    private let infoBox: OnDeviceInfoBox = .init()

    private lazy var downloadModelCard = DownloadModelCard(
        symbolName: "externaldrive",
        modelName: "Whisper",
        style: .default,
        storage: vm.status.storage,
        modelSize: vm.modelSize
    )

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
        isModalInPresentation = true
        setup()
        setupActions()
    }

    override public func updateProperties() {
        super.updateProperties()
        applyDownloadState()
    }

    private func setup() {
        for item in [titleLabel, subTitleLabel, infoBox, downloadModelCard, subTitle2Label] {
            view.addSubview(item)
        }

        bottomContainer.addArrangedSubview(cancelButton)
        bottomContainer.addArrangedSubview(primaryButton)
        view.addSubview(bottomArea)
        bottomArea.addSubview(bottomContainer)
        bottomArea.addSubview(cancelDownloadButton)

        NSLayoutConstraint.activate([
            // titleLabel
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 54),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // subTitleLabel
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // infoBox
            infoBox.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 24),
            infoBox.leadingAnchor.constraint(equalTo: subTitleLabel.leadingAnchor),
            infoBox.trailingAnchor.constraint(equalTo: subTitleLabel.trailingAnchor),

            // downloadModelCard
            downloadModelCard.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 24),
            downloadModelCard.leadingAnchor.constraint(equalTo: subTitleLabel.leadingAnchor),
            downloadModelCard.trailingAnchor.constraint(equalTo: subTitleLabel.trailingAnchor),

            // subTitleLabel2
            subTitle2Label.topAnchor.constraint(equalTo: infoBox.bottomAnchor, constant: 24),
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
            cancelDownloadButton.bottomAnchor.constraint(equalTo: bottomArea.bottomAnchor)
        ])
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
        let isFailed = vm.status.storage == .failed
        let isShowingCard = isDownloading || isFailed

        primaryButton.configuration?.title = isFailed ? "재시도" : "다운로드"

        cancelButton.isExclusiveTouch = isDownloading
        bottomContainer.isHidden = isDownloading
        cancelDownloadButton.isExclusiveTouch = !isDownloading
        cancelDownloadButton.isHidden = !isDownloading
        infoBox.isHidden = isShowingCard
        downloadModelCard.isHidden = !isShowingCard
        if isShowingCard {
            downloadModelCard.updateStatus(
                vm.status.storage,
                errorMessage: vm.errorMessage,
                modelSize: vm.modelSize
            )
        }
    }
}
