import ProjectDescription
import ProjectDescriptionHelpers

private let dataScheme = Scheme.scheme(
    name: "Data",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Data")],
        findImplicitDependencies: true
    )
)

private let dataTestsScheme = Scheme.scheme(
    name: "DataTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("DataTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("DataTests"), parallelization: .disabled)
    ])
)

private let dataTarget = Target.target(
    name: "Data",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Data",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Sources/**/*.swift"],
    scripts: [
        .pre(tool: "swiftlint", arguments: ["--fix"], name: "SwiftLint", basedOnDependencyAnalysis: false)
    ],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain")
    ]
)

private let dataTestsTarget = Target.target(
    name: "DataTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).DataTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    dependencies: [.target(name: "Data")]
)

let project = Project(
    name: "Data",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        dataTarget,
        dataTestsTarget
    ],
    schemes: [
        dataScheme,
        dataTestsScheme
    ]
)
