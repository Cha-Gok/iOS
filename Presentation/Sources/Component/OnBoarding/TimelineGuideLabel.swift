import Domain
import UIKit

final class TimelineGuideLabel: UILabel {
    private var timer: Timer?
    private var state: OnDeviceStatus.StorageState = .notDownloaded
    private var index: Int = 0

    init(
        state: OnDeviceStatus.StorageState,
        frame: CGRect = .zero
    ) {
        self.state = state
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func updateProperties() {
        super.updateProperties()
        updateState()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        textColor = UIColor.gray950
        numberOfLines = 0
        clipsToBounds = true
    }

    func updateLabelState(_ state: OnDeviceStatus.StorageState) {
        guard self.state != state else { return }
        self.state = state
        setNeedsUpdateProperties()
    }

    private func updateState() {
        switch state {
        case .notDownloaded, .downloaded, .failed:
            stopTimer()
        case .downloading:
            startTimer()
        }
    }

    /// timeLine을 시작합니다.
    private func startTimer() {
        guard timer == nil else { return }

        // 시작하자마자 첫 텍스트가 바로 보이도록 설정
        index = 0
        updateLabel(animated: false)

        // 4초 주기로 텍스트 롤링 타이머 구동
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.index += 1
                self.updateLabel(animated: true)
            }
        }
    }

    /// timeLine의 진행을 멈춥니다.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        text = "" // 다운로드 중이 아닐 때는 표시하지 않음
        alpha = 1
        transform = .identity
    }

    /// 텍스트 업데이트 및 아래에서 위로 올라오는 전환 효과 적용
    private func updateLabel(animated: Bool) {
        let nextText = toolTips[index % toolTips.count]

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: -12)
            }) { [weak self] _ in
                guard let self else { return }
                text = nextText
                setTypography(text: nextText, style: .body3, textAlignment: .center)
                transform = CGAffineTransform(translationX: 0, y: 12)

                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                    self.alpha = 1
                    self.transform = .identity
                })
            }
        } else {
            text = nextText
            setTypography(text: text, style: .body3, textAlignment: .center)
        }
    }
}

extension TimelineGuideLabel {
    /// timeline을 통해 보여줄 데이터
    private var toolTips: [String] {
        [
            "차곡의 모든 인공지능 요약 연산은 기기 안에서만 처리돼요.\n내 소중한 대화 내용이 절대 외부 서버로 전송되거나 유출되지 않으니 안심하세요!",
            "다운로드가 완료되면 인터넷이 연결되지 않은 비행기 모드나 데이터가 터지지 않는 깊은 산속에서도 음성 인식과 요약 기능을 그대로 사용할 수 있어요.",
            "길게 녹음된 음성을 처음부터 다 들을 필요 없어요.\n차곡의 AI가 회의나 대화의 핵심 내용과 키워드만 일목요연하게 요약해 줍니다.",
            "실수로 삭제한 소중한 기록은 휴지통 폴더에 보관돼요.\n완전히 지워지기 전이라면 언제든 터치 한 번으로 복구할 수 있어요.",
            "폴더 기능을 활용해 회의록, 아이디어 노트, 강의 녹음 등 주제별로 정리해 보세요. 정돈된 분류는 나중에 기록을 다시 꺼내볼 때 시간을 절약해 줘요.",
            "안정적인 설치를 위해 기기에 약 4GB 이상의 여유 공간이 필요해요. 다운로드가 원활하지 않다면 기기의 저장 공간을 직접 정리해 주세요."
        ]
    }
}
