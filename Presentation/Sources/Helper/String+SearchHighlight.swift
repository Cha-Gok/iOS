import UIKit

extension String {
    /// 문자열 내에서 `query`에 매칭되는 모든 `NSRange`를 반환합니다.
    /// - Parameters:
    ///   - query: 찾을 문자열. 비어 있으면 빈 배열을 반환합니다.
    ///   - options: 비교 옵션 (기본값: 대소문자 무시).
    func ranges(of query: String, options: String.CompareOptions = [.caseInsensitive]) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let nsString = self as NSString
        var ranges: [NSRange] = []
        var searchStart = 0
        let totalLength = nsString.length

        while searchStart < totalLength {
            let remaining = NSRange(location: searchStart, length: totalLength - searchStart)
            let found = nsString.range(of: query, options: options, range: remaining)
            guard found.location != NSNotFound else { break }
            ranges.append(found)
            searchStart = found.location + max(found.length, 1)
        }

        return ranges
    }

    /// `query` 매치를 `highlightColor`로 하이라이트한 `NSAttributedString`을 반환합니다.
    /// `focusedRange`가 지정되면 해당 범위에는 `focusedHighlightColor`를 우선 적용합니다.
    func highlighted(
        query: String,
        baseAttributes: [NSAttributedString.Key: Any],
        highlightColor: UIColor,
        focusedRange: NSRange? = nil,
        focusedHighlightColor: UIColor? = nil
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: self, attributes: baseAttributes)
        guard !query.isEmpty else { return attributed }

        for range in ranges(of: query) {
            attributed.addAttribute(.foregroundColor, value: highlightColor, range: range)
        }

        if let focusedRange, let focusedHighlightColor,
           focusedRange.location != NSNotFound,
           focusedRange.location + focusedRange.length <= (self as NSString).length
        {
            attributed.addAttribute(.foregroundColor, value: focusedHighlightColor, range: focusedRange)
        }

        return attributed
    }
}
