import ProjectDescription
import ProjectDescriptionHelpers

private let presentationScheme = Scheme.scheme(
    name: "Presentation",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Presentation")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("PresentationTests"), parallelization: .disabled)
    ])
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
    destinations: [.iPhone],
    product: .framework,
    bundleId: "\(bundleId).Presentation",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(
        with: [
            "UIAppFonts": .array([
                "Pretendard-Bold.otf",
                "Pretendard-Medium.otf",
                "Pretendard-Regular.otf"
            ])
        ]
    ),
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain")
    ]
)

private let presentationTestsTarget = Target.target(
    name: "PresentationTests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "\(bundleId).PresentationTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift"],
    dependencies: [
        .target(name: "Presentation"),
        .project(target: "DomainTesting", path: "../Domain")
    ]
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
