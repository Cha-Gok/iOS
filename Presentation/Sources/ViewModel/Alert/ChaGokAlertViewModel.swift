import Domain
import Foundation

@MainActor
public protocol ChaGokAlertCoordinatorDelegate: AnyObject {
    /// Open Alert
    func presentAlert(
        environment: ChaGokAlertViewModel.AlertEnvironment,
        delegate: ChaGokAlertButtonTappedDelegate?
    )
}

public extension ChaGokAlertCoordinatorDelegate {
    func presentAlert(environment: ChaGokAlertViewModel.AlertEnvironment) {
        presentAlert(environment: environment, delegate: nil)
    }
}

@MainActor
@objc
public protocol ChaGokAlertButtonTappedDelegate: AnyObject {
    /// mic Permission Action
    @objc
    optional func micPermissionCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func micPermissionPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)
    /// recordingCancel Action
    @objc
    optional func recordingCancelCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func recordingCancelPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// recordingComplete Action
    @objc
    optional func recordingCompleteCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func recordingCompletePrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// languageSelect Action
    @objc
    optional func languageSelectCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func languageSelectPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// createFolder Action
    @objc
    optional func createFolderCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func createFolderPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// updateFolder Action
    @objc
    optional func updateFolderCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func updateFolderPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// moveTrash Action
    @objc
    optional func moveTrashCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func moveTrashPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)

    /// Trash Delete Action
    @objc
    optional func deleteAllTrashCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func deleteAllTrashPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func deleteItemsTrashCloseButonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func deleteItemsTrashPrimaryButonTapped(_ alertVC: ChaGokAlertViewController)

    /// none Action
    @objc
    optional func noneCloseButtonTapped(_ alertVC: ChaGokAlertViewController)
    @objc
    optional func nonePrimaryButtonTapped(_ alertVC: ChaGokAlertViewController)
}

@MainActor
@Observable
public final class ChaGokAlertViewModel {
    private(set) var environment: AlertEnvironment
    private(set) var state: AlertState
    private(set) var selectedLanguage: Language?

    public init(environment: AlertEnvironment = .none) {
        self.environment = environment
        state = environment.state
    }

    public convenience init(state: AlertState) {
        self.init(environment: .none)
        self.state = state
    }

    @ObservationIgnored
    public var header: Header {
        state.header
    }

    @ObservationIgnored
    public var style: BodyStyle {
        state.bodyStyle
    }

    public weak var coordinator: ChaGokAlertCoordinatorDelegate?
}

// MARK: - Action

extension ChaGokAlertViewModel {
    public func update(environment: AlertEnvironment) {
        self.environment = environment
        state = environment.state
    }

    func didTapCancel(delegate: ChaGokAlertButtonTappedDelegate?, alertVC: ChaGokAlertViewController) {
        switch environment {
        case .micPermissionRequired:
            delegate?.micPermissionCloseButtonTapped?(alertVC)
        case .recordingCancel:
            delegate?.recordingCancelCloseButtonTapped?(alertVC)
        case .recordingComplete:
            delegate?.recordingCompleteCloseButtonTapped?(alertVC)
        case .languageSelect:
            delegate?.languageSelectCloseButtonTapped?(alertVC)
        case .createFolder:
            delegate?.createFolderCloseButtonTapped?(alertVC)
        case .updateFolder:
            delegate?.updateFolderCloseButtonTapped?(alertVC)
        case .moveTrash:
            delegate?.moveTrashCloseButtonTapped?(alertVC)
        case .deleteAllTrash:
            delegate?.deleteAllTrashCloseButtonTapped?(alertVC)
        case .deleteItemsTrash:
            delegate?.deleteItemsTrashCloseButonTapped?(alertVC)
        case .none:
            delegate?.noneCloseButtonTapped?(alertVC)
        }
    }

    func didTapPrimary(delegate: ChaGokAlertButtonTappedDelegate?, alertVC: ChaGokAlertViewController) {
        switch environment {
        case .micPermissionRequired:
            delegate?.micPermissionPrimaryButtonTapped?(alertVC)
        case .recordingCancel:
            delegate?.recordingCancelPrimaryButtonTapped?(alertVC)
        case .recordingComplete:
            delegate?.recordingCompletePrimaryButtonTapped?(alertVC)
        case .languageSelect:
            delegate?.languageSelectPrimaryButtonTapped?(alertVC)
        case .createFolder:
            delegate?.createFolderPrimaryButtonTapped?(alertVC)
        case .updateFolder:
            delegate?.updateFolderPrimaryButtonTapped?(alertVC)
        case .moveTrash:
            delegate?.moveTrashPrimaryButtonTapped?(alertVC)
        case .deleteAllTrash:
            delegate?.deleteAllTrashPrimaryButtonTapped?(alertVC)
        case .deleteItemsTrash:
            delegate?.deleteItemsTrashPrimaryButonTapped?(alertVC)
        case .none:
            delegate?.nonePrimaryButtonTapped?(alertVC)
        }
    }

