import Foundation

/// 현재 사용자에게 지원되는 LLM 모델 추천 객채
public struct ChaGokModelSupport: Hashable, Sendable {
    let ramSizeGB: Int
    var isProUser: Bool

    /// RAM 사양에 따라 결정되는 모델
    public var model: ChaGokModel {
        if ramSizeGB >= 6 {
            return .gemma4_e2b_4bit
        } else {
            return .none
        }
    }

    public init(ramSizeGB: Int, isProUser: Bool = false) {
        self.ramSizeGB = ramSizeGB
        self.isProUser = isProUser
    }

    /// 현재 기기 정보를 바로 가져오는 속성 (에러 수정됨)
    public static var current: ChaGokModelSupport {
        let ramBytes = ProcessInfo.processInfo.physicalMemory
        let ramGB = Double(ramBytes) / (1024.0 * 1024.0 * 1024.0)
        let ram = Int(ramGB.rounded())
        return ChaGokModelSupport(ramSizeGB: ram)
    }
}

/// 차곡에서 사용하는 OnDevice-AI LLM 모델입니다.
public enum ChaGokModel: Equatable, Sendable, CaseIterable {
    case none // OnDevice Model 제공 X
    case whisper
    case gemma4_e2b_4bit

    /// none을 제외한 모델을 List 화 합니다.
    public static var models: [ChaGokModel] {
        Array(allCases.filter { $0 != .none })
    }
}

/// 차곡 - 설정에서 사용자가 현재 모델의 상태를 나타냅니다.
public struct ChaGokModelState: Hashable, Sendable {
    public let title: String
    public let subTitle: String
    public let model: ChaGokModel
    public var status: OnDeviceStatus

    public init(
        title: String,
        subTitle: String,
        model: ChaGokModel,
        status: OnDeviceStatus = .init(storage: .notDownloaded)
    ) {
        self.title = title
        self.subTitle = subTitle
        self.model = model
        self.status = status
    }
}
