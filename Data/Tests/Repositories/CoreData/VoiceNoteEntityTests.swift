@testable import Data
import CoreData
import Domain
import XCTest

// MARK: - VoiceNoteEntity CRUD & Relationship & Mapping 테스트

final class VoiceNoteEntityTests: XCTestCase {
    // MARK: - Helpers

    /// 단일 CoreDataStore로 모든 엔티티를 처리합니다.
    private func makeStore() async throws -> CoreDataStore {
        try await CoreDataStore(inMemory: true)
    }

    private func makeVoiceRecord(
        audioFilePath: URL = URL(fileURLWithPath: "/tmp/test.m4a"),
        duration: Double = 60.0
    ) -> VoiceRecord {
        VoiceRecord(audioFilePath: audioFilePath, duration: duration)
    }

    private func makeVoiceNote(
        title: String = "Test Note",
        folderID: UUID = UUID(),
        voiceRecord: VoiceRecord? = nil,
        keywords: [Keyword] = [],
        transcript: Transcript? = nil,
        summary: Summary? = nil,
        deletedAt: Date? = nil
    ) -> VoiceNote {
        let record = voiceRecord ?? makeVoiceRecord()
        return VoiceNote(
            title: title,
            folderID: folderID,
            voiceRecord: record,
            keywords: keywords,
            transcript: transcript,
            summary: summary,
            deletedAt: deletedAt
        )
    }

    // MARK: - Create → Fetch(byId) 전체 속성 + 중첩 관계 복원

    func test_VoiceNote생성후_조회시_모든속성과관계가복원된다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "테스트 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceRecord = makeVoiceRecord(duration: 120.5)
        let keywords = [
            Keyword(noteId: UUID(), word: "Swift"),
            Keyword(noteId: UUID(), word: "CoreData")
        ]
        let transcript = Transcript(text: "안녕하세요, 테스트입니다.")
        let summary = Summary(text: "테스트 요약")

        let voiceNote = makeVoiceNote(
            title: "전체 속성 검증",
            folderID: folder.id,
            voiceRecord: voiceRecord,
            keywords: keywords,
            transcript: transcript,
            summary: summary
        )

