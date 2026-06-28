import ProjectDescription
import ProjectDescriptionHelpers

private let widgetScheme = Scheme.scheme(
    name: "ChaGokWidget",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("ChaGokWidget")],
        findImplicitDependencies: true
    )
)

private let widgetTestsScheme = Scheme.scheme(
    name: "ChaGokWidgetTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("ChaGokWidgetTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("ChaGokWidgetTests"), parallelization: .disabled)
    ])
)

private let widgetTarget = Target.target(
    name: "ChaGokWidget",
    destinations: [.iPhone],
    product: .appExtension,
    bundleId: "\(bundleId).widget",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": "ChaGokWidget",
            "NSSupportsLiveActivities": true,
            "NSExtension": [
                "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
            ]
        ]
    ),
    sources: ["Sources/**/*.swift"],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Presentation", path: "../Presentation")
    ]
)

private let widgetTestsTarget = Target.target(
    name: "ChaGokWidgetTests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "\(bundleId).widgetTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Tests/**/*.swift", "Sources/RecordingActivityWidget.swift"], // @main이 선언된 WidgetBundle.swift는 컴파일에서 제외
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Presentation", path: "../Presentation")
    ]
)

let project = Project(
    name: "Widget",
    settings: settings,
    targets: [
        widgetTarget,
        widgetTestsTarget
    ],
    schemes: [
        widgetScheme,
        widgetTestsScheme
    ]
)
