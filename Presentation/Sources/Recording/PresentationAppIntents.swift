import AppIntents

/// Presentation 프레임워크에 정의된 AppIntent(LiveActivityIntent 포함)를
/// 시스템이 자동으로 검색할 수 있도록 등록합니다.
///
/// AppIntent가 별도 프레임워크 모듈에 정의된 경우,
/// 시스템의 메타데이터 추출(metadata extraction) 단계에서 해당 Intent를 발견하지 못합니다.
/// `AppIntentsPackage`를 구현하면 빌드 시스템이 이 모듈의 Intent를 인식하고 등록합니다.
public struct PresentationAppIntents: AppIntentsPackage {}
