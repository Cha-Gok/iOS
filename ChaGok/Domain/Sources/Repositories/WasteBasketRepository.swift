import Foundation

/// 휴지통 관련 작업을 담당하는 리포지토리 프로토콜.
/// 휴지통 비우기(영구 삭제) 및 항목 이동(Soft Delete) 기능을 제공합니다.
public protocol WasteBasketRepository: Sendable {

    /// 휴지통의 모든 항목을 영구적으로 삭제합니다.
    /// - Returns: 삭제 성공 여부
    /// - Throws: 삭제 중 오류 발생 시
    func allClear() async throws -> Bool

    /// 특정 항목을 휴지통에서 영구적으로 삭제합니다.
    /// - Parameter item: 삭제할 휴지통 항목 (폴더 또는 VoiceNote)
    /// - Returns: 삭제 성공 여부
    /// - Throws: 삭제 중 오류 발생 시
    func delete(item: WasteBasketItem) async throws -> Bool

    /// 다수의 항목을 휴지통에서 영구적으로 삭제합니다.
    /// - Parameter items: 삭제할 휴지통 항목 리스트
    /// - Returns: 삭제 성공 여부
    /// - Throws: 삭제 중 오류 발생 시
    func deleteAll(items: [WasteBasketItem]) async throws -> Bool

    /// 특정 항목을 휴지통으로 이동시킵니다. (Soft Delete)
    /// - Parameter item: 이동시킬 항목 (폴더 또는 VoiceNote)
    /// - Returns: 이동 성공 여부
    /// - Throws: 이동 중 오류 발생 시
    func moveToWasteBasket(item: WasteBasketItem) async throws -> Bool

    /// 다수의 항목을 휴지통으로 이동시킵니다. (Soft Delete)
    /// - Parameter items: 이동시킬 항목 리스트
    /// - Returns: 이동 성공 여부
    /// - Throws: 이동 중 오류 발생 시
    func moveAllToWasteBasket(items: [WasteBasketItem]) async throws -> Bool
}
