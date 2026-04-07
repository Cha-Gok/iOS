@testable import Data
import CoreData
import Domain
import XCTest

// MARK: - FolderEntity CRUD & Mapping 테스트

final class FolderEntityTests: XCTestCase {
    // MARK: - Helpers

    private func makeStore() async throws -> CoreDataLocalDataBase {
        try CoreDataLocalDataBase(inMemory: true)
    }

    private func makeFolder(
        name: String = "Test Folder",
        isDeletable: Bool = true,
        deletedAt: Date? = nil
    ) -> Folder {
        Folder(name: name, isDeletable: isDeletable, deletedAt: deletedAt)
    }

    private func makeVoiceRecord() -> VoiceRecord {
        VoiceRecord(audioFilePath: URL(fileURLWithPath: "/tmp/test.m4a"), duration: 60.0)
    }

    // MARK: - Create → Fetch(byId) 속성 유지

    func test_폴더를생성후_ID로조회시_모든속성이유지된다() async throws {
        // Given
        let store = try await makeStore()
        let deletedDate = Date.now
        let folder = Folder(name: "속성 유지 폴더", deletedAt: deletedDate)

        // When
        _ = try await store.create(folder, as: FolderEntity.self)
        let fetched = try await store.fetch(byID: folder.id, as: FolderEntity.self)

        // Then
        XCTAssertEqual(fetched.id, folder.id)
        XCTAssertEqual(fetched.name, "속성 유지 폴더")
        XCTAssertEqual(
            fetched.createdAt.timeIntervalSinceReferenceDate,
            folder.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1
        )
        XCTAssertEqual(fetched.isDeletable, true)
        XCTAssertEqual(fetched.deletedAt, deletedDate)
    }

    // MARK: - FetchAll 복수 엔티티 반환

    func test_여러폴더존재시_전체조회시_모든폴더가반환된다() async throws {
        // Given
        let store = try await makeStore()
        let folders = (1 ... 5).map { makeFolder(name: "Folder \($0)") }

        for folder in folders {
            _ = try await store.create(folder, as: FolderEntity.self)
        }

        // When
        let allFolders = try await store.fetchAll(FolderEntity.self)

        // Then
        XCTAssertEqual(allFolders.count, 5)
        for folder in folders {
            XCTAssertTrue(
                allFolders.contains(where: { $0.id == folder.id }),
                "\(folder.name)이 fetchAll 결과에 포함되어야 합니다."
            )
        }
    }

    // MARK: - Update 후 수정값 반영

    func test_폴더수정후_다시조회시_수정값이반영된다() async throws {
        // Given
        let store = try await makeStore()
        let folder = makeFolder(name: "Original")
        _ = try await store.create(folder, as: FolderEntity.self)

        // When
        let updatedFolder = Folder(
            id: folder.id,
            name: "Updated",
            createdAt: folder.createdAt,
            isDeletable: false,
            deletedAt: Date.now
        )
        _ = try await store.update(updatedFolder, as: FolderEntity.self)

        // Then
        let fetched = try await store.fetch(byID: folder.id, as: FolderEntity.self)
        XCTAssertEqual(fetched.name, "Updated")
        XCTAssertEqual(fetched.isDeletable, false)
        XCTAssertNotNil(fetched.deletedAt)
    }

    // MARK: - Folder 이름만 변경 시 content 재조회 없이 동작 (성능 검증)

    func test_이름만변경후_업데이트시_정상반영된다() async throws {
        // Given — Folder.update(from:)는 스칼라 속성만 비교하므로 voiceNotes를 로드하지 않음
        let store = try await makeStore()
        let folder = makeFolder(name: "Before")
        _ = try await store.create(folder, as: FolderEntity.self)

        // When — 이름만 변경
        let renamed = Folder(
            id: folder.id,
            name: "After",
            createdAt: folder.createdAt,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )
        _ = try await store.update(renamed, as: FolderEntity.self)

        // Then — 이름만 정상 변경 확인
        let fetched = try await store.fetch(byID: folder.id, as: FolderEntity.self)
        XCTAssertEqual(fetched.name, "After")
        XCTAssertEqual(fetched.isDeletable, folder.isDeletable)
    }

    // MARK: - 동일 데이터 update 시 변경 없음 검증

    func test_동일데이터로_업데이트시_변경없이정상동작한다() async throws {
        // Given
        let store = try await makeStore()
        let folder = makeFolder(name: "Same")
        _ = try await store.create(folder, as: FolderEntity.self)

        // When — 동일한 값으로 update (내부적으로 조기 반환)
        let sameFolder = Folder(
            id: folder.id,
            name: "Same",
            createdAt: folder.createdAt,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )
        _ = try await store.update(sameFolder, as: FolderEntity.self)

        // Then — 여전히 동일한 값
        let fetched = try await store.fetch(byID: folder.id, as: FolderEntity.self)
        XCTAssertEqual(fetched.name, "Same")
    }

