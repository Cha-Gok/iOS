import Core
import Domain
import UIKit

/// 항상 가로 방향으로 30% 너비의 인디케이터가 우측으로 이동하며 부드럽게 생성되고 사라지는 키프레임 애니메이션이 반복되는 커스텀 프로그레스 바.
/// TrackView: .gray600
/// IndicatorView: ImmutableIndicator
public final class ImmutableProgressView: UIView {
    
    // MARK: - Component
    
    private let trackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray600
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private let indicatorView: ImmutableIndicator = {
        let view = ImmutableIndicator()
        return view
    }()
    
    // MARK: - Properties
    
    private var isAnimating = false
    private var lastWidth: CGFloat = 0
    
    // MARK: - LifeCycle
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupHierarchy()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        setupHierarchy()
        setupLayout()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // 가로 방향으로 스윕하며 이동하는 애니메이션 적용 및 레이아웃 루프 인터럽트 방지
        if bounds.width > 0 {
            if bounds.width != lastWidth {
                lastWidth = bounds.width
                stopAnimation()
                startAnimation()
            } else {
                startAnimation()
            }
        }
    }    
}

// MARK: - Private Setup

extension ImmutableProgressView {
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupHierarchy() {
        addSubview(trackView)
        trackView.addSubview(indicatorView)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // trackView
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // indicatorView (높이는 트랙과 동일, leading에 밀착)
            indicatorView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            indicatorView.topAnchor.constraint(equalTo: trackView.topAnchor),
            indicatorView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            
            // 항상 전체 트랙의 30% 너비 유지
            indicatorView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: 0.3)
        ])
    }
    
    // MARK: - Update
    func updateIndicator() {
        
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        let totalWidth = bounds.width
        guard !isAnimating, totalWidth > 0 else { return }
        isAnimating = true
        
        // 30% 너비이므로 가용 우측 이동 가능 거리는 70%
        let maxTranslation = totalWidth * 0.7
        
        animateIndicator(maxTranslation: maxTranslation)
    }
    
    private func animateIndicator(maxTranslation: CGFloat) {
        guard isAnimating else { return }
        
        // 출발점 초기화 (시작은 눈이 피로하지 않도록 완전히 투명하게 설정)
        self.indicatorView.transform = .identity
        self.indicatorView.alpha = 0.0
        
        UIView.animateKeyframes(
            withDuration: 1.8,
            delay: 0.0,
            options: [.calculationModeCubic],
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    self.indicatorView.transform = CGAffineTransform(translationX: maxTranslation, y: 0)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    self.indicatorView.alpha = 1.0
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.indicatorView.alpha = 0.0
                }
            },
            completion: { [weak self] finished in
                guard let self else { return }
                Task { @MainActor in
                    if finished && self.isAnimating {
                        self.animateIndicator(maxTranslation: maxTranslation)
                    }
                }
            }
        )
    }
    
    private func stopAnimation() {
        isAnimating = false
        indicatorView.layer.removeAllAnimations()
        indicatorView.transform = .identity
        indicatorView.alpha = 0.0
    }
}
