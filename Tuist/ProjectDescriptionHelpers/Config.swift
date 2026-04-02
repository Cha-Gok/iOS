import ProjectDescription

public let bundleId = "com.yongms.ChaGokChaGok"
public let displayName = "차곡"
public let version = "1.0.0"
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
        // CI 시뮬레이터 빌드 시 Development Team 없이 빌드 가능
        "CODE_SIGN_IDENTITY": "",
        "CODE_SIGNING_REQUIRED": "NO",
        // 에셋 카탈로그 → Swift 심볼 자동 생성 (타입 세이프 접근)
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        // String Catalog → Swift 심볼 생성 (Xcode "Enable String Catalog Symbol Generation")
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
        // Apple Clang Module Verifier (Xcode "Target 'Core' - Enable Module Verifier")
        "ENABLE_MODULE_VERIFIER": "YES",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14",
        // Run Script가 정상 동작하도록 User Script Sandboxing 비활성화
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO"
    ],
    defaultSettings: .recommended
)
