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
        XCTAssertEqual(result, "방금 전 (오늘 수정됨) · 12분")
    }

    func test_5분전_음성메모일자문구생성시_분전으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 1, 12, 0, 0)
        let updatedAt = makeDate(2026, 4, 13, 15, 25, 0)

        // When
        let result = now.voiceNoteDay(createdAt: createdAt, updatedAt: updatedAt, duration: 150)

        // Then
        XCTAssertEqual(result, "5분 전 (오늘 수정됨) · 2분 30초")
    }

    func test_당일1시간초과_상세날짜문구생성시_오전오후시각으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 3, 15, 15, 23, 0)
        let updatedAt = makeDate(2026, 4, 13, 14, 20, 0)

        // When
        let result = now.voiceNoteDateText(createdAt: createdAt, updatedAt: updatedAt)

        // Then
        XCTAssertEqual(result, "오후 2:20")
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

// MARK: - 휴지통 삭제 시각

extension DateFormattingTests {
    func test_휴지통_삭제3일전_타임라인문구생성시_일전삭제로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 13, 15, 23, 0)
        let deletedAt = makeDate(2026, 4, 10, 10, 0, 0)

        // When
        let result = now.trashVoiceNoteDay(createdAt: createdAt, updatedAt: createdAt, deletedAt: deletedAt)

        // Then
        XCTAssertEqual(result, "오후 3:23 · 3일 전 삭제됨")
    }

    func test_휴지통_삭제2개월전_타임라인문구생성시_개월전삭제로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 13, 15, 23, 0)
        let deletedAt = makeDate(2026, 2, 10, 10, 0, 0)

        // When
        let result = now.trashVoiceNoteDay(createdAt: createdAt, updatedAt: createdAt, deletedAt: deletedAt)

        // Then
        XCTAssertEqual(result, "오후 3:23 · 2026.02.10 삭제됨")
    }

    func test_휴지통_삭제1년초과_타임라인문구생성시_yyyyMMdd삭제로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 13, 15, 23, 0)
        let deletedAt = makeDate(2025, 3, 15, 15, 23, 0)

        // When
        let result = now.trashVoiceNoteDay(createdAt: createdAt, updatedAt: createdAt, deletedAt: deletedAt)

        // Then
        XCTAssertEqual(result, "오후 3:23 · 2025.03.15 삭제됨")
    }
}

// MARK: - 폴더 상대 시각

extension DateFormattingTests {
    func test_폴더_3개항목_1개월전_문구생성시_요청형식으로표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let deletedAt = makeDate(2026, 3, 10, 10, 0, 0)

        // When
        let result = now.trashFolderText(deletedAt: deletedAt, count: 3)

        // Then
        XCTAssertEqual(result, "3개 항목 · 2026.03.10 삭제됨")
    }
}

// MARK: - 검색 결과 시각

extension DateFormattingTests {
    func test_검색결과_폴더날짜생성시_yyyyMMdd형식으로표시된다() {
        // Given
        let date = makeDate(2026, 4, 13, 15, 30, 0)

        // When
        let result = date.searchFolderText()

        // Then
        XCTAssertEqual(result, "2026.04.13")
    }

    func test_검색결과_음성메모생성시_폴더명이포함되어표시된다() {
        // Given
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let createdAt = makeDate(2026, 4, 13, 15, 20, 0)

        // When
        let result = now.searchVoiceNoteDay(
            createdAt: createdAt,
            updatedAt: createdAt,
            duration: 125,
            folderName: "아이디어"
        )

        // Then
        XCTAssertEqual(result, "10분 전 · 2분 5초 · 아이디어")
    }
}

// MARK: - 문자열 변환

extension DateFormattingTests {
    func test_yyyyMMddHHmmssString_호출시_지정된형식으로반환된다() {
        // Given
        let date = makeDate(2026, 4, 13, 15, 30, 45)

        // When
        let result = date.yyyyMMddHHmmssString

        // Then
        XCTAssertEqual(result, "20260413153045")
    }

    func test_toString_호출시_지정된포맷의문자열을반환한다() {
        // Given
        let date = makeDate(2026, 4, 13, 15, 30, 0)

        // When
        let result = date.toString(format: "yyyy-MM-dd HH:mm")

        // Then
        XCTAssertEqual(result, "2026-04-13 15:30")
    }
}

// MARK: - 상대 시간 임계값 테스트

extension DateFormattingTests {
    func test_상대시간_당일_경계값테스트() {
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        XCTAssertEqual(Date.relativeDateText(referenceDate: now.addingTimeInterval(-60), now: now), "오늘")
        XCTAssertEqual(Date.relativeDateText(referenceDate: makeDate(2026, 4, 13, 0, 1, 0), now: now), "오늘")
    }

    func test_상대시간_7일이내_경계값테스트() {
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let yesterday = makeDate(2026, 4, 12, 23, 59, 59)
        let sevenDaysAgo = makeDate(2026, 4, 6, 0, 1, 0)
        
        XCTAssertEqual(Date.relativeDateText(referenceDate: yesterday, now: now), "1일 전")
        XCTAssertEqual(Date.relativeDateText(referenceDate: sevenDaysAgo, now: now), "7일 전")
    }

    func test_상대시간_7일초과_경계값테스트() {
        let now = makeDate(2026, 4, 13, 15, 30, 0)
        let eightDaysAgo = makeDate(2026, 4, 5, 23, 59, 59)
        
        XCTAssertEqual(Date.relativeDateText(referenceDate: eightDaysAgo, now: now), "2026.04.05")
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
