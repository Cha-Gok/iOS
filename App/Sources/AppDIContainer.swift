import Core
import Data
import Domain
import Foundation
import Presentation
import UIKit

/// App의 모든 의존성(의존성 그래프)을 구성하고 객체를 생성하는 Pure DI 컨테이너입니다.
/// 외부 라이브러리에 의존하지 않고 생성자 주입(Constructor Injection) 방식으로 객체를 조립합니다.
@MainActor
public final class AppDIContainer {
    /// InfraStructure
    private lazy var store = UserDefaultsKeyValueStoreService()
    private lazy var storageService = FileManagerStorageService()
    private let localDataBase: CoreDataLocalDataBase

    /// Repository
    private lazy var languageRepository = DefaultLanguageRepository(store: store)
    private lazy var voiceRecordRepository = DefaultVoiceRecordRepository(storageService: storageService)
    private lazy var voiceRecordPlaybackRepository =
        DefaultVoiceRecordPlaybackRepository(storageService: storageService)
    private lazy var checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(store: store)
    private lazy var folderRepository = DefaultFolderRepository(store: localDataBase)
    private lazy var voiceNoteRepository = DefaultVoiceNoteRepository(store: localDataBase)
    private lazy var wasteBasketRepository = DefaultWasteBasketRepository(store: localDataBase)
    private lazy var sttRepository = DefaultSTTRepository(storageService: storageService)
    private lazy var summaryRepository = DefaultSummaryRepository()

    /// UseCase
    private lazy var folderUseCase = DefaultFolderUseCase(repository: folderRepository)
    private lazy var voiceNoteUseCase = DefaultVoiceNoteUseCase(
        repository: voiceNoteRepository,
        sttRepository: sttRepository,
        summaryRepository: summaryRepository
    )
    public init() throws {
        localDataBase = try CoreDataLocalDataBase()
    }

    // MARK: - Repository

    func makeCheckFirstLaunchRepository() -> CheckFirstLaunchRepository {
        checkFirstLaunchRepository
    }

    func makeVoiceRecordRepository() -> VoiceRecordRepository {
        voiceRecordRepository
    }

    // MARK: - ViewModel

    public func makeOnBoardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            languageRepository: languageRepository,
            voiceRecordRepository: voiceRecordRepository,
            checkFirstLaunchRepository: checkFirstLaunchRepository,
            folderUseCase: folderUseCase
        )
    }

    public func makeRecordingViewModel() -> RecordingViewModel {
        RecordingViewModel(
            repository: voiceRecordRepository,
            voiceNoteUseCase: voiceNoteUseCase
        )
    }

    public func makeVoiceNoteViewModel(voiceNote: VoiceNote) -> VoiceNoteViewModel {
        VoiceNoteViewModel(
            voiceNote: voiceNote,
            voiceNoteUseCase: voiceNoteUseCase,
            folderUseCase: folderUseCase,
            languageRepository: languageRepository,
            playbackRepository: voiceRecordPlaybackRepository,
            wasteBasketRepository: wasteBasketRepository
        )
    }

    public func makeMainViewModel() -> MainViewModel {
        return MainViewModel(
            microphoneRepository: voiceRecordRepository,
            voiceNoteUseCase: voiceNoteUseCase,
            folderUseCase: folderUseCase,
            wasteBasketRepository: wasteBasketRepository
        )
    }

    public func makeTrashViewModel() -> TrashViewModel {
        return TrashViewModel(
            repository: wasteBasketRepository
        )
    }

    public func makeMyFolderViewModel(_ category: CategoryToggle) -> FolderViewModel {
        return FolderViewModel(
            category: category,
            folderUseCase: folderUseCase,
            wasteBasketRepository: wasteBasketRepository
        )
    }

    public func makeMyFolderDetailViewModel(_ folder: Folder) -> FolderDetailViewModel {
        return FolderDetailViewModel(
            title: folder.name,
            folderID: folder.id,
            voiceNoteUseCase: voiceNoteUseCase,
            wasteBasketRepository: wasteBasketRepository
        )
    }

    public func makeMoveFolderListViewModel(voiceNote: VoiceNote) -> MoveFolderListViewModel {
        return MoveFolderListViewModel(
            voiceNote: voiceNote,
            folderUseCase: folderUseCase,
            voiceNoteUseCase: voiceNoteUseCase
        )
    }

    public func makeNewFolderViewModel() -> NewFolderViewModel {
        return NewFolderViewModel(folderUseCase: folderUseCase)
    }
}
