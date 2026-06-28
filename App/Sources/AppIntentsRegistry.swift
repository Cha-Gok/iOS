import AppIntents
import Presentation

/// 메인 앱에서 Presentation 프레임워크의 AppIntent(LiveActivityIntent)를
/// 시스템이 인식할 수 있도록 등록합니다.
///
/// LiveActivityIntent는 메인 앱 프로세스에서 실행되므로,
/// 앱 타겟에서도 프레임워크의 Intent 메타데이터를 참조해야 합니다.
struct AppIntentsRegistry: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [PresentationAppIntents.self]
    }
}
