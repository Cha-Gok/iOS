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
    private lazy var mlxProvider = MLXModelProvider()

    /// Repository
    private lazy var languageRepository = DefaultLanguageRepository(store: store)
    private lazy var voiceRecordRepository = DefaultVoiceRecordRepository(storageService: storageService)
    private lazy var checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(store: store)
    private lazy var folderRepository = DefaultFolderRepository(context: localDataBase.container.viewContext)
    private lazy var voiceNoteRepository = DefaultVoiceNoteRepository(context: localDataBase.container.viewContext)
    private lazy var sttRepository = DefaultSTTRepository(
        storageService: storageService,
        languageRepository: languageRepository
    )
    private lazy var summaryRepository = DefaultSummaryRepository()
    private lazy var mlxSummaryRepository = DefaultMLXSummaryRepository(
        provider: mlxProvider
    )
    private lazy var whisperProvider = WhisperKitProvider(
        languageRepository: languageRepository
    )
    private lazy var availableSupportModelRepository = DefaultAvailableModelSupportRepository(
        mlxProvider: mlxProvider,
        whisperProvider: whisperProvider
    )

    private lazy var sttWhisperRepository = DefaultWhisperSTTRepository(
        storageService: storageService,
        dataSource: whisperProvider
    )
    
    private lazy var mlxOnDeviceRepository = DefaultMlxOnDeviceRepository(
        provider: mlxProvider,
        storageService: storageService
    )
    
    private lazy var whisperOnDeviceRepository = DefaultWhisperOnDeviceRepository(
        storageService: storageService,
        provider: whisperProvider
    )
    /// Analysis (Domain Service)
    private(set) lazy var voiceNoteAnalysisService = DefaultVoiceNoteAnalysisService(
        voiceNoteRepository: voiceNoteRepository,
        sttRepository: sttWhisperRepository,
        summaryRepository: mlxSummaryRepository,
        languageRepository: languageRepository
    )

    /// UseCase
    private lazy var folderUseCase = DefaultFolderUseCase(repository: folderRepository)
    private lazy var voiceNoteUseCase = DefaultVoiceNoteUseCase(
        repository: voiceNoteRepository,
        folderRepository: folderRepository,
        analysisService: voiceNoteAnalysisService
    )
    private lazy var onDeviceStatusUseCase = DefaultOnDeviceStatusUseCase(
        whisperRepository: whisperOnDeviceRepository,
        mlxRepository: mlxOnDeviceRepository
    )
    public init() throws {
        localDataBase = try CoreDataLocalDataBase()
    }

    // MARK: - Whisper 모델 ( preload , download ) Status

    public func isWhisperModelDownloaded() async -> Bool {
        do {
            _ = try await whisperProvider.getDownloadPath()
            return true
        } catch {
            AppLogger.error(error)
            return false
        }
    }

    public func preloadWhisperKit() {
        Task { @MainActor in
            await whisperProvider.preload()
        }
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
            sttRepository: sttRepository,
            checkFirstLaunchRepository: checkFirstLaunchRepository,
            folderUseCase: folderUseCase,
            availableSupportModelRepository: availableSupportModelRepository,
            mlxRepository: mlxOnDeviceRepository
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
            playbackRepository: DefaultVoiceRecordPlaybackRepository(storageService: storageService)
        )
    }

    public func makeMainViewModel() -> MainViewModel {
        return MainViewModel(
            microphoneRepository: voiceRecordRepository,
            voiceNoteUseCase: voiceNoteUseCase,
            folderUseCase: folderUseCase
        )
    }

    public func makeTrashViewModel() -> TrashViewModel {
        return TrashViewModel(
            folderUseCase: folderUseCase,
            voiceNoteUseCase: voiceNoteUseCase
        )
    }

    public func makeMyFolderViewModel(_ category: CategoryToggle) -> FolderViewModel {
        return FolderViewModel(
            category: category,
            folderUseCase: folderUseCase
        )
    }

    public func makeMyFolderDetailViewModel(_ folder: Folder, isTrashMode: Bool = false) -> FolderDetailViewModel {
        return FolderDetailViewModel(
            title: folder.name,
            folderID: folder.id,
            isTrashMode: isTrashMode,
            voiceNoteUseCase: voiceNoteUseCase
        )
    }

    public func makeMoveFolderListViewModel(
        voiceNotes: [VoiceNote],
        onComplete: ((String) -> Void)? = nil
    ) -> MoveFolderListViewModel {
        return MoveFolderListViewModel(
            voiceNotes: voiceNotes,
            folderUseCase: folderUseCase,
            voiceNoteUseCase: voiceNoteUseCase,
            onComplete: onComplete
        )
    }

    public func makeNewFolderViewModel() -> NewFolderViewModel {
        return NewFolderViewModel(folderUseCase: folderUseCase)
    }

    public func makeSearchViewModel(
        type: SearchViewModel.SearchType,
        items: [ContentItem],
        isTrashMode: Bool = false
    ) -> SearchViewModel {
        return SearchViewModel(
            type: type,
            items: items,
            isTrashMode: isTrashMode,
            folderRepository: folderRepository
        )
    }

    public func makeChaGokAlertViewModel(environment: ChaGokAlertViewModel.AlertEnvironment) -> ChaGokAlertViewModel {
        return ChaGokAlertViewModel(environment: environment)
    }

    public func makeDownloadOnDeviceViewModel() -> DownloadOnDeviceViewModel {
        return DownloadOnDeviceViewModel(
            repository: sttWhisperRepository
        )
    }

    public func makeSettingViewModel() -> SettingViewModel {
        return SettingViewModel(
            languageRepository: languageRepository,
            availableModelRepository: availableSupportModelRepository,
            onDeviceStatusUseCase: onDeviceStatusUseCase
        )
    }

    #if DEBUG
        public func seedDebugDataIfNeeded() {
            DebugSeeder(
                folderRepository: folderRepository,
                voiceNoteRepository: voiceNoteRepository
            ).seedIfNeeded()
        }
    #endif
}
