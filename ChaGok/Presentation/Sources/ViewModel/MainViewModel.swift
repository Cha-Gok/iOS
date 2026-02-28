import Foundation
import Domain

@MainActor
public final class MainViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var folders: [Domain.Folder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Domain.FolderError?

    // MARK: - Dependencies (DI)
    private let createFolderUseCase: Domain.CreateFolderUseCase
    private let readFolderUseCase: Domain.ReadFolderUseCase
    private let updateFolderUseCase: Domain.UpdateFolderUseCase
    private let deleteFolderUseCase: Domain.DeleteFolderUseCase

    // MARK: - Initializer
    public init(
        createFolderUseCase: CreateFolderUseCase,
        readFolderUseCase: ReadFolderUseCase,
        updateFolderUseCase: UpdateFolderUseCase,
        deleteFolderUseCase: DeleteFolderUseCase
    ) {
        self.createFolderUseCase = createFolderUseCase
        self.readFolderUseCase = readFolderUseCase
        self.updateFolderUseCase = updateFolderUseCase
        self.deleteFolderUseCase = deleteFolderUseCase
    }

    // MARK: - CRUD Actions

    /// 모든 폴더 목록을 가져옵니다.
    func fetchFolders() async {
        isLoading = true
        error = nil
        do {
            self.folders = try await readFolderUseCase.execute()
        } catch {
            self.error = .readFailed
        }
        isLoading = false
    }

    /// 새로운 폴더를 생성합니다.
    func createFolder(name: String) async {
        guard !name.isEmpty else { return }
        isLoading = true
        do {
            _ = try await createFolderUseCase.execute(name: name)
            await fetchFolders() // 목록 갱신
        } catch {
            self.error = .createFailed
        }
        isLoading = false
    }

    /// 폴더 이름을 수정합니다 (이름 뒤에 반짝이 추가하는 예시 로직)
    func updateFolderName(folder: Folder) async {
        isLoading = true
        let updatedFolder = Folder(
            id: folder.id,
            path: folder.path,
            name: folder.name + "✨",
            createdAt: folder.createdAt,
        )

        do {
            _ = try await updateFolderUseCase.execute(updatedFolder)
            await fetchFolders()
        } catch {
            self.error = .updateFailed
        }
        isLoading = false
    }

    /// 폴더를 삭제합니다.
    func deleteFolder(id: UUID) async {
        isLoading = true
        do {
            // UseCase가 String ID를 받으므로 uuidString으로 변환하여 전달
            try await deleteFolderUseCase.execute(byId: id)
            await fetchFolders()
        } catch {
            self.error = .deleteFailed
        }
        isLoading = false
    }

    /// 에러 상태를 초기화합니다.
    func clearError() {
        self.error = nil
    }
}
