import ProjectDescription
import ProjectDescriptionHelpers

private let appScheme = Scheme.scheme(
    name: "App",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("App")],
        findImplicitDependencies: true
    ),
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
            "CFBundleShortVersionString": Plist.Value(stringLiteral: version),
            "CFBundleVersion": Plist.Value(stringLiteral: build),
            "UILaunchScreen": Plist.Value(
                dictionaryLiteral: (
                    "UIColorName", Plist.Value(stringLiteral: "")
                ),
                ("UIImageName", Plist.Value(stringLiteral: ""))
            )
        ]
    ),
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"],
    scripts: [
        .pre(tool: "swiftlint", arguments: [], name: "SwiftLint", basedOnDependencyAnalysis: false)
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
