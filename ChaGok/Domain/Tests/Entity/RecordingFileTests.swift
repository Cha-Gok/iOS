import Foundation
import XCTest
@testable import Domain

final class RecordingFileTests: XCTestCase {

    // MARK: - R: Right - init 후 프로퍼티 일치

    func test_RecordingFile_init_전달한값이프로퍼티와일치한다() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/tmp/recording.m4a")
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let duration: TimeInterval = 120.5
        let format: FileFormat = .m4a
        let fileSize: Int64 = 1024
        let fileName = "recording.m4a"
        let title = "제목"
        let description = "설명"
        let tags = ["회의", "녹음"]

        let sut = RecordingFile(
            id: id,
            fileURL: url,
            createdAt: createdAt,
            updatedAt: updatedAt,
            duration: duration,
            fileFormat: format,
            fileSize: fileSize,
            fileName: fileName,
            title: title,
            description: description,
            tags: tags
        )

        XCTAssertEqual(sut.id, id)
        XCTAssertEqual(sut.fileURL, url)
        XCTAssertEqual(sut.createdAt, createdAt)
        XCTAssertEqual(sut.updatedAt, updatedAt)
        XCTAssertEqual(sut.duration, duration)
        if case .m4a = sut.fileFormat { } else { XCTFail("fileFormat should be m4a") }
        XCTAssertEqual(sut.fileSize, fileSize)
        XCTAssertEqual(sut.fileName, fileName)
        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(sut.description, description)
        XCTAssertEqual(sut.tags, tags)
    }

    // MARK: - B: Boundary - 빈 값, 0 값

    func test_RecordingFile_Boundary_빈tags가능() {
        let sut = RecordingFile(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/tmp/a.m4a"),
            createdAt: Date(),
            updatedAt: Date(),
            duration: 0,
            fileFormat: .m4a,
            fileSize: 0,
            fileName: "a.m4a",
            title: "",
            description: "",
            tags: []
        )
        XCTAssertTrue(sut.tags.isEmpty)
        XCTAssertEqual(sut.duration, 0)
        XCTAssertEqual(sut.fileSize, 0)
        XCTAssertEqual(sut.title, "")
        XCTAssertEqual(sut.description, "")
    }

    func test_RecordingFile_Boundary_createdAt와updatedAt가같아도생성된다() {
        let date = Date()
        let sut = RecordingFile(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/tmp/a.m4a"),
            createdAt: date,
            updatedAt: date,
            duration: 0,
            fileFormat: .mp3,
            fileSize: 0,
            fileName: "a.mp3",
            title: "t",
            description: "d",
            tags: []
        )
        XCTAssertEqual(sut.createdAt, sut.updatedAt)
    }
}
