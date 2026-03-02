import ProjectDescription
import ProjectDescriptionHelpers

private let presentationScheme = Scheme.scheme(
    name: "Presentation",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Presentation")],
        findImplicitDependencies: true
    )
)

private let presentationTestsScheme = Scheme.scheme(
    name: "PresentationTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("PresentationTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("PresentationTests"), parallelization: .disabled)
    ])
)

private let presentationTarget = Target.target(
    name: "Presentation",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Presentation",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Sources/**/*.swift"],
    scripts: [
        .pre(tool: "swiftlint", arguments: ["--fix"], name: "SwiftLint", basedOnDependencyAnalysis: true)
    ],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain")
    ]
)

private let presentationTestsTarget = Target.target(
    name: "PresentationTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).PresentationTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    dependencies: [.target(name: "Presentation")]
)

let project = Project(
    name: "Presentation",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        presentationTarget,
        presentationTestsTarget
    ],
    schemes: [
        presentationScheme,
        presentationTestsScheme
    ]
)
