import UIKit

/// 검색 매치 간 이동을 위한 하단 플로팅 내비게이션 바.
/// "현재 / 전체" 카운트 표시 + 이전/다음 버튼으로 구성됩니다.
public final class VoiceNoteMatchNavigationBar: UIView {
    public var onPrev: (() -> Void)?
    public var onNext: (() -> Void)?

    private let countLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .body1)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white
        return button
    }()

    public init() {
        super.init(frame: .zero)
        setupUI()
        setupActions()
        configure(currentIndex: 0, total: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    /// 현재 매치 위치와 전체 매치 개수를 표시합니다.
    /// - Parameters:
    ///   - currentIndex: 사용자에게 보여줄 1-based 인덱스 (매치가 없으면 0)
    ///   - total: 전체 매치 개수
    public func configure(currentIndex: Int, total: Int) {
        countLabel.text = "\(currentIndex) / \(total)"
        let hasMatches = total > 0
        prevButton.isEnabled = hasMatches
        nextButton.isEnabled = hasMatches
        prevButton.tintColor = hasMatches ? .white : UIColor.gray600
        nextButton.tintColor = hasMatches ? .white : UIColor.gray600
    }

    private func setupUI() {
        backgroundColor = UIColor.gray850
        layer.cornerRadius = 24
        clipsToBounds = true

        for subview in [countLabel, prevButton, nextButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),

            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -8),
            prevButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            prevButton.heightAnchor.constraint(equalToConstant: 44),

            heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupActions() {
        prevButton.addAction(UIAction { [weak self] _ in
            self?.onPrev?()
        }, for: .touchUpInside)

        nextButton.addAction(UIAction { [weak self] _ in
            self?.onNext?()
        }, for: .touchUpInside)
    }
}

#if DEBUG
    #Preview("매치 있음") {
        let bar = VoiceNoteMatchNavigationBar()
        bar.configure(currentIndex: 3, total: 24)
        let container = UIView()
        container.backgroundColor = .white
        bar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bar.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    #Preview("매치 없음") {
        let bar = VoiceNoteMatchNavigationBar()
        bar.configure(currentIndex: 0, total: 0)
        let container = UIView()
        container.backgroundColor = .white
        bar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bar.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
#endif
