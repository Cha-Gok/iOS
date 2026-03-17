import Foundation

/// 권한의 현재 상태를 나타내는 열거형
public enum PermissionStatus: Sendable {
    /// 아직 확인되지 않은 상태 (처음 요청 전)
    case notDetermined
    /// 허용된 상태
    case authorized
    /// 거부된 상태
    case denied
}
