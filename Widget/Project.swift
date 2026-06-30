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
    ],
    settings: .settings(
        base: [
            "CODE_SIGN_IDENTITY": "Apple Development",
            "PROVISIONING_PROFILE_SPECIFIER": "match Development com.yongms.ChaGokChaGok.widget"
        ],
        configurations: [
            .debug(name: "Debug", settings: [
                "CODE_SIGN_IDENTITY": "Apple Development",
                "PROVISIONING_PROFILE_SPECIFIER": "match Development com.yongms.ChaGokChaGok.widget"
            ]),
            .release(name: "Release", settings: [
                "CODE_SIGN_IDENTITY": "Apple Distribution",
                "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.yongms.ChaGokChaGok.widget"
            ])
        ],
        defaultSettings: .recommended
    )
)

private let widgetTestsTarget = Target.target(
    name: "ChaGokWidgetTests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "\(bundleId).widgetTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: [
        "Tests/**/*.swift",
        "Sources/**/*.swift",
        "!Sources/WidgetBundle.swift"
    ],
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
