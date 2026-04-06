import Data
import Domain
import Foundation
import Presentation
import UIKit

/// App의 모든 의존성(의존성 그래프)을 구성하고 객체를 생성하는 Pure DI 컨테이너입니다.
/// 외부 라이브러리에 의존하지 않고 생성자 주입(Constructor Injection) 방식으로 객체를 조립합니다.
@MainActor
public final class AppDIContainer {
    private lazy var store = UserDefaultsKeyValueStoreService()
    private lazy var audioService = AudioService()
    private lazy var storageService = FileManagerStorageService()

    public init() {}

    // MARK: - 온보딩 플로우 (Presentation)

    /// OnBoarding 화면을 시작할 때 호출될 Factory 메서드
    public func makeOnBoardingViewController() -> OnBoardingViewController {
        // [2] Repository (Data Layer)
        let languageRepository = DefaultLanguageRepository(store: store)
        let voiceRecordRepository = DefaultVoiceRecordRepository(
            audioService: audioService,
            storageService: storageService
        )
        let checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(store: store)

        // [3] UseCase (Domain Layer)

        let selectLanguageUseCase = DefaultSelectLanguageUseCase(repository: languageRepository)
        let checkMicrophonePermissionUseCase =
            DefaultCheckMicrophonePermissionUseCase(repository: voiceRecordRepository)
        let requestMicrophonePermissionUseCase =
            DefaultRequestMicrophonePermissionUseCase(repository: voiceRecordRepository)
        let checkFirstLaunchUseCase = DefaultCheckFirstLaunchUseCase(repository: checkFirstLaunchRepository)

        let viewModel = OnBoardingViewModel(
            selectLanguageUseCase: selectLanguageUseCase,
            checkMicrophonePermissionUseCase: checkMicrophonePermissionUseCase,
            requestMicrophonePermissionUseCase: requestMicrophonePermissionUseCase,
            checkFirstLaunchUseCase: checkFirstLaunchUseCase
        )

        return OnBoardingViewController(vm: viewModel)
    }

    // MARK: - 메인 플로우

    public func makeMainViewController() -> MainViewController {
        MainViewController()
    }

    public func makeRecordingViewController(coordinator: RecordingCoordinating) -> RecordingViewController {
        let voiceRecordRepository = DefaultVoiceRecordRepository(
            audioService: audioService,
            storageService: storageService
        )

        let viewModel = RecordingViewModel(
            startRecordingUseCase: DefaultStartRecordingUseCase(recordingRepository: voiceRecordRepository),
            pauseRecordingUseCase: DefaultPauseRecordingUseCase(recordingRepository: voiceRecordRepository),
            resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: voiceRecordRepository),
            finishRecordingUseCase: DefaultFinishRecordingUseCase(recordingRepository: voiceRecordRepository),
            cancelRecordingUseCase: DefaultCancelRecordingUseCase(recordingRepository: voiceRecordRepository)
        )
        viewModel.coordinator = coordinator

        return RecordingViewController(viewModel: viewModel)
    }
}

public extension AppDIContainer {
    // MARK: - 공통 유즈케이스 (App)

    func checkFirstLaunchUser() -> Bool {
        let repository = DefaultCheckFirstLaunchRepository(store: store)
        let useCase = DefaultCheckFirstLaunchUseCase(repository: repository)

        return useCase.checkIsFirstLaunch()
    }
}
