import ProjectDescription
import ProjectDescriptionHelpers

private let coreScheme = Scheme.scheme(
    name: "Core",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Core")],
        findImplicitDependencies: true
    )
)

private let coreTestsScheme = Scheme.scheme(
    name: "CoreTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("CoreTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("CoreTests"), parallelization: .disabled)
    ])
)

private let coreTarget = Target.target(
    name: "Core",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Core",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Sources/**/*.swift"],
    scripts: [
        .pre(
            tool: "swiftlint",
            arguments: ["--fix"],
            name: "SwiftLint",
            inputPaths: ["Sources/**/*.swift"],
            outputPaths: ["$(DERIVED_FILE_DIR)/swiftlint.stamp"],
            basedOnDependencyAnalysis: true
        )
    ],
    dependencies: []
)

private let coreTestsTarget = Target.target(
    name: "CoreTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).CoreTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    dependencies: [.target(name: "Core")]
)

let project = Project(
    name: "Core",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        coreTarget,
        coreTestsTarget
    ],
    schemes: [
        coreScheme,
        coreTestsScheme
    ]
)
