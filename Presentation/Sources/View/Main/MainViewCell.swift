import UIKit

final class MainViewCell: UICollectionViewCell {
    static let reuseIdentifier: String = "MainViewCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
