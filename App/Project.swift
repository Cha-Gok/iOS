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
    destinations: .iOS,
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
            "NSSpeechRecognitionUsageDescription": "음성을 텍스트로 변환하기 위해 음성 인식 권한이 필요합니다.",
            "ITSAppUsesNonExemptEncryption": false
        ]
    ),
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"],
    scripts: [
        .pre(
            tool: "swiftformat",
            arguments: ["--config", "../.swiftformat", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        )
    ],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Presentation", path: "../Presentation"),
        .project(target: "Data", path: "../Data")
    ],
    settings: settings
)

private let appTestsTarget = Target.target(
    name: "AppTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).AppTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    scripts: [
        .pre(
            tool: "swiftformat",
            arguments: ["--config", "../.swiftformat", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        )
    ],
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
