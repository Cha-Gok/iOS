import SwiftUI
import Domain

public struct CoreDataTestView: View {
    @StateObject private var vm: MainViewModel
    @State private var newFolderName: String = ""

    public init(vm: MainViewModel) {
        _vm = StateObject(
            wrappedValue: vm
        )
    }

    public var body: some View {
        NavigationStack {
            List {
                // 1. Create 섹션
                Section(header: Text("새 폴더 생성 (Domain UseCase)")) {
                    HStack {
                        TextField("폴더 이름 입력", text: $newFolderName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button {
                            Task {
                                await vm.createFolder(name: newFolderName)
                                newFolderName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newFolderName.isEmpty)
                    }
                    .padding(.vertical, 5)
                }

                // 2. Read, Update, Delete 섹션
                Section(header: Text("폴더 목록 (\(vm.folders.count))")) {
                    if vm.isLoading {
                        ProgressView("로딩 중...")
                    } else if vm.folders.isEmpty {
                        Text("폴더가 없습니다. 위에서 추가해 보세요.")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }

                    ForEach(vm.folders, id: \.id) { folder in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(folder.name)
                                    .font(.headline)
                                Spacer()
                                Button("수정") {
                                    Task { await vm.updateFolderName(folder: folder) }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }

                            Text("생성일: \(folder.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let folder = vm.folders[index]
                            Task { await vm.deleteFolder(id: folder.id) }
                        }
                    }
                }
            }
            .navigationTitle("Core Data CRUD 테스트")
            .toolbar {
                EditButton()
            }
            .task {
                await vm.fetchFolders()
            }
            .alert("에러", isPresented: Binding(
                get: { vm.error != nil },
                set: { if !$0 { vm.clearError() } }
            )) {
                Button("확인") { }
            } message: {
                Text(vm.error?.errorDescription ?? "알 수 없는 에러가 발생했습니다.")
            }
        }
    }
}
