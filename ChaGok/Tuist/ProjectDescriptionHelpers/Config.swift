import ProjectDescription

public let bundleId = "com.yongms.ChaGokChaGok"
public let displayName = "차곡"
public let version = "1.0.0"
public let build = "1"
public let iOSVersion = "17.0"
public let deploymentTargets: DeploymentTargets = .iOS(iOSVersion)

public let settings: Settings = .settings(
    base: [
        "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: iOSVersion),
        "SWIFT_VERSION": "6.0",
        "PRODUCT_BUNDLE_DISPLAY_NAME": SettingValue(stringLiteral: displayName),
        "MARKETING_VERSION": SettingValue(stringLiteral: version),
        "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: build),
        // CI 시뮬레이터 빌드 시 Development Team 없이 빌드 가능
        "CODE_SIGN_IDENTITY": "",
        "CODE_SIGNING_REQUIRED": "NO",
    ],
    defaultSettings: .recommended
)
