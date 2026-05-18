import Foundation

/// 온디바이스 AI 모델의 지원 여부 확인 및 생명주기(다운로드/로드)를 관리하는 리포지토리 인터페이스.
@MainActor
public protocol AvailableModelSupportRepository: Sendable {
    /// 현재 디바이스의 하드웨어 사양(RAM 등) 및 유저 상태를 기반으로 지원 가능한 모델 정보를 확인합니다.
    /// - Returns: 기기의 RAM 용량, 프로 유저 여부, 할당된 모델 타입을 포함하는 지원 정보 객체
    func checkSupportModel() async -> ChaGokModelSupport

    /// 모델 파일을 다운로드하여 로컬 캐시에 저장합니다. (메모리 적재 X)
    func downloadModel(progressHandler: @Sendable @escaping (Progress)
        -> Void) async throws(AvailableModelSupportRepositoryError)
}
