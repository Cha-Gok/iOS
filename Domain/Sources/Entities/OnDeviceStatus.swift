import Foundation

/// on-device 리소스의 현재 상태를 표현하는 도메인 순수 객체.
///
/// 저장 상태(`storage`)와 메모리 적재 상태(`runtime`)를 분리해서 표현합니다.
public struct OnDeviceStatus: Hashable, Sendable {
    /// 디스크 또는 캐시 상의 저장 상태입니다.
    public var storage: StorageState
    /// 메모리 상에서 모델이 준비된 상태입니다.
    public var runtime: RuntimeState

    public init(
        storage: StorageState = .notDownloaded,
        runtime: RuntimeState = .unloaded
    ) {
        self.storage = storage
        self.runtime = runtime
    }

    /// 다운로드 및 삭제처럼, 모델 파일의 보관 상태를 나타냅니다.
    public enum StorageState: Sendable, Hashable {
        /// 아직 내려받지 않은 상태입니다.
        case notDownloaded
        /// 다운로드가 진행 중인 상태입니다.
        case downloading(progress: Double)
        /// 로컬에 파일이 준비된 상태입니다.
        case downloaded
        /// 삭제가 진행 중인 상태입니다.
        case deleting
        /// 저장 단계에서 실패한 상태입니다.
        case failed
    }

    /// 로드처럼, 메모리 적재 여부를 나타냅니다.
    public enum RuntimeState: Sendable, Hashable {
        /// 메모리에 올려지지 않은 상태입니다.
        case unloaded
        /// 메모리 로드가 진행 중인 상태입니다.
        case loading
        /// 메모리에 적재된 상태입니다.
        case loaded
        /// 런타임 적재 단계에서 실패한 상태입니다.
        case failed
    }
}
