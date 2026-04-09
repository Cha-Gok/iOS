import Foundation

public struct KeyPoint {
    let id: Int
    let text: String
}

public struct ScriptSection {
    let timestamp: String
    let paragraphs: [String]
}

public final class FileDetailViewModel {
    public var title: String = "오전 취업 관련 강의"
    public var folderName: String = "기본폴더"
    public var metadataText1: String = "2026.03.02 · 오후 14:32 (2026.03.02 수정됨)"
    public var metadataText2: String = "1시간 12분 30초"

    public var keyPoints: [KeyPoint] = [
        KeyPoint(id: 1, text: "실무 역량 중심으로 채용 기준이 이동하는 추세"),
        KeyPoint(id: 2, text: "피그마 링크보다 실제 작업물과 근거가 중요"),
        KeyPoint(id: 3, text: "이해관계자 조율, 문서화 능력을 기업이 중시")
    ]

    public var keywords: [String] = [
        "AI요약", "녹음기능", "줄거리요약", "수업내용", "최대몇글자키워드", "언제인지"
    ]

    public var scriptSections: [ScriptSection] = [
        ScriptSection(
            timestamp: "00:00",
            paragraphs: [
                "채용 시장에서는 학력보다는 실제 역량과 성과를 중심으로 인재를 평가하는 경향이 더 강해지고 있어요.",
                "요즘 UX UI 채용이 이렇게 하기보다는 좀 포트폴리오나 실제 결과물을 훨씬 더 중시하고 있습니다.",
                "그리고 디자이너라면 이런 피그마 링크나 디자인 시스템 실제 작업물들을 갖고 계실 텐데요.",
                "오히려 이런 것들을 더 기업에서는 좀 확인을 하고 싶어 하고 있어요.",
                "그러니까 왜 이 디자인을 했는지 그런 약간 논리적 근거를 좀 더 제시를 하고 그러니까 UX 디자이너로서 이런 그 기업에 있는 이해관계자들이 어떤 의견을 같이 이제 조율한 것들을 좀 문서화하는 능력들을 기업에서는 좀 중요시하게 여기고 있습니다.",
                "그래서 많은 분들이 포트폴리오에 이제 디자인 시스템을 담을 때도 브랜딩 가이드처럼 좀 예쁘게 이렇게 정리를 해 두시는데 실무에서는 사실 그런 것들을 보지는 않고 있는 것 같아요."
            ]
        ),
        ScriptSection(
            timestamp: "03:21",
            paragraphs: [
                "그래서 이렇게 정리한 사람이랑 좀 개발자가 실제로 같이 일을 했을 때 어떤 좀 구조를 이해했는지 그리고 컴포넌트가 어떤 식으로 약간 재사용이 될 수 있는지 이런 것들을 좀 보려고 하기 때문에 이런 것들을 좀 결과를 정리하는 게 좀 중요한 것 같습니다.",
                "결과적으로 디자이너가 협업을 어떻게 했고 논리를 어떻게 정리하고 어떻게 의사결정을 이렇게 기록했는지 보고 싶어 하는 것 같아요.",
                "그리고 가장 중요시하는 거는 이제 두 번째로는 도메인인데요.",
                "기업에서 요새 이제 가장 중요하게 생각하는 거가 이제 도메인 경험인 것 같아요."
            ]
        )
    ]

    public init() {}
}
