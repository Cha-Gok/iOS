import Domain
import UIKit

final class FolderViewCell: UITableViewCell {
    static let reuseIdentifier: String = "FolderViewCell"

    // MARK: - Component

    private let prefixImage: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFit
        return img
    }()

    private let titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.textColor = UIColor.gray800
        return t
    }()

    private let countLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.textColor = UIColor.gray800
        return t
    }()

    // MARK: - Initialize

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - LifeCycle

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame.inset(by: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor.gray50
        contentView.addSubview(prefixImage)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        setupConstraint()
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            prefixImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            prefixImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            prefixImage.widthAnchor.constraint(equalToConstant: 24),
            prefixImage.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: prefixImage.trailingAnchor, constant: 12),

            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Helper

    func configure(with item: LibraryItem) {
        switch item {
        case .folder(let folder):
            prefixImage.image = UIImage(systemName: "folder.fill")
            prefixImage.tintColor = UIColor.gray600
            titleLabel.setTypography(text: folder.name, style: .body2)
            countLabel.setTypography(text: "\(folder.voiceNoteIDs.count)", style: .body2)
        case .voiceNote(let voiceNote):
            prefixImage.image = UIImage(systemName: "waveform")
            prefixImage.tintColor = UIColor.gray600
            titleLabel.setTypography(text: voiceNote.title, style: .body2)

            let minutes = Int(voiceNote.voiceRecord.duration) / 60
            let seconds = Int(voiceNote.voiceRecord.duration) % 60
            let durationString = String(format: "%02d:%02d", minutes, seconds)
            countLabel.setTypography(text: durationString, style: .body2)
        }
    }
}