        // When
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)

        // Then — 기본 속성 검증
        XCTAssertEqual(fetched.id, voiceNote.id)
        XCTAssertEqual(fetched.title, "전체 속성 검증")
        XCTAssertEqual(fetched.folderID, folder.id)
        XCTAssertEqual(
            fetched.createdAt.timeIntervalSinceReferenceDate,
            voiceNote.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1
        )

        // Then — 중첩 관계: VoiceRecord
        XCTAssertEqual(fetched.voiceRecord.id, voiceRecord.id)
        XCTAssertEqual(fetched.voiceRecord.duration, 120.5)
        XCTAssertEqual(fetched.voiceRecord.audioFilePath, voiceRecord.audioFilePath)

        // Then — 중첩 관계: Keywords
        XCTAssertEqual(fetched.keywords.count, 2)
        let fetchedWords = Set(fetched.keywords.map(\.word))
        XCTAssertTrue(fetchedWords.contains("Swift"))
        XCTAssertTrue(fetchedWords.contains("CoreData"))

        // Then — 중첩 관계: Transcript & Summary
        XCTAssertEqual(fetched.transcript?.text, "안녕하세요, 테스트입니다.")
        XCTAssertEqual(fetched.summary?.text, "테스트 요약")
    }

    // MARK: - Update: 제목 변경 반영

    func test_VoiceNote수정후_다시조회시_제목변경이반영된다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(title: "Original Title", folderID: folder.id)
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: "Updated Title",
            createdAt: voiceNote.createdAt,
            updatedAt: Date(),
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: voiceNote.transcript,
            summary: voiceNote.summary,
            deletedAt: voiceNote.deletedAt
        )
        _ = try await store.update(updatedNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertEqual(fetched.title, "Updated Title")
    }

    // MARK: - Update: Transcript 추가 후 반영

    func test_Transcript가없는상태에서_Transcript추가시_정상적으로반영된다() async throws {
        // Given — Transcript 없이 생성
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(
            title: "전사본 추가",
            folderID: folder.id,
            transcript: nil
        )
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When — Transcript를 추가하여 update
        let transcript = Transcript(text: "전사 완료된 텍스트")
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: Date(),
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: transcript,
            summary: voiceNote.summary,
            deletedAt: voiceNote.deletedAt
        )
        _ = try await store.update(updatedNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertNotNil(fetched.transcript)
        XCTAssertEqual(fetched.transcript?.text, "전사 완료된 텍스트")
    }

    // MARK: - Update: Transcript 생성 후 Summary + Keywords 추가

    func test_전사본만있는상태에서_요약과키워드추가시_모두정상반영된다() async throws {
        // Given — Transcript만 있는 상태로 생성
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let transcript = Transcript(text: "전사된 텍스트")
        let voiceNote = makeVoiceNote(
            title: "비즈니스 시나리오",
            folderID: folder.id,
            transcript: transcript
        )
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When — Summary와 Keywords를 추가하여 update
        let summary = Summary(text: "요약 텍스트")
        let keywords = [
            Keyword(noteId: voiceNote.id, word: "AI"),
            Keyword(noteId: voiceNote.id, word: "전사")
        ]
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: Date(),
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: keywords,
            transcript: transcript,
            summary: summary,
            deletedAt: voiceNote.deletedAt
        )
        _ = try await store.update(updatedNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertEqual(fetched.transcript?.text, "전사된 텍스트")
        XCTAssertEqual(fetched.summary?.text, "요약 텍스트")
        XCTAssertEqual(fetched.keywords.count, 2)
        let words = Set(fetched.keywords.map(\.word))
        XCTAssertTrue(words.contains("AI"))
        XCTAssertTrue(words.contains("전사"))
    }

    // MARK: - Update: Keywords Diff (추가/삭제)

    func test_키워드목록이변경될때_업데이트시_삭제와추가가모두반영된다() async throws {
        // Given — 키워드 A, B로 생성
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(
            title: "키워드 Diff",
            folderID: folder.id,
            keywords: [
                Keyword(noteId: UUID(), word: "A"),
                Keyword(noteId: UUID(), word: "B")
            ]
        )
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When — 키워드 B를 삭제하고 C를 추가 (A, C)
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: Date(),
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: [
                Keyword(noteId: voiceNote.id, word: "A"),
                Keyword(noteId: voiceNote.id, word: "C")
            ],
            transcript: voiceNote.transcript,
            summary: voiceNote.summary,
            deletedAt: voiceNote.deletedAt
        )
        _ = try await store.update(updatedNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertEqual(fetched.keywords.count, 2)
        let words = Set(fetched.keywords.map(\.word))
        XCTAssertTrue(words.contains("A"), "기존 키워드 A는 유지되어야 합니다.")
        XCTAssertFalse(words.contains("B"), "삭제된 키워드 B는 없어야 합니다.")
        XCTAssertTrue(words.contains("C"), "새로 추가된 키워드 C가 있어야 합니다.")
    }

    // MARK: - 동일 데이터 update 시 변경 없음 (Equatable 최적화)

    func test_동일데이터로_업데이트시_변경없이정상동작한다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(title: "변경 없음", folderID: folder.id)
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)
        let original = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)

        // When — 동일한 데이터로 update (toDomain() == domain이므로 조기 반환)
        _ = try await store.update(original, as: VoiceNoteEntity.self)

        // Then — 여전히 동일
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertEqual(fetched.title, "변경 없음")
    }

    // MARK: - 필수 Relationship 포함 저장 (Folder가 반드시 존재)

    func test_폴더존재상태에서_VoiceNote생성시_정상저장된다() async throws {
        // Given — 폴더를 먼저 생성한 뒤 VoiceNote 저장
        let store = try await makeStore()
        let folder = Folder(name: "필수 관계 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(
            title: "Relationship 포함",
            folderID: folder.id,
            voiceRecord: makeVoiceRecord(duration: 30.0)
        )

        // When
        let saved = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: saved.id, as: VoiceNoteEntity.self)
        XCTAssertEqual(fetched.id, voiceNote.id)
        XCTAssertEqual(fetched.title, "Relationship 포함")
        XCTAssertEqual(fetched.folderID, folder.id)
    }

    // MARK: - 정렬 검증 (updatedAt 내림차순)

    func test_여러노트가존재할때_전체조회시_수정일내림차순으로정렬된다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "정렬 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let now = Date()
        let noteOldest = VoiceNote(
            title: "Oldest",
            createdAt: now.addingTimeInterval(-200),
            updatedAt: now.addingTimeInterval(-200),
            folderID: folder.id,
            voiceRecord: makeVoiceRecord()
        )
        let noteMiddle = VoiceNote(
            title: "Middle",
            createdAt: now.addingTimeInterval(-100),
            updatedAt: now.addingTimeInterval(-100),
            folderID: folder.id,
            voiceRecord: makeVoiceRecord()
        )
        let noteNewest = VoiceNote(
            title: "Newest",
            createdAt: now,
            updatedAt: now,
            folderID: folder.id,
            voiceRecord: makeVoiceRecord()
        )

        // 의도적으로 순서를 뒤섞어 생성
        _ = try await store.create(noteNewest, as: VoiceNoteEntity.self)
        _ = try await store.create(noteOldest, as: VoiceNoteEntity.self)
        _ = try await store.create(noteMiddle, as: VoiceNoteEntity.self)

        // When
        let allNotes = try await store.fetchAll(VoiceNoteEntity.self)

        // Then — updatedAt descending
        XCTAssertEqual(allNotes.count, 3)
        XCTAssertEqual(allNotes[0].id, noteNewest.id, "첫 번째는 가장 최근 업데이트된 노트여야 합니다.")
        XCTAssertEqual(allNotes[1].id, noteMiddle.id, "두 번째는 중간 업데이트된 노트여야 합니다.")
        XCTAssertEqual(allNotes[2].id, noteOldest.id, "세 번째는 가장 오래전 업데이트된 노트여야 합니다.")
    }

    // MARK: - toDomain() 동일성 검증

    func test_DB에저장후_조회시_원본도메인객체와동일하다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "동일성 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(
            title: "도메인 동일성",
            folderID: folder.id,
            deletedAt: Date(timeIntervalSince1970: 500_000)
        )

        // When
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)
        let restored = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)

        // Then
        XCTAssertEqual(restored.id, voiceNote.id)
        XCTAssertEqual(restored.title, voiceNote.title)
        XCTAssertEqual(
            restored.createdAt.timeIntervalSinceReferenceDate,
            voiceNote.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1
        )
        XCTAssertEqual(
            restored.updatedAt.timeIntervalSinceReferenceDate,
            voiceNote.updatedAt.timeIntervalSinceReferenceDate,
            accuracy: 1
        )
        XCTAssertEqual(restored.deletedAt, voiceNote.deletedAt)
    }

    // MARK: - Delete 후 조회 실패

    func test_VoiceNote삭제후_다시조회시_fetchFailed에러를던진다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "삭제 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(title: "삭제 대상", folderID: folder.id)
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When
        _ = try await store.delete(byId: voiceNote.id, as: VoiceNoteEntity.self)

        // Then
        do {
            _ = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
            XCTFail("삭제 후 조회 시 에러가 발생해야 합니다.")
        } catch let error as CoreDataStorageError {
            guard case .fetchFailed = error else {
                return XCTFail("예상한 에러는 .fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    // MARK: - Transcript / Summary nil일 때 복원 검증

    func test_선택적관계가nil인노트를_생성후조회시_nil로정상복원된다() async throws {
        // Given
        let store = try await makeStore()
        let folder = Folder(name: "Optional 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let voiceNote = makeVoiceNote(
            title: "Optional 없음",
            folderID: folder.id,
            transcript: nil,
            summary: nil
        )

        // When
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)

        // Then
        XCTAssertNil(fetched.transcript)
        XCTAssertNil(fetched.summary)
    }

    // MARK: - Transcript 삭제 후 nil 반영

    func test_Transcript가있는노트에서_이를nil로변경후업데이트시_삭제가정상반영된다() async throws {
        // Given — Transcript가 있는 상태로 생성
        let store = try await makeStore()
        let folder = Folder(name: "폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        let transcript = Transcript(text: "삭제될 전사본")
        let voiceNote = makeVoiceNote(
            title: "전사본 삭제",
            folderID: folder.id,
            transcript: transcript
        )
        _ = try await store.create(voiceNote, as: VoiceNoteEntity.self)

        // When — Transcript를 nil로 설정하여 update
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: Date(),
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: nil,
            summary: voiceNote.summary,
            deletedAt: voiceNote.deletedAt
        )
        _ = try await store.update(updatedNote, as: VoiceNoteEntity.self)

        // Then
        let fetched = try await store.fetch(byId: voiceNote.id, as: VoiceNoteEntity.self)
        XCTAssertNil(fetched.transcript, "Transcript가 nil로 정상 삭제되어야 합니다.")
    }
}
