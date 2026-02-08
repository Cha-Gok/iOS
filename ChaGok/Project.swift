import ProjectDescription

// MARK: - Project Configuration

let bundleId = "com.yongms.ChaGok"
let displayName = "차곡"
let version = "1.0.0"
let build = "1"
let iOSVersion = "17.0"
let deploymentTargets: DeploymentTargets = .iOS(iOSVersion)

let settings: Settings = .settings(
    base: [
        "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: iOSVersion),
        "SWIFT_VERSION": "6.0",
        "PRODUCT_BUNDLE_DISPLAY_NAME": SettingValue(stringLiteral: displayName),
        "MARKETING_VERSION": SettingValue(stringLiteral: version),
        "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: build),
    ],
    defaultSettings: .recommended
)

// MARK: - Targets

let appTarget = ProjectDescription.Target.target(
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
        .pre(
            tool: "swiftformat",
            arguments: ["--lint", "."],
            name: "SwiftFormat",
            basedOnDependencyAnalysis: false
        ),
    ],
    dependencies: [
        .target(name: "Presentation"),
        .target(name: "Data"),
    ],
    settings: settings
)

let coreTarget = ProjectDescription.Target.target(
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

let domainTarget = ProjectDescription.Target.target(
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

let dataTarget = ProjectDescription.Target.target(
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

let presentationTarget = ProjectDescription.Target.target(
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
    ]
)

let appTestsTarget = ProjectDescription.Target.target(
    name: "ChaGokTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(bundleId)Tests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "App/Tests",
    ],
    dependencies: [.target(name: "App")]
)

let coreTestsTarget = ProjectDescription.Target.target(
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

let domainTestsTarget = ProjectDescription.Target.target(
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

let dataTestsTarget = ProjectDescription.Target.target(
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

let presentationTestsTarget = ProjectDescription.Target.target(
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

// MARK: - Project

let project = Project(
    name: "ChaGok",
    settings: settings,
    targets: [
        appTarget,
        coreTarget,
        domainTarget,
        dataTarget,
        presentationTarget,
        appTestsTarget,
        coreTestsTarget,
        domainTestsTarget,
        dataTestsTarget,
        presentationTestsTarget,
    ]
)
