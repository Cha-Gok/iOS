import CoreData
import Domain

/// 엔티티와 도메인 모델 간의 매핑을 정의하는 프로토콜입니다.
public protocol ManagedObjectMapping: NSManagedObject {
    /// 해당 엔티티와 매핑되는 도메인 모델 타입
    associatedtype DomainType: Sendable, Identifiable, Equatable where DomainType.ID: Sendable

    /// 도메인 모델과 컨텍스트를 받아 엔티티를 초기화합니다.
    init(domain: DomainType, context: NSManagedObjectContext)

    /// 엔티티를 도메인 모델로 변환합니다.
    func toDomain() -> DomainType

    /// 도메인 모델의 데이터를 엔티티에 반영(주입)합니다.
    func insert(from domain: DomainType)

    /// 기존 엔티티의 데이터를 도메인 모델 상태로 업데이트합니다.
    func update(from domain: DomainType)

    /// Core Data 엔티티의 이름
    static var entityName: CoreDataEntityName { get }

    /// 정렬 조건 배열
    static var sortDescriptors: [NSSortDescriptor] { get }

    /// 특정 도메인 모델을 찾기 위한 도메인 기반의 프레디케이트를 생성합니다.
    static func identityPredicate(for domain: DomainType) -> NSPredicate

    /// 특정 도메인 모델을 찾기 위한 식별자 기반의 프레디케이트를 생성합니다.
    static func identityPredicate(byId id: DomainType.ID) -> NSPredicate

    /// 컨텍스트 내에서 특정 도메인 모델에 해당하는 엔티티를 검색합니다.
    static func find(for domain: DomainType, in context: NSManagedObjectContext) throws -> Self?

    /// 컨텍스트 내에서 특정 도메인 모델ID를 통해 해당하는 엔티티를 검색합니다.
    static func find(byId id: DomainType.ID, in context: NSManagedObjectContext) throws -> Self?
}

public extension ManagedObjectMapping {
    /// 기본적으로 update는 insert를 호출하되, 값이 동일할 경우 조기 반환하여 데이터 수정을 최소화합니다.
    func update(from domain: DomainType) {
        if toDomain() == domain { return }
        insert(from: domain)
    }
}
