import Foundation
import UIKit

final class Pagenation: UIStackView {
    /// 현재 활성화된 스텝을 저장합니다 (0부터 시작)
    private(set) var currentStep: Int = 0 {
        didSet {
            updateSteps()
        }
    }

    private let totalSteps = Constant.pagenationTotalValue
    private let indicatorView = UIView()

    override init(frame: CGRect) {
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

        for _ in 0 ..< totalSteps {
            let step = createStep()
            step.backgroundColor = UIColor.gray300 // 기본 배경색
            addArrangedSubview(step)
        }

        indicatorView.backgroundColor = UIColor.gray950
        addSubview(indicatorView)

        // 초기 상태 업데이트
        updateSteps()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard arrangedSubviews.indices.contains(currentStep) else { return }

        // 인디케이터가 현재 스텝의 프레임을 따라가도록 설정
        indicatorView.frame = arrangedSubviews[currentStep].frame
    }

    /// 현재 스텝에 맞게 인디케이터를 부드럽게 이동시킵니다.
    private func updateSteps() {
        setNeedsLayout()

        UIView.animate(withDuration: Constant.animationDuration, delay: 0, options: .curveEaseInOut) {
            self.layoutIfNeeded()
        }
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

    /// 다음 스텝으로 진행합니다. 이미 마지막 스텝인 경우 아무 동작도 하지 않습니다.
    func next() {
        guard currentStep < totalSteps - Constant.pagenationMoveCount else { return }
        currentStep += Constant.pagenationMoveCount
    }

    /// 이전 스텝으로 되돌아갑니다. 이미 가장 첫 번째 스텝인 경우 아무 동작도 하지 않습니다.
    func prev() {
        guard currentStep > 0 else { return }
        currentStep -= Constant.pagenationMoveCount
    }

    /// 스텝을 건너뛰어 맨 마지막 스텝 상태로 단번에 이동합니다.
    func skip() {
        guard currentStep != totalSteps - Constant.pagenationMoveCount else { return }
        currentStep = totalSteps - Constant.pagenationMoveCount
    }
}
