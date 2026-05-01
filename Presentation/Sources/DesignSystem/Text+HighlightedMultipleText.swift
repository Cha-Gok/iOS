import Domain
import SwiftUI

extension Text {
    /// 문자열에서 키워드를 통해 강조색을 표현하는 이니셜라이저
    /// - Parameters:
    ///   - fullText: 전체 문장을 넣습니다.
    ///   - keyword: 강조하고 싶은 String 키워드
    init(fullText: String, keyword: String) {
        guard !keyword.isEmpty, fullText.localizedCaseInsensitiveContains(keyword) else {
            self.init(fullText)
            return
        }

        var attributedString = AttributedString(fullText)

        // 검색할 전체 범위
        var searchRange = attributedString.startIndex ..< attributedString.endIndex

        // 범위 내에 키워드가 존재하는 한 계속 반복해서 찾습니다.
        while let range = attributedString[searchRange].range(of: keyword, options: .caseInsensitive) {
            // 스타일 적용
            attributedString[range].foregroundColor = .point900

            // 찾은 부분 다음부터 다시 검색하도록 범위를 업데이트
            searchRange = range.upperBound ..< attributedString.endIndex
        }

        self.init(attributedString)
    }

    init(transcript: Transcript, keyword: String) {
        let targetText = transcript.sections.first { $0.text.localizedCaseInsensitiveContains(keyword) }?.text
            ?? transcript.sections.first?.text
            ?? ""
        self.init(fullText: targetText, keyword: keyword)
    }
}
