@testable import Data
import Domain
import DomainTesting
import XCTest

final class DefaultVoiceNoteRepositoryTest: XCTestCase {
    private var store: CoreDataLocalDataBase!
    private var sut: DefaultVoiceNoteRepository!

    override func setUpWithError() throws {
        store = try CoreDataLocalDataBase(inMemory: true)
        sut = DefaultVoiceNoteRepository(store: store)
    }

    func test_create_기본폴더가있을때_정상생성() async throws {
        // Given
        let defaultFolder = Folder(name: "기본 폴더", isDeletable: false)
        _ = try await store.create(defaultFolder, as: FolderEntity.self)

        let createdAt = Date()
        let voiceRecord = VoiceRecord(
            createdAt: createdAt,
            audioFilePath: "test.m4a",
            duration: 60
        )

        // When
        let result = try await sut.create(voiceRecord)

        // Then
        XCTAssertEqual(result.folderID, defaultFolder.id)
        XCTAssertEqual(result.title, createdAt.yyyyMMddHHmmssString)
    }

    func test_update_정상수정() async throws {
        // Given
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)
        let note = VoiceNote.stub(folderID: folder.id)
        _ = try await store.create(note, as: VoiceNoteEntity.self)

        let updatedNote = VoiceNote(
            id: note.id,
            title: "수정된 제목",
            createdAt: note.createdAt,
            updatedAt: Date(),
            folderID: folder.id,
            voiceRecord: note.voiceRecord,
            keywords: [],
            transcript: Transcript(text: "전사"),
            summary: Summary(text: "요약")
        )

        // When
        let result = try await sut.update(updatedNote)

        // Then
        XCTAssertEqual(result.title, "수정된 제목")
        XCTAssertEqual(result.transcript?.text, "전사")
    }

    func test_fetchAllFromDefaultFolder_기본폴더메모조회() async throws {
        // Given
        let defaultFolder = Folder(name: "기본 폴더", isDeletable: false)
        _ = try await store.create(defaultFolder, as: FolderEntity.self)
        let note = VoiceNote.stub(folderID: defaultFolder.id)
        _ = try await store.create(note, as: VoiceNoteEntity.self)

        // When
        let result = try await sut.fetchAllFromDefaultFolder()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, note.id)
    }
}
