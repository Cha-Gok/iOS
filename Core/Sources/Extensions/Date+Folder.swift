import Foundation

public extension Date {
    func trashFolderText(deletedAt: Date?, count: Int) -> String {
        var deletedText: String
        guard let deletedAt else {
            return ""
        }
        deletedText = Self.relativeDateText(referenceDate: deletedAt, now: self)
        return "\(count)개 항목 · \(deletedText) 삭제됨"
    }

    func searchFolderText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
}
