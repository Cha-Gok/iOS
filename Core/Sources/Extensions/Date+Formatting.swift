import Foundation

public extension Date {
    var yyyyMMddHHmmssString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: self)
    }
}
