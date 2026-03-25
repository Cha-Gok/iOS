import Data
import Domain
import Presentation

actor DefaultSandboxDependency: SandboxDependency {
    // Authority
    let checkFirstLaunchUseCase: any CheckFirstLaunchUseCase
    let checkMicrophonePermissionUseCase: any CheckMicrophonePermissionUseCase
    let checkSTTPermissionUseCase: any CheckSTTPermissionUseCase
    let requestMicrophonePermissionUseCase: any RequestMicrophonePermissionUseCase
    let requestSTTPermissionUseCase: any RequestSTTPermissionUseCase
    // Language
    let fetchLanguageUseCase: any FetchLanguageUseCase
    let selectLanguageUseCase: any SelectLanguageUseCase
    // Folder
    let createFolderUseCase: any Domain.CreateFolderUseCase
    let readFolderUseCase: any Domain.ReadFolderUseCase
    let updateFolderUseCase: any Domain.UpdateFolderUseCase
    // Recording
    let startRecordingUseCase: any Domain.StartRecordingUseCase
    let pauseRecordingUseCase: any Domain.PauseRecordingUseCase
    let resumeRecordingUseCase: any Domain.ResumeRecordingUseCase

    init(
        checkFirstLaunchUseCase: any CheckFirstLaunchUseCase,
        checkMicrophonePermissionUseCase: any CheckMicrophonePermissionUseCase,
        checkSTTPermissionUseCase: any CheckSTTPermissionUseCase,
        requestMicrophonePermissionUseCase: any RequestMicrophonePermissionUseCase,
        requestSTTPermissionUseCase: any RequestSTTPermissionUseCase,
        fetchLanguageUseCase: any FetchLanguageUseCase,
        selectLanguageUseCase: any SelectLanguageUseCase,
        createFolderUseCase: any Domain.CreateFolderUseCase,
        readFolderUseCase: any Domain.ReadFolderUseCase,
        updateFolderUseCase: any Domain.UpdateFolderUseCase,
        startRecordingUseCase: any Domain.StartRecordingUseCase,
        pauseRecordingUseCase: any Domain.PauseRecordingUseCase,
        resumeRecordingUseCase: any Domain.ResumeRecordingUseCase
    ) {
        self.checkFirstLaunchUseCase = checkFirstLaunchUseCase
        self.checkMicrophonePermissionUseCase = checkMicrophonePermissionUseCase
        self.checkSTTPermissionUseCase = checkSTTPermissionUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.requestSTTPermissionUseCase = requestSTTPermissionUseCase
        self.fetchLanguageUseCase = fetchLanguageUseCase
        self.selectLanguageUseCase = selectLanguageUseCase
        self.createFolderUseCase = createFolderUseCase
        self.readFolderUseCase = readFolderUseCase
        self.updateFolderUseCase = updateFolderUseCase
        self.startRecordingUseCase = startRecordingUseCase
        self.pauseRecordingUseCase = pauseRecordingUseCase
        self.resumeRecordingUseCase = resumeRecordingUseCase
    }
}
