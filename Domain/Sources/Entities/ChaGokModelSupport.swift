import Foundation

public struct ChaGokModelSupport: Sendable {
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
        let ram = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
        return ChaGokModelSupport(ramSizeGB: ram)
    }
}

public enum ChaGokModel: Equatable, Sendable {
    case none // OnDevice Model 제공 X
    case gemma4_e2b_4bit
}
