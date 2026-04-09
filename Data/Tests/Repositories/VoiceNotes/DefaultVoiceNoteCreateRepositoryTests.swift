@testable import Data
import Domain
import XCTest

final class DefaultVoiceNoteCreateRepositoryTests: XCTestCase {
    func test_기본폴더가있을때_생성된보이스노트제목은녹음일시기반이다() async throws {
        let store = try CoreDataLocalDataBase(inMemory: true)
        let defaultFolder = Folder(name: "기본 폴더", isDeletable: false)
        _ = try await store.create(defaultFolder, as: FolderEntity.self)

        let createdAt = Date(timeIntervalSince1970: 1_710_000_000)
        let voiceRecord = VoiceRecord(
            createdAt: createdAt,
            audioFilePath: URL(fileURLWithPath: "/tmp/1710000000000.m4a"),
            duration: 60
        )
        let sut = DefaultVoiceNoteCreateRepository(store: store)

        let voiceNote = try await sut.create(voiceRecord)

        XCTAssertEqual(voiceNote.folderID, defaultFolder.id)
        XCTAssertEqual(voiceNote.title, createdAt.yyyyMMddHHmmssString)
        XCTAssertEqual(voiceNote.voiceRecord, voiceRecord)
    }
}
