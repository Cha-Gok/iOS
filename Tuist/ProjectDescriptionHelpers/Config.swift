import ProjectDescription

public let bundleId = "com.yongms.ChaGokChaGok"
public let displayName = "차곡"
public let version = "1.1.0"
public let build = "1"
public let iOSVersion = "26.0"
public let deploymentTargets: DeploymentTargets = .iOS(iOSVersion)
public let style = "Dark"

public let settings: Settings = .settings(
    base: [
        "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: iOSVersion),
        "SWIFT_VERSION": "6.0",
        "PRODUCT_BUNDLE_DISPLAY_NAME": SettingValue(stringLiteral: displayName),
        "MARKETING_VERSION": SettingValue(stringLiteral: version),
        "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: build),
        // iPhone 전용 앱 (iPad 아이콘 불필요)
        "TARGETED_DEVICE_FAMILY": "1",
        // 실제 기기 빌드를 위한 사이닝 설정
        "DEVELOPMENT_TEAM": "78QTJM9AD7",
        "CODE_SIGN_STYLE": "Manual",
        "CODE_SIGNING_REQUIRED": "YES",
        "CODE_SIGNING_ALLOWED": "YES",
        // 에셋 카탈로그 → Swift 심볼 자동 생성 (타입 세이프 접근)
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        // String Catalog → Swift 심볼 생성 (Xcode "Enable String Catalog Symbol Generation")
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
        // Module Verifier는 순수 Swift 프레임워크에서 Obj-C 검증 실패를 유발하므로 비활성화
        "ENABLE_MODULE_VERIFIER": "NO",
        // Run Script가 정상 동작하도록 User Script Sandboxing 비활성화
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO"
    ],
    defaultSettings: .recommended
)
