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

private let domainTestingTarget = Target.target(
    name: "DomainTesting",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).DomainTesting",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: [
        "Testing/Interfaces/Mocks/**/*.swift",
        "Testing/Entities/Stubs/**/*.swift"
    ],
    scripts: [
        .pre(
            tool: "swiftformat",
            arguments: ["--config", "../.swiftformat", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        )
    ],
    dependencies: [
        .target(name: "Domain"),
        .xctest
    ]
)

private let domainTestsTarget = Target.target(
    name: "DomainTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).DomainTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/UseCases/**/*.swift"],
    scripts: [
        .pre(
            tool: "swiftformat",
            arguments: ["--config", "../.swiftformat", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        )
    ],
    dependencies: [
        .target(name: "Domain"),
        .target(name: "DomainTesting"),
        .xctest
    ]
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
        domainTestingTarget,
        domainTestsTarget
    ],
    schemes: [
        domainScheme,
        domainTestsScheme
    ]
)
