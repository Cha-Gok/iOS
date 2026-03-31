import CoreData

/// 엔티티와 도메인 모델 간의 매핑을 정의하는 프로토콜입니다.
public protocol ManagedObjectMapping: NSManagedObject {
    /// 해당 엔티티와 매핑되는 모델 타입
    associatedtype ModelType: Sendable, Identifiable, Equatable where ModelType.ID: Sendable

    /// 모델과 컨텍스트를 받아 엔티티를 초기화합니다.
    init(model: ModelType, context: NSManagedObjectContext) throws

    /// 엔티티를 모델로 변환합니다.
    func toModel() -> ModelType

    /// 모델의 데이터를 엔티티에 반영(주입)합니다.
    func insert(from model: ModelType) throws

    /// 기존 엔티티의 데이터를 모델 상태로 업데이트합니다.
    func update(from model: ModelType) throws

    /// Core Data 엔티티의 이름
    static var entityName: CoreDataEntityName { get }

    /// 정렬 조건 배열
    static var sortDescriptors: [NSSortDescriptor] { get }

    /// 특정 모델을 찾기 위한 모델 기반의 프레디케이트를 생성합니다.
    static func identityPredicate(for model: ModelType) -> NSPredicate

    /// 특정 모델을 찾기 위한 식별자 기반의 프레디케이트를 생성합니다.
    static func identityPredicate(byId id: ModelType.ID) -> NSPredicate

    /// 컨텍스트 내에서 특정 모델에 해당하는 엔티티를 검색합니다.
    static func find(for model: ModelType, in context: NSManagedObjectContext) throws -> Self?

    /// 컨텍스트 내에서 특정 모델ID를 통해 해당하는 엔티티를 검색합니다.
    static func find(byId id: ModelType.ID, in context: NSManagedObjectContext) throws -> Self?
}

public extension ManagedObjectMapping {
    /// 기본적으로 update는 insert를 호출하되, 값이 동일할 경우 조기 반환하여 데이터 수정을 최소화합니다.
    func update(from model: ModelType) throws {
        if toModel() == model { return }
        try insert(from: model)
    }

    /// 모델 기반 기본 Predicate 생성
    static func identityPredicate(for model: ModelType) -> NSPredicate {
        identityPredicate(byId: model.id)
    }

    /// 단일 엔티티 검색 (by model)
    static func find(for model: ModelType, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(for: model)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 단일 엔티티 검색 (by id)
    static func find(byId id: ModelType.ID, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(byId: id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

public extension ManagedObjectMapping where ModelType.ID == UUID {
    /// UUID 식별자를 가지는 모델을 위한 Predicate 기본값
    static func identityPredicate(byId id: ModelType.ID) -> NSPredicate {
        NSPredicate(format: "id == %@", id as CVarArg)
    }
}
