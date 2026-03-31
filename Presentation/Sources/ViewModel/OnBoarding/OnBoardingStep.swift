import Core
import Foundation

struct OnBoardingItem: Equatable {
    let headline: String
    let body: String
    let image: String?

    init(headline: String, body: String, image: String? = nil) {
        self.headline = headline
        self.body = body
        self.image = image
    }
}

enum Step: Int, CaseIterable, Equatable {
    case first = 0
    case second
    case micPermission
    case finish

    var rawValue: Int {
        switch self {
        case .first:
            return 0
        case .second:
            return 1
        case .micPermission:
            return 2
        case .finish:
            return 3
        }
    }

    static func matchingStep(_ val: Int) -> Step {
        switch val {
        case 0:
            return .first
        case 1:
            return .second
        case 2:
            return .micPermission
        case 3:
            return .finish
        default:
            AppLogger.warning("매칭되지 않는 Int값이 들어왔습니다, value: \(val)")
            return .first
        }
    }

    var item: OnBoardingItem {
        switch self {
        case .first:
            OnBoardingItem(
                headline: "녹음부터 요약까지,\n내 기기에서 한 번에",
                body: "서버 업로드 없이 저장되는\n프라이빗 기록",
                image: "onboarding01"
            )
        case .second:
            OnBoardingItem(
                headline: "하루가 끝나면,\n기억은 먼저 정리돼버려요.",
                body: "놓치고 싶지 않은 말들이 있다면,\n내 기기에 차곡차곡 기록하고 요약까지",
                image: "onboarding02"
            )
        case .micPermission:
            OnBoardingItem(
                headline: "필요한 권한만\n요청할게요.",
                body: "녹음을 시작하려면\n마이크 권한이 필요해요.",
                image: "onboarding03"
            )
        case .finish:
            OnBoardingItem(
                headline: "기록할 언어를 선택해 주세요.",
                body: "텍스트 변환 정확도가 올라가요.\n언어는 나중에 변경할 수 있어요."
            )
        }
    }

    func next() -> Self {
        switch self {
        case .first:
            return .second
        case .second:
            return .micPermission
        case .micPermission:
            return .finish
        case .finish:
            return .finish
        }
    }

    func prev() -> Self {
        switch self {
        case .first:
            return .first
        case .second:
            return .first
        case .micPermission:
            return .second
        case .finish:
            return .micPermission
        }
    }

    func skip() -> Self {
        if self == .first {
            return .finish
        }
        return self
    }
}
