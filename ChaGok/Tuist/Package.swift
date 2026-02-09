// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "CasePaths": .framework,
            "CasePathsCore": .framework,
            "Clocks": .framework,
            "CombineSchedulers": .framework,
            "ComposableArchitecture": .framework,
            "ComposableArchitectureMacros": .framework,
            "ConcurrencyExtras": .framework,
            "CustomDump": .framework,
            "Dependencies": .framework,
            "DependenciesMacros": .framework,
            "IdentifiedCollections": .framework,
            "InternalCollectionsUtilities": .framework,
            "IssueReporting": .framework,
            "IssueReportingPackageSupport": .framework,
            "OrderedCollections": .framework,
            "Perception": .framework,
            "PerceptionCore": .framework,
            "PerceptionMacros": .framework,
            "Sharing": .framework,
            "SwiftNavigation": .framework,
            "SwiftUINavigation": .framework,
            "UIKitNavigation": .framework,
            "XCTestDynamicOverlay": .framework,
        ],
        targetSettings: [
            "ComposableArchitecture": .settings(base: [
                "OTHER_SWIFT_FLAGS": ["-module-alias", "Sharing=SwiftSharing"],
            ]),
            "Sharing": .settings(base: [
                "PRODUCT_NAME": "SwiftSharing",
                "OTHER_SWIFT_FLAGS": ["-module-alias", "Sharing=SwiftSharing"],
            ]),
        ]
    )
#endif

let package = Package(
    name: "ChaGok",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
    ]
)
