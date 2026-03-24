/// Core Data 모델(.xcdatamodeld)에 정의된 엔티티 이름을 타입 안전하게 관리하는 열거형입니다.
/// rawValue가 `.xcdatamodel`의 `entity name` 속성과 정확히 일치해야 합니다.
public enum CoreDataEntityName: String, CaseIterable, Sendable {
    case folder = "Folder"
    case voiceNote = "VoiceNote"
    case keyword = "Keyword"
    case summary = "Summary"
    case transcript = "Transcript"
    case voiceRecord = "VoiceRecord"
}
