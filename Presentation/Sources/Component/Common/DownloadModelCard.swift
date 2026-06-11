import Domain
import SwiftUI
import UIKit

final class DownloadModelCard: UIStackView {
    let modelName: String
    let symbolName: String
    let style: ProgressStyle
    var storage: OnDeviceStatus.StorageState
    var errorMessage: String?
    var modelSize: String

    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.point800
        return label
    }()

    // MARK: - Initialize

    init(
        symbolName: String,
        modelName: String,
        style: ProgressStyle,
        storage: OnDeviceStatus.StorageState,
        errorMessage: String? = nil,
        modelSize: String = "",
        frame: CGRect = .zero
    ) {
        self.symbolName = symbolName
        self.modelName = modelName
        self.style = style
        self.storage = storage
        self.errorMessage = errorMessage
        self.modelSize = modelSize
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Component

    private lazy var modelLabel: UIStackView = createLabel(modelName, symbolName: symbolName)

    private lazy var immutableProgressView = ImmutableProgressView()
    private lazy var defaultProgressView = DefaultProgressView()

    private let downloadMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: "다운로드 상태 표기", style: .body2)
        return label
    }()

    // MARK: - LifeCycle

    override func updateProperties() {
        super.updateProperties()
        updateStatus()
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 8
        applyGlassEffect(tintColor: .point200.withAlphaComponent(0.2))
        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        isLayoutMarginsRelativeArrangement = true

        addArrangedSubview(modelLabel)
        switch style {
        case .default:
            addArrangedSubview(defaultProgressView)
            defaultProgressView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        case .immutable:
            addArrangedSubview(immutableProgressView)
            immutableProgressView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        }
        addArrangedSubview(downloadMessageLabel)
    }

    /// 프로그래스의 스타일을 정의합니다.
    enum ProgressStyle: Equatable {
        case `default` // 기본 스타일
        case immutable // 불변 프로그래스 바
    }
}

// MARK: - Private

extension DownloadModelCard {
    /// model의 이름과 이미지를 표기하는 View입니다.
    func createLabel(_ modelName: String, symbolName: String) -> UIStackView {
        let container = UIStackView()
        let imageView = UIImageView()
        let nameLabel = UILabel()
        
        for item in [container, imageView, nameLabel, sizeLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
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
        // model size
        sizeLabel.setTypography(text: modelSize, style: .label)
        for item in [imageView, nameLabel, spacer, sizeLabel] {
            container.addArrangedSubview(item)
        }

        return container
    }
}

// MARK: - Update

extension DownloadModelCard {
    func updateStatus(_ storage: OnDeviceStatus.StorageState, errorMessage: String?, modelSize: String? = nil) {
        self.storage = storage
        self.errorMessage = errorMessage
        if let modelSize {
            self.modelSize = modelSize
            sizeLabel.setTypography(text: modelSize, style: .label)
        }
        setNeedsUpdateProperties()
    }

    private func updateStatus() {
        switch storage {
        case .notDownloaded:
            switch style {
            case .default:
                defaultProgressView.isHidden = true
            case .immutable:
                immutableProgressView.isHidden = true
            }
            downloadMessageLabel.isHidden = true
        case .downloading(let progress):
            switch style {
            case .default:
                defaultProgressView.isHidden = false
                defaultProgressView.setProgress(Float(progress), animated: true)
            case .immutable:
                immutableProgressView.isHidden = false
            }
            downloadMessageLabel.isHidden = true
        case .downloaded:
            switch style {
            case .default:
                defaultProgressView.isHidden = true
            case .immutable:
                immutableProgressView.isHidden = true
            }
            downloadMessageLabel.isHidden = true
        case .failed:
            switch style {
            case .default:
                defaultProgressView.isHidden = true
            case .immutable:
                immutableProgressView.isHidden = true
            }
            downloadMessageLabel.isHidden = false
            let msg = (errorMessage == nil || errorMessage?.isEmpty == true) ? "다운로드에 실패했습니다" : errorMessage
            downloadMessageLabel.setTypography(text: msg, style: .body2)
            downloadMessageLabel.textColor = .danger
        }
    }
}