    // MARK: - Delete(byId) 후 조회 실패

    func test_폴더삭제후_다시조회시_fetchFailed에러를던진다() async throws {
        // Given
        let store = try await makeStore()
        let folder = makeFolder(name: "곧 삭제될 폴더")
        _ = try await store.create(folder, as: FolderEntity.self)

        // When
        _ = try await store.delete(byID: folder.id, as: FolderEntity.self)

        // Then
        do {
            _ = try await store.fetch(byID: folder.id, as: FolderEntity.self)
            XCTFail("삭제 후 조회 시 에러가 발생해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail("예상한 에러는 .fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    // MARK: - SortDescriptors 기준 정렬 (createdAt 내림차순)

    func test_여러폴더존재시_전체조회시_생성일내림차순으로정렬된다() async throws {
        // Given
        let store = try await makeStore()
        let now = Date()
        let newest = Folder(name: "Newest", createdAt: now)
        let middle = Folder(name: "Middle", createdAt: now.addingTimeInterval(-100))
        let oldest = Folder(name: "Oldest", createdAt: now.addingTimeInterval(-200))

        // 의도적으로 순서를 뒤섞어 생성
        _ = try await store.create(newest, as: FolderEntity.self)
        _ = try await store.create(oldest, as: FolderEntity.self)
        _ = try await store.create(middle, as: FolderEntity.self)

        // When
        let allFolders = try await store.fetchAll(FolderEntity.self)

        // Then — createdAt descending
        XCTAssertEqual(allFolders.count, 3)
        XCTAssertEqual(allFolders[0].id, newest.id, "첫 번째는 가장 새로운 폴더여야 합니다.")
        XCTAssertEqual(allFolders[1].id, middle.id, "두 번째는 중간 폴더여야 합니다.")
        XCTAssertEqual(allFolders[2].id, oldest.id, "세 번째는 가장 오래된 폴더여야 합니다.")
    }

    // MARK: - toDomain() 동일성 검증

    func test_DB에저장후_조회시_원본도메인객체와동일하다() async throws {
        // Given
        let store = try await makeStore()
        let deletedDate = Date.now
        let folder = Folder(name: "도메인 동일성", isDeletable: false, deletedAt: deletedDate)

        // When
        _ = try await store.create(folder, as: FolderEntity.self)
        let restored = try await store.fetch(byID: folder.id, as: FolderEntity.self)

        // Then
        XCTAssertEqual(restored.id, folder.id)
        XCTAssertEqual(restored.name, folder.name)
        XCTAssertEqual(
            restored.createdAt.timeIntervalSinceReferenceDate,
            folder.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1
        )
        XCTAssertEqual(restored.isDeletable, folder.isDeletable)
        XCTAssertEqual(restored.deletedAt, folder.deletedAt)
    }

    // MARK: - insert(from:) 최소 상태 만족

    func test_필수값만있는폴더로_생성시_기본값이정상할당된다() async throws {
        // Given
        let store = try await makeStore()
        let minimalFolder = Folder(name: "Minimal")

        // When
        let saved = try await store.create(minimalFolder, as: FolderEntity.self)

        // Then
        XCTAssertEqual(saved.id, minimalFolder.id)
        XCTAssertEqual(saved.name, "Minimal")
        XCTAssertTrue(saved.isDeletable, "기본값 isDeletable은 true여야 합니다.")
        XCTAssertNil(saved.deletedAt, "기본값 deletedAt은 nil이어야 합니다.")
        XCTAssertTrue(saved.content.isEmpty, "기본값 content는 빈 배열이어야 합니다.")
    }

    // MARK: - toDomain()이 voiceNotes를 빈 배열로 반환하는지 검증

    func test_조회된엔티티에서_toDomain호출시_content가빈배열이다() async throws {
        // Given — FolderEntity.toDomain()은 성능 최적화를 위해 content를 빈 배열로 반환
        let store = try await makeStore()
        let folder = makeFolder(name: "빈 content 검증")
        _ = try await store.create(folder, as: FolderEntity.self)

        // When
        let fetched = try await store.fetch(byID: folder.id, as: FolderEntity.self)

        // Then — content는 항상 빈 배열 (별도 fetch로 voiceNotes를 가져와야 함)
        XCTAssertTrue(fetched.content.isEmpty)
    }
}
