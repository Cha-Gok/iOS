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

enum Step: Equatable {
    case first
    case second
    case micPermission
    case download
    case finish

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
                body: "녹음과 음성 변환을 위해\n마이크와 음성 인식 권한이 필요해요.",
                image: "onboarding03"
            )
        case .download:
            OnBoardingItem(
                headline: "기기에서 바로 작동하도록,\n몇 가지를 준비할게요.",
                body: "녹음과 요약을 기기 안에서 처리하기 위해\n필요한 모델을 다운로드해요. Wi-Fi 환경을 권장하며 나중에 설정에서도 다운로드할 수 있어요."
            )
        case .finish:
            OnBoardingItem(
                headline: "기록할 언어를 선택해 주세요.",
                body: "텍스트 변환 정확도가 올라가요.\n언어는 나중에 변경할 수 있어요."
            )
        }
    }
}

extension Step: CaseIterable {
    static var allCases: [Step] {
        [.first, .second, .micPermission, .download, .finish]
    }
}

extension Step {
    var isDownload: Bool {
        if case .download = self { return true }
        return false
    }
}
