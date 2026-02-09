import Foundation
import XCTest
@testable import Domain

final class FileFormatTests: XCTestCase {

    // MARK: - R: Right - 각 case 존재 및 기대값

    func test_FileFormat_mp3_case가존재한다() {
        let format: FileFormat = .mp3
        if case .mp3 = format { return }
        XCTFail("FileFormat.mp3 should match")
    }

    func test_FileFormat_wav_case가존재한다() {
        let format: FileFormat = .wav
        if case .wav = format { return }
        XCTFail("FileFormat.wav should match")
    }

    func test_FileFormat_aac_case가존재한다() {
        let format: FileFormat = .aac
        if case .aac = format { return }
        XCTFail("FileFormat.aac should match")
    }

    func test_FileFormat_m4a_case가존재한다() {
        let format: FileFormat = .m4a
        if case .m4a = format { return }
        XCTFail("FileFormat.m4a should match")
    }

    func test_FileFormat_other_연관값이저장된다() {
        let format: FileFormat = .other("custom")
        if case let .other(value) = format {
            XCTAssertEqual(value, "custom")
        } else {
            XCTFail("FileFormat.other should match with associated value")
        }
    }

    // MARK: - B: Boundary - other 경계

    func test_FileFormat_other_빈문자열도허용된다() {
        let format: FileFormat = .other("")
        if case let .other(value) = format {
            XCTAssertEqual(value, "")
        } else {
            XCTFail("FileFormat.other(\"\") should match")
        }
    }

    func test_FileFormat_other_긴문자열도저장된다() {
        let long = String(repeating: "x", count: 1000)
        let format: FileFormat = .other(long)
        if case let .other(value) = format {
            XCTAssertEqual(value, long)
        } else {
            XCTFail("FileFormat.other(long) should match")
        }
    }
}
