import Foundation
import UIKit

final class Pagenation: UIStackView {
    /// 현재 활성화된 인덱스를 저장합니다 (0부터 시작)
    var currentIndex: Int {
        didSet {
            setNeedsLayout()
        }
    }

    private let maxIndex: Int
    private let indicatorView = UIView()

    init(
        currentIndex: Int,
        maxIndex: Int,
        frame: CGRect = .zero
    ) {
        self.currentIndex = currentIndex
        self.maxIndex = maxIndex
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .horizontal
        spacing = Constant.pagenationSpacing
        distribution = .fillEqually
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false

        for _ in 0 ..< maxIndex {
            let step = createStep()
            step.backgroundColor = UIColor.gray400 // 기본 배경색
            addArrangedSubview(step)
        }

        indicatorView.backgroundColor = UIColor.gray950
        addSubview(indicatorView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard arrangedSubviews.indices.contains(currentIndex) else { return }

        // 인디케이터가 현재 스텝의 프레임을 따라가도록 설정
        indicatorView.frame = arrangedSubviews[currentIndex].frame
    }
}

// MARK: - Helper 함수 ( Step UIView )

extension Pagenation {
    /// Pagenation을 구성하는 개별 스텝 뷰(선)를 생성하여 반환합니다.
    /// 높이 제약조건이 내부적으로 함께 설정됩니다.
    private func createStep() -> UIView {
        let step = UIView()
        step.translatesAutoresizingMaskIntoConstraints = false
        step.heightAnchor.constraint(equalToConstant: Constant.pagenationHeight).isActive = true

        return step
    }
}
