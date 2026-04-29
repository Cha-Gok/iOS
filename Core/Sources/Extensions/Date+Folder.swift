import Foundation

public extension Date {
    func trashFolderText(deletedAt: Date?, count: Int) -> String {
        var deletedText: String
        guard let deletedAt else {
            return ""
        }
        deletedText = Self.relativeDateText(referenceDate: deletedAt, now: self)

        if count == 0 {
            return "항목 없음 · \(deletedText) 삭제"
        } else {
            return "\(count)개 항목 · \(deletedText) 삭제"
        }
    }

    func searchFolderText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
}
