import Domain
import Foundation

/// Sandbox UI에서 테스트할 UseCase들을 주입받기 위한 프로토콜입니다.
/// App 레이어의 Dependency Injection 단계에서 실제 구현체 또는 Mock을 주입합니다.
public protocol SandboxDependency: Sendable {
    // WorkSpace (구현체 미 구현)

    // Authority (Check , Request)
    var checkFirstLaunchUseCase: CheckFirstLaunchUseCase { get }
    var checkMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase { get }
    var checkSTTPermissionUseCase: CheckSTTPermissionUseCase { get }

    var requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase { get }
    var requestSTTPermissionUseCase: RequestSTTPermissionUseCase { get }

    // WasteBasket (구현체 미 구현)

    /// VoiceNote (구현체 미 구현)
    var runSummarySandbox: @Sendable () async throws -> String { get }

    // Language
    var fetchLanguageUseCase: FetchLanguageUseCase { get }
    var selectLanguageUseCase: SelectLanguageUseCase { get }
    // Folders UseCase
    var createFolderUseCase: CreateFolderUseCase { get }
    var readFolderUseCase: ReadFolderUseCase { get }
    var updateFolderUseCase: UpdateFolderUseCase { get }

    // Recoding UseCase
    var startRecordingUseCase: StartRecordingUseCase { get }
    var pauseRecordingUseCase: PauseRecordingUseCase { get }
    var resumeRecordingUseCase: ResumeRecordingUseCase { get }
    var finishRecordingUseCase: FinishRecordingUseCase { get }
}
