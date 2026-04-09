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
    private lazy var storageService = FileManagerStorageService()
    private let localDataBase: CoreDataLocalDataBase

    /// Repository
    private lazy var languageRepository = DefaultLanguageRepository(store: store)
    private lazy var voiceRecordRepository = DefaultVoiceRecordRepository(
        audioService: audioService,
        storageService: storageService
    )
    private lazy var checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(store: store)
    private lazy var folderRepository = DefaultFolderRepository(store: localDataBase)
    private lazy var voiceNoteCreateRepository = DefaultVoiceNoteCreateRepository(store: localDataBase)
    private lazy var voiceNoteFetchRepository = DefaultVoiceNoteFetchRepository(store: localDataBase)
    private lazy var voiceNoteUpdateRepository = DefaultVoiceNoteUpdateRepository(store: localDataBase)
    private lazy var wasteBasketRepository = DefaultWasteBasketRepository(store: localDataBase)
    private lazy var sttRepository = DefaultSTTRepository(service: SpeechService())
    private lazy var summaryRepository = DefaultSummaryRepository(service: AppleFoundationSummaryService())

    /// UseCase
    private lazy var selectLanguageUseCase = DefaultSelectLanguageUseCase(
        repository: languageRepository
    )
    private lazy var checkMicrophonePermissionUseCase =
        DefaultCheckMicrophonePermissionUseCase(repository: voiceRecordRepository)
    private lazy var requestMicrophonePermissionUseCase =
        DefaultRequestMicrophonePermissionUseCase(repository: voiceRecordRepository)
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

    // MARK: - 온보딩 플로우 (Presentation)

    func makeCheckFirstLaunchUseCase() -> CheckFirstLaunchUseCase {
        checkFirstLaunchUseCase
    }

    /// OnBoarding 화면을 시작할 때 호출될 Factory 메서드
    public func makeOnBoardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            selectLanguageUseCase: selectLanguageUseCase,
            checkMicrophonePermissionUseCase: checkMicrophonePermissionUseCase,
            requestMicrophonePermissionUseCase: requestMicrophonePermissionUseCase,
            completeFirstLaunchUseCase: completeFirstLaunchUseCase,
            createDefaultFolderUseCase: createDefaultFolderUseCase
        )
    }

    // MARK: - 메인 플로우

    public func makeRecordingViewModel() -> RecordingViewModel {
        RecordingViewModel(
            startRecordingUseCase: DefaultStartRecordingUseCase(
                recordingRepository: voiceRecordRepository
            ),
            pauseRecordingUseCase: DefaultPauseRecordingUseCase(
                recordingRepository: voiceRecordRepository
            ),
            resumeRecordingUseCase: DefaultResumeRecordingUseCase(
                recordingRepository: voiceRecordRepository
            ),
            finishRecordingUseCase: DefaultFinishRecordingUseCase(
                recordingRepository: voiceRecordRepository
            ),
            cancelRecordingUseCase: DefaultCancelRecordingUseCase(
                recordingRepository: voiceRecordRepository
            ),
            createVoiceNoteUseCase: createVoiceNoteUseCase
        )
    }

    public func makeVoiceNoteViewModel(voiceNote: VoiceNote) -> VoiceNoteViewModel {
        VoiceNoteViewModel(
            voiceNote: voiceNote,
            audioToSummaryUseCase: audioToSummaryUseCase,
            updateVoiceNoteUseCase: updateVoiceNoteUseCase,
            fetchLanguageUseCase: fetchLanguageUseCase,
            fetchFolderUseCase: fetchFolderUseCase
        )
    }

    public func makeMainViewModel() -> MainViewModel {
        return MainViewModel(
            fetchFolderUseCase: fetchFolderUseCase,
            fetchVoiceNoteUseCase: fetchVoiceNoteUseCase,
            fetchRecentVoiceNoteUseCase: fetchRecentVoiceNoteUseCase
        )
    }

    public func makeTrashViewModel() -> TrashViewModel {
        return TrashViewModel(
            fetchUseCase: fetchWasteBasketUseCase,
            deleteUseCase: deleteWasteBasketUseCase,
            restoreUseCase: restoreWasteBasketUseCase
        )
    }

    public func makeTrashViewController() -> TrashViewController {
        return TrashViewController()
    }

    public func makeMyFolderViewModel(_ category: CategoryToggle) -> FolderViewModel {
        return FolderViewModel(
            category: category,
            createUseCase: createFolderUseCase,
            updateUseCase: updateFolderUseCase,
            moveToTrashUseCase: moveWasteBasketUseCase
        )
    }
}
