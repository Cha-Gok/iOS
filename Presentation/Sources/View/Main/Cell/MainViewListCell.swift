import Domain
import UIKit

final class MainViewListCell: UICollectionViewCell {
    static let reuseIdentifier: String = "MainViewListCell"

    // MARK: - UI Components

    private let container: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let v = UIVisualEffectView(effect: blurEffect)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.contentView.backgroundColor = UIColor.point200.withAlphaComponent(0.2)
        return v
    }()

    private let borderLayer: CALayer = {
        let layer = CALayer()
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        layer.cornerRadius = 20
        return layer
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray950
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray700
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusChip: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.point200.withAlphaComponent(0.6).cgColor
        v.backgroundColor = UIColor.point200.withAlphaComponent(0.1)
        return v
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .point200
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = container.bounds
    }

    // MARK: - Configuration

    func configure(libraryItem: LibraryItem) {
        switch libraryItem {
        case .folder(let folder):
            titleLabel.setTypography(text: folder.name, style: .title3)
            subtitleLabel.setTypography(text: "폴더 · \(folder.content.count)개의 항목", style: .caption)
            statusChip.isHidden = true
        case .voiceNote(let voiceNote):
            titleLabel.setTypography(text: voiceNote.title, style: .title3)

            let timeString = formatTime(voiceNote.createdAt)
            let durationString = formatDuration(voiceNote.voiceRecord.duration)
            subtitleLabel.setTypography(text: "\(timeString) · \(durationString)", style: .caption)

            statusChip.isHidden = voiceNote.summary == nil
            statusLabel.setTypography(text: "요약 완료", style: .label)
        }
    }

    // MARK: - Private Methods

    private func setupUI() {
        contentView.addSubview(container)
        container.layer.addSublayer(borderLayer)

        for item in [titleLabel, subtitleLabel, statusChip] {
            container.contentView.addSubview(item)
        }

        statusChip.addSubview(statusLabel)

        let bottomConstraint = statusChip.bottomAnchor.constraint(
            equalTo: container.contentView.bottomAnchor,
            constant: -18
        )
        bottomConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: container.contentView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            statusChip.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            statusChip.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomConstraint,
            statusChip.heightAnchor.constraint(equalToConstant: 28),

            statusLabel.leadingAnchor.constraint(equalTo: statusChip.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusChip.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: statusChip.centerYAnchor)
        ])
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 \(seconds)초"
        } else if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
