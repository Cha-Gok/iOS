import ProjectDescription
import ProjectDescriptionHelpers

private let appScheme = Scheme.scheme(
    name: "App",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("App")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("AppTests"), parallelization: .disabled)
    ]),
    runAction: .runAction(executable: .target("App"))
)

private let appTestsScheme = Scheme.scheme(
    name: "AppTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("AppTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("AppTests"), parallelization: .disabled)
    ])
)

private let appTarget = Target.target(
    name: "App",
    destinations: [.iPhone],
    product: .app,
    bundleId: bundleId,
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": Plist.Value(stringLiteral: displayName),
            "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
            "UILaunchScreen": Plist.Value(
                dictionaryLiteral: (
                    "UIColorName", Plist.Value(stringLiteral: "")
                ),
                ("UIImageName", Plist.Value(stringLiteral: ""))
            ),
            "UIUserInterfaceStyle": Plist.Value(stringLiteral: style),
            "NSMicrophoneUsageDescription": "음성 메모를 녹음하기 위해 마이크 권한이 필요합니다.",
            "ITSAppUsesNonExemptEncryption": false,
            "UIBackgroundModes": ["audio"]
        ]
    ),
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"],
    entitlements: .dictionary([
        "com.apple.developer.kernel.increased-memory-limit": .boolean(true),
        "com.apple.developer.kernel.extended-virtual-addressing": .boolean(true)
    ]),
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Presentation", path: "../Presentation"),
        .project(target: "Data", path: "../Data")
    ],
    settings: .settings(
        base: ["ASSETCATALOG_COMPILER_APPICON_NAME": "ChaGok"],
        configurations: [
            .debug(name: "Debug", settings: [
                "CODE_SIGN_IDENTITY": "Apple Development",
                "PROVISIONING_PROFILE_SPECIFIER": "match Development com.yongms.ChaGokChaGok"
            ]),
            .release(name: "Release", settings: [
                "CODE_SIGN_IDENTITY": "Apple Distribution",
                "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.yongms.ChaGokChaGok"
            ])
        ],
        defaultSettings: .recommended
    )
)

private let appTestsTarget = Target.target(
    name: "AppTests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "\(bundleId).AppTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    dependencies: [.target(name: "App")]
)

let project = Project(
    name: "App",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        appTarget,
        appTestsTarget
    ],
    schemes: [
        appScheme,
        appTestsScheme
    ]
)
