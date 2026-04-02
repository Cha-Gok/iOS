import Data
import Domain
import Foundation
import Presentation
import UIKit

/// App의 모든 의존성(의존성 그래프)을 구성하고 객체를 생성하는 Pure DI 컨테이너입니다.
/// 외부 라이브러리에 의존하지 않고 생성자 주입(Constructor Injection) 방식으로 객체를 조립합니다.
@MainActor
public final class AppDIContainer {
    public static let shared = AppDIContainer()

    // 전역적으로 공유되어야 하는 네트워크 관련 객체 역이나 로컬 캐시, DB 레이어 등을 이곳에서 1번만 초기화하여 들고 있도록 구성할 수 있습니다.
    // 예: private lazy var networkService = DefaultNetworkService()

    private init() {}

    // MARK: - 온보딩 플로우 (Presentation)

    /// OnBoarding 화면을 시작할 때 호출될 Factory 메서드
    public func makeOnBoardingViewController(onFinish: @escaping () -> Void) -> UIViewController {
        // [1] InfraStructure (외부 환경/서비스)
        let store = UserDefaultsKeyValueStoreService()
        let audioService = AudioService()
        let storageService = FileManagerStorageService()

        // [2] Repository (Data Layer)
        let languageRepository = DefaultLanguageRepository(store: store)
        let voiceRecordRepository = DefaultVoiceRecordRepository(
            audioService: audioService,
            storageService: storageService
        )

        // [3] UseCase (Domain Layer)

        let selectLanguageUseCase = DefaultSelectLanguageUseCase(repository: languageRepository)
        let checkMicrophonePermissionUseCase =
            DefaultCheckMicrophonePermissionUseCase(repository: voiceRecordRepository)
        let requestMicrophonePermissionUseCase =
            DefaultRequestMicrophonePermissionUseCase(repository: voiceRecordRepository)
        let checkFirstLaunchUseCase = makeCheckFirstLaunchUseCase()

        let viewModel = OnBoardingViewModel(
            selectLanguageUseCase: selectLanguageUseCase,
            checkMicrophonePermissionUseCase: checkMicrophonePermissionUseCase,
            requestMicrophonePermissionUseCase: requestMicrophonePermissionUseCase,
            checkFirstLaunchUseCase: checkFirstLaunchUseCase
        )

        // viewModel에 클로저 주입
        viewModel.onFinishOnBoarding = onFinish

        return OnBoardingViewController(vm: viewModel)
    }

    // MARK: - 메인 플로우

    public func makeMainViewController() -> UIViewController {
        // ContentViewController 생성에 필요한 DI
        return MainViewController()
    }
}

public extension AppDIContainer {
    // MARK: - 공통 유즈케이스 (App)

    func makeCheckFirstLaunchUseCase() -> CheckFirstLaunchUseCase {
        let store = UserDefaultsKeyValueStoreService()
        let repository = DefaultCheckFirstLaunchRepository(store: store)
        return DefaultCheckFirstLaunchUseCase(repository: repository)
    }
}
