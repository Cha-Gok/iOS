@testable import Core
import Foundation
import XCTest

final class DateFormattingTests: XCTestCase {
    private var originalTimeZone: TimeZone!
    private let seoulTimeZone = TimeZone(identifier: "Asia/Seoul")!

    override func setUp() {
        super.setUp()
        originalTimeZone = NSTimeZone.default
        NSTimeZone.default = seoulTimeZone
    }

    override func tearDown() {
        NSTimeZone.default = originalTimeZone
        super.tearDown()
    }
}

// MARK: - 상대 시간

extension DateFormattingTests {
    func test_30초전_음성메모일자문구생성시_방금전으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 1, 12, 0, 0)
        let updatedAt = makeDate(2026, 4, 13, 15, 29, 30)

        // When
        let result = now.voiceNoteDay(createdAt: createdAt, updatedAt: updatedAt, duration: 720)

        // Then
        XCTAssertEqual(result, "방금 전 · 12분")
    }

    func test_5분전_음성메모일자문구생성시_분전으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 1, 12, 0, 0)
        let updatedAt = makeDate(2026, 4, 13, 15, 25, 0)

        // When
        let result = now.voiceNoteDay(createdAt: createdAt, updatedAt: updatedAt, duration: 150)

        // Then
        XCTAssertEqual(result, "5분 전 · 2분")
    }

    func test_1시간전_상세날짜문구생성시_수정일기준시간전으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 3, 15, 15, 23, 0)
        let updatedAt = makeDate(2026, 4, 13, 14, 20, 0)

        // When
        let result = now.voiceNoteDateText(createdAt: createdAt, updatedAt: updatedAt)

        // Then
        XCTAssertEqual(result, "1시간 전")
    }
}

// MARK: - 절대 날짜

extension DateFormattingTests {
    func test_1년이내_음성메모일자문구생성시_월일오전오후형식으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 3, 15, 15, 23, 0)

        // When
        let result = now.voiceNoteDay(createdAt: createdAt, updatedAt: createdAt, duration: 720)

        // Then
        XCTAssertEqual(result, "3월 15일 오후 3:23 · 12분")
    }

    func test_1년초과_음성메모일자문구생성시_연도포함형식으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2025, 3, 15, 15, 23, 0)

        // When
        let result = now.voiceNoteDay(createdAt: createdAt, updatedAt: createdAt, duration: 720)

        // Then
        XCTAssertEqual(result, "2025.03.15 · 12분")
    }
}

// MARK: - Helpers

private extension DateFormattingTests {
    func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        _ second: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = seoulTimeZone

        let components = DateComponents(
            calendar: calendar,
            timeZone: seoulTimeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        return try! XCTUnwrap(calendar.date(from: components))
    }
}
