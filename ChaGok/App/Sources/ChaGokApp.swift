import Presentation
import Data
import Domain
import SwiftUI

@main
struct ChaGokApp: App {
    let controller: PersistenceController?
    let vm: MainViewModel?
    let initError: ChaGokSystemError?

    init() {
        do {
            controller = try .getInstance(method: .preview)
            let repository: DefaultFolderRepository = .init(controller: controller!)

            vm = .init(
                createFolderUseCase: DefaultCreateFolderUseCase(repository: repository),
                readFolderUseCase: DefaultReadFolderUseCase(repository: repository),
                updateFolderUseCase: DefaultUpdateFolderUseCase(repository: repository),
                deleteFolderUseCase: DefaultDeleteFolderUseCase(repository: repository)
            )

            initError = nil
        } catch let error as Domain.ChaGokSystemError {
            self.controller = nil
            self.vm = nil
            self.initError = error
        } catch {
            self.controller = nil
            self.vm = nil
            initError = .unkownError
        }
    }

    var body: some Scene {
        WindowGroup {
            switch initError {
            case .rootDirectoryNotFound:
                EmptyView()
            case .initializeCoreDataFailed:
                EmptyView()
            case .systemStorageIsFull:
                EmptyView()
            case .unkownError:
                EmptyView()
            case nil: // error == nil 이면 vm 또한 존재 함.
                if let vm = vm {
                    CoreDataTestView(vm: vm)
                } else {
                    EmptyView()
                }
            }
        }
    }
}
