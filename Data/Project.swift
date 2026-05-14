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

private let dataTarget = Target.target(
    name: "Data",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Data",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain"),
        .external(name: "ArgmaxOSS")
    ]
)

let project = Project(
    name: "Data",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
    settings: settings,
    targets: [
        dataTarget
    ],
    schemes: [
        dataScheme
    ]
)
