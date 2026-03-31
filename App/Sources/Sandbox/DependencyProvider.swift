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
    private var summaryService: SummaryService?
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
        summaryService = AppleFoundationSummaryService()
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
                  let voiceRecordRepository,
                  let summaryService
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
                resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: voiceRecordRepository),
                finishRecordingUseCase: DefaultFinishRecordingUseCase(recordingRepository: voiceRecordRepository),
                runSummarySandbox: {
                    let result = try await summaryService.summarize(text: """
                    오늘 제품 회의에서는 음성 녹음을 텍스트로 변환한 뒤 핵심 내용을 자동으로 요약하고,
                    검색 가능한 키워드를 함께 추출하는 기능을 우선 개발하기로 결정했다.
                    현재 사용자 인터뷰를 보면 회의나 아이디어 메모를 길게 남겨도 다시 찾아보기가 어렵고,
                    녹음 파일 제목만으로는 내용을 파악하기 힘들다는 의견이 많았다.
                    그래서 사용자가 녹음을 종료하면 전사 결과를 먼저 만들고,
                    그 전사문을 바탕으로 두세 문장 정도의 짧은 요약과 핵심 키워드 여러 개를 보여주는 흐름을 제안했다.

                    디자이너는 결과 화면에서 요약이 가장 먼저 보이고,
                    그 아래에 키워드를 태그 형태로 배치하면 정보 구조가 더 직관적일 것이라고 말했다.
                    또한 사용자가 키워드를 눌렀을 때 관련 노트를 모아서 볼 수 있으면 검색 경험이 좋아질 것이라고 덧붙였다.
                    개발 측에서는 요약 품질이 일정하지 않을 수 있기 때문에
                    사용자가 직접 요약 텍스트를 수정하거나 키워드를 편집할 수 있어야 한다는 의견을 냈다.
                    특히 한국어와 영어가 섞인 회의록,
                    문장이 길고 반복이 많은 인터뷰 전사문,
                    그리고 도메인 용어가 자주 등장하는 업무 회의에서 결과 품질을 반드시 확인해야 한다고 정리했다.

                    백엔드와 서버 비용을 최소화하려는 방향 때문에
                    가능한 경우 온디바이스 모델을 우선 사용하고,
                    실패하거나 지원되지 않는 환경에서는 대체 경로를 고려하기로 했다.
                    다만 첫 번째 목표는 기술 검증이기 때문에
                    이번 스프린트에서는 우선 샌드박스 화면에서 샘플 텍스트를 넣어 요약과 키워드 결과가 어떻게 나오는지 빠르게 확인하고,
                    이후 실제 녹음 파일 전사 결과를 연결하기로 했다.
                    QA 측에서는 너무 짧은 메모, 지나치게 긴 회의록, 잡담이 많은 음성,
                    그리고 명확한 주제가 없는 자유 발화 같은 케이스도 함께 점검해야 한다고 제안했다.

                    최종적으로 이번 스프린트의 목표는 세 가지로 정리되었다.
                    첫째, 전사문으로부터 사용자가 읽기 쉬운 요약이 안정적으로 생성되는지 확인한다.
                    둘째, 검색과 분류에 실제로 도움이 되는 키워드가 추출되는지 평가한다.
                    셋째, 결과가 앱의 폴더 구조 및 노트 저장 흐름과 자연스럽게 연결되는지 검증한다.
                    다음 주 중간 점검에서는 요약 결과의 언어 일관성,
                    키워드 중복 여부,
                    처리 속도,
                    그리고 사용자가 결과를 신뢰할 수 있는 표현으로 보여지는지까지 함께 리뷰하기로 했다.
                    """, language: .ko)

                    return """
                    keywords:
                    \(result.keywords.joined(separator: ", "))

                    summary:
                    \(result.summary)
                    """
                }
            )
        } catch {
            AppLogger.error(error)
        }
    }
}
