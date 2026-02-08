import ProjectDescription

// MARK: - App

public let appTarget = ProjectDescription.Target.target(
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
            ),
        ]
    ),
    buildableFolders: [
        "App/Sources",
        "App/Resources",
    ],
    scripts: [
        .pre(tool: "swiftlint", arguments: [], name: "SwiftLint", basedOnDependencyAnalysis: false),
    ],
    dependencies: [
        .target(name: "Presentation"),
        .target(name: "Data"),
    ],
    settings: settings
)

// MARK: - Core

public let coreTarget = ProjectDescription.Target.target(
    name: "Core",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Core",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Core/Sources",
    ],
    dependencies: []
)

// MARK: - Domain

public let domainTarget = ProjectDescription.Target.target(
    name: "Domain",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Domain",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Domain/Sources",
    ],
    dependencies: [
        .target(name: "Core"),
    ]
)

// MARK: - Data

public let dataTarget = ProjectDescription.Target.target(
    name: "Data",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Data",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Data/Sources",
    ],
    dependencies: [
        .target(name: "Domain"),
    ]
)

// MARK: - Presentation

public let presentationTarget = ProjectDescription.Target.target(
    name: "Presentation",
    destinations: .iOS,
    product: .framework,
    bundleId: "\(bundleId).Presentation",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Presentation/Sources",
    ],
    dependencies: [
        .target(name: "Domain"),
        .external(name: "ComposableArchitecture"),
    ],
)

// MARK: - AppTests

public let appTestsTarget = ProjectDescription.Target.target(
    name: "AppTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).AppTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "App/Tests",
    ],
    dependencies: [.target(name: "App")]
)

// MARK: - CoreTests

public let coreTestsTarget = ProjectDescription.Target.target(
    name: "CoreTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).CoreTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Core/Tests",
    ],
    dependencies: [.target(name: "Core")]
)

// MARK: - DomainTests

public let domainTestsTarget = ProjectDescription.Target.target(
    name: "DomainTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).DomainTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Domain/Tests",
    ],
    dependencies: [.target(name: "Domain")]
)

// MARK: - DataTests

public let dataTestsTarget = ProjectDescription.Target.target(
    name: "DataTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).DataTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Data/Tests",
    ],
    dependencies: [.target(name: "Data")]
)

// MARK: - PresentationTests

public let presentationTestsTarget = ProjectDescription.Target.target(
    name: "PresentationTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId).PresentationTests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "Presentation/Tests",
    ],
    dependencies: [.target(name: "Presentation")]
)
