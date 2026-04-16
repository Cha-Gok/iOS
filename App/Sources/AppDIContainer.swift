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
    private lazy var audioService = AudioService()
    private lazy var audioPlaybackService = AudioPlaybackPlayerService()
    private lazy var storageService = FileManagerStorageService()
    private let localDataBase: CoreDataLocalDataBase

    /// Repository
    private lazy var languageRepository = DefaultLanguageRepository(store: store)
    private lazy var voiceRecordRepository = DefaultVoiceRecordRepository(
        audioService: audioService,
        storageService: storageService
    )
    private lazy var voiceRecordPlaybackRepository = DefaultVoiceRecordPlaybackRepository(
        audioPlaybackService: audioPlaybackService,
        storageService: storageService
    )
    private lazy var checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(store: store)
    private lazy var folderRepository = DefaultFolderRepository(store: localDataBase)
    private lazy var voiceNoteCreateRepository = DefaultVoiceNoteCreateRepository(store: localDataBase)
    private lazy var voiceNoteFetchRepository = DefaultVoiceNoteFetchRepository(store: localDataBase)
    private lazy var voiceNoteUpdateRepository = DefaultVoiceNoteUpdateRepository(store: localDataBase)
    private lazy var wasteBasketRepository = DefaultWasteBasketRepository(store: localDataBase)
    private lazy var sttRepository = DefaultSTTRepository(service: SpeechService(), storageService: storageService)
    private lazy var summaryRepository = DefaultSummaryRepository(service: AppleFoundationSummaryService())

    /// UseCase
    private lazy var selectLanguageUseCase = DefaultSelectLanguageUseCase(
        repository: languageRepository
    )
    private lazy var microphonePermissionUseCase = DefaultMicrophonePermissionUseCase(
        repository: voiceRecordRepository
    )
    private lazy var recordingUseCase = DefaultRecordingUseCase(
        repository: voiceRecordRepository
    )
    private lazy var playbackUseCase = DefaultPlaybackUseCase(
        repository: voiceRecordPlaybackRepository
    )
    private lazy var checkFirstLaunchUseCase = DefaultCheckFirstLaunchUseCase(
        repository: checkFirstLaunchRepository
    )
    private lazy var completeFirstLaunchUseCase = DefaultCompleteFirstLaunchUseCase(
        repository: checkFirstLaunchRepository
    )
    private lazy var createFolderUseCase = DefaultCreateFolderUseCase(repository: folderRepository)
    private lazy var fetchFolderUseCase = DefaultFetchFolderUseCase(repository: folderRepository)
    private lazy var updateFolderUseCase = DefaultUpdateFolderUseCase(repository: folderRepository)
    private lazy var createDefaultFolderUseCase = DefaultCreateDefaultFolderUseCase(
        repository: folderRepository
    )
    private lazy var createVoiceNoteUseCase = DefaultCreateVoiceNoteUseCase(
        repository: voiceNoteCreateRepository
    )
    private lazy var fetchVoiceNoteUseCase = DefaultFetchVoiceNoteUseCase(
        repository: voiceNoteFetchRepository
    )
    private lazy var fetchRecentVoiceNoteUseCase = DefaultFetchRecentVoiceNoteUseCase(
        repository: voiceNoteFetchRepository
    )
    private lazy var fetchWasteBasketUseCase = DefaultFetchWasteBasketFolderUseCase(
        repository: wasteBasketRepository
    )
    private lazy var deleteWasteBasketUseCase = DefaultDeleteWasteBasketUseCase(
        repository: wasteBasketRepository
    )
    private lazy var moveWasteBasketUseCase = DefaultMoveWasteBasketUseCase(
        repository: wasteBasketRepository
    )
    private lazy var restoreWasteBasketUseCase = DefaultRestoreWasteBasketUseCase(
        repository: wasteBasketRepository
    )
    private lazy var fetchLanguageUseCase = DefaultFetchLanguageUseCase(repository: languageRepository)
    private lazy var updateVoiceNoteUseCase = DefaultUpdateVoiceNoteUseCase(repository: voiceNoteUpdateRepository)
    private lazy var audioToSummaryUseCase = DefaultAudioToSummaryUseCase(
        sttRepository: sttRepository,
        summaryRepository: summaryRepository
    )

    public init() throws {
        localDataBase = try CoreDataLocalDataBase()
    }

    // MARK: - UseCase

    func makeCheckFirstLaunchUseCase() -> CheckFirstLaunchUseCase {
        checkFirstLaunchUseCase
    }

    func makeMicrophonePermissionUseCase() -> MicrophonePermissionUseCase {
        microphonePermissionUseCase
    }

    // MARK: - ViewModel

    public func makeOnBoardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            selectLanguageUseCase: selectLanguageUseCase,
            microphonePermissionUseCase: microphonePermissionUseCase,
            completeFirstLaunchUseCase: completeFirstLaunchUseCase,
            createDefaultFolderUseCase: createDefaultFolderUseCase
        )
    }

    public func makeRecordingViewModel() -> RecordingViewModel {
        RecordingViewModel(
            recordingUseCase: recordingUseCase,
            createVoiceNoteUseCase: createVoiceNoteUseCase
        )
    }

    public func makeVoiceNoteViewModel(voiceNote: VoiceNote) -> VoiceNoteViewModel {
        VoiceNoteViewModel(
            voiceNote: voiceNote,
            audioToSummaryUseCase: audioToSummaryUseCase,
            updateVoiceNoteUseCase: updateVoiceNoteUseCase,
            fetchLanguageUseCase: fetchLanguageUseCase,
            fetchFolderUseCase: fetchFolderUseCase,
            playbackUseCase: playbackUseCase
        )
    }

    public func makeMainViewModel() -> MainViewModel {
        return MainViewModel(
            fetchRecentVoiceNoteUseCase: fetchRecentVoiceNoteUseCase,
            fetchVoiceNoteUseCase: fetchVoiceNoteUseCase,
            fetchFolderUseCase: fetchFolderUseCase,
            fetchTrashUseCase: fetchWasteBasketUseCase
        )
    }

    public func makeTrashViewModel() -> TrashViewModel {
        return TrashViewModel(
            fetchUseCase: fetchWasteBasketUseCase,
            deleteUseCase: deleteWasteBasketUseCase,
            restoreUseCase: restoreWasteBasketUseCase
        )
    }

    public func makeMyFolderViewModel(_ category: CategoryToggle) -> FolderViewModel {
        return FolderViewModel(
            category: category,
            createUseCase: createFolderUseCase,
            updateUseCase: updateFolderUseCase,
            moveToTrashUseCase: moveWasteBasketUseCase
        )
    }

    public func makeMyFolderDetailViewModel(_ folder: Folder) -> FolderDetailViewModel {
        return FolderDetailViewModel(
            title: folder.name,
            folderID: folder.id,
            fetchVoiceNoteUseCase: fetchVoiceNoteUseCase
        )
    }

    public func makeMoveFolderListViewModel(voiceNote: VoiceNote) -> MoveFolderListViewModel {
        return MoveFolderListViewModel(
            voiceNote: voiceNote,
            fetchFolderUseCase: fetchFolderUseCase,
            updateVoiceNoteUseCase: updateVoiceNoteUseCase
        )
    }

    public func makeNewFolderViewModel() -> NewFolderViewModel {
        return NewFolderViewModel(createFolderUseCase: createFolderUseCase)
    }
}

