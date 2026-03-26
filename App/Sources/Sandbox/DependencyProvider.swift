import Core
import Data
import Domain
import Foundation
import Presentation

public actor DependencyProvider {
    /// 모든 UseCase
    private var dependency: SandboxDependency?
    // infrastructure
    private var audioService: AudioRecorderService?
    private var folderDB: CoreDataLocalDataBase<FolderEntity>?
    private var firstlaunchService: FirstLaunchService?
    private var microphonePermissionService: MicrophonePermissionService?
    private var sttPermissionService: STTPermissionService?
    private var languageService: LanguageService?
    // repository
    private var checkFirstLaunchRepository: CheckFirstLaunchRepository?
    private var microphonePermissionRepository: MicrophonePermissionRepository?
    private var sttPermissionRepository: STTPermissionRepository?
    private var languageRepository: LanguageRepository?
    private var folderRepository: FolderRepository?

    private var recordStartRepository: VoiceRecordStartRepository?
    private var recordPauseRepository: VoiceRecordPauseRepository?
    private var recordResumeRepository: VoiceRecordResumeRepository?

    public init() {}

    /// 의존성을 안전하게 가져오는 헬퍼. 없으면 생성 후 반환.
    public func getDependency() async -> SandboxDependency? {
        if dependency == nil {
            await makeDependency()
        }
        return dependency
    }
}

// MARK: - 내부 은닉화된 함수들

extension DependencyProvider {
    /// 실 구현에 필요한 InfraStructure 주입
    private func makeInfrastructure() async throws {
        folderDB = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        audioService = AudioService()
        firstlaunchService = DefaultFirstLaunchService()
        microphonePermissionService = AudioService()
        sttPermissionService = SpeechService()
        languageService = LanguageSettingService()
    }

    /// 리포지토리 만드는 함수
    private func makeRepository() async throws {
        guard
            let folderDB,
            let audioService,
            let firstlaunchService,
            let microphonePermissionService,
            let sttPermissionService,
            let languageService
        else {
            throw NSError(domain: "리포지토리를 못 만들었습니다.", code: -1)
        }
        checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(service: firstlaunchService)
        microphonePermissionRepository = DefaultMicrophonePermissionRepository(service: microphonePermissionService)
        sttPermissionRepository = DefaultSTTPermissionRepository(service: sttPermissionService)
        languageRepository = DefaultLanguageRepository(service: languageService)
        folderRepository = DefaultFolderRepository(database: folderDB)
        recordStartRepository = DefaultVoiceRecordStartRepository(service: audioService)
        recordPauseRepository = DefaultVoiceRecordPauseRepository(service: audioService)
        recordResumeRepository = DefaultVoiceRecordResumeRepository(service: audioService)
    }

    /// 외부에서 의존성 주입을 트리거하는 함수
    private func makeDependency() async {
        do {
            // infrastructure 주입
            try await makeInfrastructure()
            // 리포지토리 주입
            try await makeRepository()
            // dependency 생성
            guard let checkFirstLaunchRepository,
                  let microphonePermissionRepository,
                  let sttPermissionRepository,
                  let languageRepository,
                  let folderRepository,
                  let recordStartRepository,
                  let recordPauseRepository,
                  let recordResumeRepository
            else {
                throw NSError(domain: "의존성 생성에 필요한 리포지토리가 없습니다.", code: -2)
            }

            dependency = DefaultSandboxDependency(
                checkFirstLaunchUseCase: DefaultCheckFirstLaunchUseCase(
                    repository: checkFirstLaunchRepository
                ),
                checkMicrophonePermissionUseCase: DefaultCheckMicrophonePermissionUseCase(
                    repository: microphonePermissionRepository
                ),
                checkSTTPermissionUseCase: DefaultCheckSTTPermissionUseCase(
                    repository: sttPermissionRepository
                ),
                requestMicrophonePermissionUseCase: DefaultRequestMicrophonePermissionUseCase(
                    repository: microphonePermissionRepository
                ),
                requestSTTPermissionUseCase: DefaultRequestSTTPermissionUseCase(
                    repository: sttPermissionRepository
                ),
                fetchLanguageUseCase: DefaultFetchLanguageUseCase(repository: languageRepository),
                selectLanguageUseCase: DefaultSelectLanguageUseCase(repository: languageRepository),
                createFolderUseCase: DefaultCreateFolderUseCase(repository: folderRepository),
                readFolderUseCase: DefaultReadFolderUseCase(repository: folderRepository),
                updateFolderUseCase: DefaultUpdateFolderUseCase(repository: folderRepository),
                startRecordingUseCase: DefaultStartRecordingUseCase(recordingRepository: recordStartRepository),
                pauseRecordingUseCase: DefaultPauseRecordingUseCase(recordingRepository: recordPauseRepository),
                resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: recordResumeRepository)
            )
        } catch {
            AppLogger.error(error)
        }
    }
}