    func setSelectedLanguage(_ language: Language) {
        selectedLanguage = language
    }
}

// MARK: - Alert Model

public extension ChaGokAlertViewModel {
    struct Header: Equatable {
        let title: String

        init(title: String) {
            self.title = title
        }
    }

    enum BodyStyle {
        case basic(subTitle: String)
        case languagePicker(Language)
        case textField(field: TextFieldView.Field, subTitle: String)
    }

    enum ButtonType {
        case close
        case `default`
        case primary
        case danger
    }

    struct ButtonStyle {
        let type: ButtonType
        let text: String
    }

    struct AlertState {
        let header: Header
        let bodyStyle: BodyStyle
        let cancelButtonStyle: ButtonStyle
        let primaryButtonStyle: ButtonStyle

        init(header: Header, bodyStyle: BodyStyle, cancelButtonStyle: ButtonStyle, primaryButtonStyle: ButtonStyle) {
            self.header = header
            self.bodyStyle = bodyStyle
            self.cancelButtonStyle = cancelButtonStyle
            self.primaryButtonStyle = primaryButtonStyle
        }
    }

    @MainActor
    enum AlertEnvironment {
        case micPermissionRequired
        case recordingCancel
        case recordingComplete
        case languageSelect(Language)
        case createFolder(TextFieldView.Field)
        case updateFolder(TextFieldView.Field)
        case moveTrash
        case deleteAllTrash
        case deleteItemsTrash
        case none

        var state: AlertState {
            switch self {
            case .micPermissionRequired:
                AlertState(
                    header: .init(title: "마이크 권한이 필요해요"),
                    bodyStyle: .basic(subTitle: "설정에서 마이크 권한을\n허용해주세요."),
                    cancelButtonStyle: .init(type: .close, text: "나중에"),
                    primaryButtonStyle: .init(type: .primary, text: "설정으로 이동")
                )
            case .recordingCancel:
                AlertState(
                    header: .init(
                        title: "녹음을 취소할까요?"
                    ),
                    bodyStyle: .basic(subTitle: "지금까지 녹음한 내용은\n저장되지 않아요."),
                    cancelButtonStyle: .init(type: .close, text: "계속 녹음"),
                    primaryButtonStyle: .init(type: .danger, text: "녹음 취소")
                )
            case .recordingComplete:
                AlertState(
                    header: .init(
                        title: "녹음을 저장하고 종료할까요?"
                    ),
                    bodyStyle: .basic(subTitle: "지금까지 녹음한 내용이\n기록됩니다."),
                    cancelButtonStyle: .init(type: .close, text: "아니오"),
                    primaryButtonStyle: .init(type: .primary, text: "저장 후 종료")
                )
            case .languageSelect(let selectedLanguage):
                AlertState(
                    header: .init(title: "녹음 언어 변경"),
                    bodyStyle: .languagePicker(selectedLanguage),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .primary, text: "저장하기")
                )
            case .createFolder(let field):
                AlertState(
                    header: .init(
                        title: "새 폴더"
                    ),
                    bodyStyle: .textField(field: field, subTitle: "새로 만들 폴더의 이름을\n입력해주세요."),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .primary, text: "만들기")
                )
            case .updateFolder(let field):
                AlertState(
                    header: .init(
                        title: "폴더 이름 수정"
                    ),
                    bodyStyle: .textField(field: field, subTitle: "수정 할 폴더의 이름을 입력해주세요"),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .primary, text: "수정하기")
                )
            case .moveTrash:
                AlertState(
                    header: .init(
                        title: "기록을 삭제할까요?"
                    ),
                    bodyStyle: .basic(subTitle: "휴지통으로 이동되며,\n직접 비우기 전까지 보관돼요."),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .danger, text: "삭제")
                )
            case .deleteAllTrash:
                AlertState(
                    header: .init(
                        title: "휴지통을 비울까요?"
                    ),
                    bodyStyle: .basic(subTitle: "모든 파일이 영구 삭제되며\n되돌릴 수 없어요"),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .danger, text: "비우기")
                )
            case .deleteItemsTrash:
                AlertState(
                    header: .init(
                        title: "선택한 항목을 삭제할까요?"
                    ),
                    bodyStyle: .basic(subTitle: "선택한 항목이 영구 삭제되며\n되돌릴 수 없어요"),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .danger, text: "삭제하기")
                )
            case .none:
                AlertState(
                    header: .init(title: ""),
                    bodyStyle: .basic(subTitle: ""),
                    cancelButtonStyle: .init(type: .close, text: "취소"),
                    primaryButtonStyle: .init(type: .primary, text: "저장하기")
                )
            }
        }
    }
}
