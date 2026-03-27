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
    private var storageService: StorageService?
    private var folderDB: CoreDataLocalDataBase<FolderEntity>?
    private var firstlaunchService: FirstLaunchService?
    private var sttPermissionService: STTPermissionService?
    private var languageService: LanguageService?
    // repository
    private var checkFirstLaunchRepository: CheckFirstLaunchRepository?
    private var sttPermissionRepository: STTPermissionRepository?
    private var languageRepository: LanguageRepository?
    private var folderRepository: FolderRepository?
    private var voiceRecordRepository: VoiceRecordRepository?

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
        storageService = FileManagerStorageService()
        firstlaunchService = DefaultFirstLaunchService()
        sttPermissionService = SpeechService()
        languageService = LanguageSettingService()
    }

    /// 리포지토리 만드는 함수
    private func makeRepository() async throws {
        guard
            let folderDB,
            let firstlaunchService,
            let sttPermissionService,
            let languageService,
            let audioService,
            let storageService
        else {
            throw NSError(domain: "리포지토리를 못 만들었습니다.", code: -1)
        }
        checkFirstLaunchRepository = DefaultCheckFirstLaunchRepository(service: firstlaunchService)
        sttPermissionRepository = DefaultSTTPermissionRepository(service: sttPermissionService)
        languageRepository = DefaultLanguageRepository(service: languageService)
        folderRepository = DefaultFolderRepository(database: folderDB)
        voiceRecordRepository = DefaultVoiceRecordRepository(
            audioService: audioService,
            storageService: storageService
        )
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
                  let sttPermissionRepository,
                  let languageRepository,
                  let folderRepository,
                  let voiceRecordRepository
            else {
                throw NSError(domain: "의존성 생성에 필요한 리포지토리가 없습니다.", code: -2)
            }

            dependency = DefaultSandboxDependency(
                checkFirstLaunchUseCase: DefaultCheckFirstLaunchUseCase(
                    repository: checkFirstLaunchRepository
                ),
                checkMicrophonePermissionUseCase: DefaultCheckMicrophonePermissionUseCase(
                    repository: voiceRecordRepository
                ),
                checkSTTPermissionUseCase: DefaultCheckSTTPermissionUseCase(
                    repository: sttPermissionRepository
                ),
                requestMicrophonePermissionUseCase: DefaultRequestMicrophonePermissionUseCase(
                    repository: voiceRecordRepository
                ),
                requestSTTPermissionUseCase: DefaultRequestSTTPermissionUseCase(
                    repository: sttPermissionRepository
                ),
                fetchLanguageUseCase: DefaultFetchLanguageUseCase(repository: languageRepository),
                selectLanguageUseCase: DefaultSelectLanguageUseCase(repository: languageRepository),
                createFolderUseCase: DefaultCreateFolderUseCase(repository: folderRepository),
                readFolderUseCase: DefaultReadFolderUseCase(repository: folderRepository),
                updateFolderUseCase: DefaultUpdateFolderUseCase(repository: folderRepository),
                startRecordingUseCase: DefaultStartRecordingUseCase(recordingRepository: voiceRecordRepository),
                pauseRecordingUseCase: DefaultPauseRecordingUseCase(recordingRepository: voiceRecordRepository),
                resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: voiceRecordRepository)
            )
        } catch {
            AppLogger.error(error)
        }
    }
}
