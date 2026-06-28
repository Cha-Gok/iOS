import AppIntents
import Presentation

/// Widget Extension에서 Presentation 프레임워크의 AppIntent(LiveActivityIntent)를
/// 시스템이 인식할 수 있도록 등록합니다.
///
/// `includedPackages`를 통해 Presentation 프레임워크의 `PresentationAppIntents`를 참조하여,
/// 빌드 시스템이 프레임워크 내 ToggleRecordingIntent의 메타데이터를 이 Extension에도 연결합니다.
struct ChaGokWidgetAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [PresentationAppIntents.self]
    }
}
