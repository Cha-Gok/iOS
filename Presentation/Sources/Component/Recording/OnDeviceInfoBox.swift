import UIKit

/// 온디바이스 Whisper 다운로드 시트에서 보여줄 정보입니다.
final class OnDeviceInfoBox: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let data: [(symbolName: String, text: String)] = [
        (symbolName: "interfaceLockShield", text: "녹음한 목소리가 기기 밖으로 나가지 않아요"),
        (symbolName: "cloudOff", text: "인터넷 없이도 받아쓰기와 요약이 가능해요"),
        (symbolName: "entertainmentRecording", text: "길이 제한 없이 기록 할 수 있어요")
    ]

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        spacing = 16
        axis = .vertical
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        applyGlassEffect(tintColor: .point200.withAlphaComponent(0.2))
        for (symbolName, text) in data {
            let info = createLabel(symbolName: symbolName, text: text)
            addArrangedSubview(info)
        }
    }
}

// MARK: - Helper

extension OnDeviceInfoBox {
    func createLabel(symbolName: String, text: String) -> UIStackView {
        let imageView = UIImageView()
        let label = UILabel()

        for item in [imageView, label] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        let sizeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let colorConfig = UIImage.SymbolConfiguration(paletteColors: [.point600])
        let combinedConfig = sizeConfig.applying(colorConfig)

        if let systemImage = UIImage(systemName: symbolName, withConfiguration: combinedConfig) {
            imageView.image = systemImage
        } else {
            let bundle = Bundle(for: OnDeviceInfoBox.self)
            if let assetImage = UIImage(named: symbolName, in: bundle, with: nil) {
                imageView.image = assetImage.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .point600
            } else if let assetImage = UIImage(named: "icon/\(symbolName)", in: bundle, with: nil) {
                imageView.image = assetImage.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .point600
            }
        }
        imageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        // label
        label.setTypography(text: text, style: .body1)
        label.textColor = .gray950
        // spacer
        let spacer = UIView()
        // container
        let container = UIStackView(arrangedSubviews: [imageView, label, spacer])
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 8

        return container
    }
}
