import ProjectDescription
import ProjectDescriptionHelpers

private let domainScheme = Scheme.scheme(
    name: "Domain",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Domain")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("DomainTests"), parallelization: .disabled)
    ])
)

private let domainTestsScheme = Scheme.scheme(
    name: "DomainTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("DomainTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("DomainTests"), parallelization: .disabled)
    ])
)

private let domainTarget = Target.target(
    name: "Domain",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Domain",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Sources/**/*.swift"],
    scripts: [
        .pre(
            tool: "swiftformat",
            arguments: ["--config", "../.swiftformat", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        )
    ],
    dependencies: [
        .project(target: "Core", path: "../Core")
    ]
)

private let domainTestsTarget = Target.target(
    name: "DomainTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).DomainTests",
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
    dependencies: [.target(name: "Domain")]
)

let project = Project(
    name: "Domain",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        domainTarget,
        domainTestsTarget
    ],
    schemes: [
        domainScheme,
        domainTestsScheme
    ]
)
