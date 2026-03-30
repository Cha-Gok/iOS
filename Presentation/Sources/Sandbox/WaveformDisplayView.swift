import Domain
import UIKit

/// Sandbox에서 실시간 파형을 시각화하기 위한 단순한 뷰입니다.
final class WaveformDisplayView: UIView {
    private let barCount = 40
    private var bars: [UIView] = []
    private let containerStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .black
        layer.cornerRadius = 12
        clipsToBounds = true

        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        containerStackView.alignment = .center
        containerStackView.spacing = 2
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])

        for _ in 0 ..< barCount {
            let bar = UIView()
            bar.backgroundColor = .systemGreen
            bar.layer.cornerRadius = 1
            bars.append(bar)
            containerStackView.addArrangedSubview(bar)

            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: 2).isActive = true
        }
    }

    /// 새로운 파형 데이터를 받아 뷰를 업데이트합니다.
    @MainActor
    func update(with waveform: Waveform) {
        // Waveform의 amplitudes 중 마지막 값을 사용하여 바들의 높이를 시프트하며 업데이트
        guard let amplitude = waveform.amplitudes.last else { return }
        let normalizedHeight = CGFloat(max(2, Float(bounds.height - 20) * amplitude))

        // 왼쪽으로 시프트
        for i in 0 ..< barCount - 1 {
            let currentBar = bars[i]
            let nextBar = bars[i + 1]

            // 다음 바의 제약조건을 현재 바로 복사 (애니메이션 없이 단순 업데이트)
            if let heightConstraint = currentBar.constraints.first(where: { $0.firstAttribute == .height }) {
                let nextHeight = nextBar.constraints.first(where: { $0.firstAttribute == .height })?.constant ?? 2
                heightConstraint.constant = nextHeight
            }
        }

        // 마지막 바 업데이트
        if let lastHeightConstraint = bars.last?.constraints.first(where: { $0.firstAttribute == .height }) {
            lastHeightConstraint.constant = normalizedHeight
        }

        layoutIfNeeded()
    }

    @MainActor
    func reset() {
        for bar in bars {
            if let heightConstraint = bar.constraints.first(where: { $0.firstAttribute == .height }) {
                heightConstraint.constant = 2
            }
        }
        layoutIfNeeded()
    }
}
