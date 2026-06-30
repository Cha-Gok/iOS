import Domain
import XCTest

final class RecordingActivityWidgetTests: XCTestCase {
    func test_라이브오디오미터는_설정된_높이_범위_내에서_높이를_반환한다() {
        let heights = (0 ..< 7).map {
            LiveAudioMeter.makeHeight(
                for: $0,
                barCount: 7,
                level: 0.8,
                maxHeight: 24,
                minHeight: 4
            )
        }

        XCTAssertEqual(heights.count, 7)
        XCTAssertTrue(heights.allSatisfy { $0 >= 4 && $0 <= 24 })
        XCTAssertTrue(heights.contains { $0 > 4 })
    }
}
