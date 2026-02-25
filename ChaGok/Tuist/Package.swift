// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            // 필요한 경우 여기에 제품 유형을 추가하세요.
        ],
        targetSettings: [
            // 필요한 경우 여기에 타겟 설정을 추가하세요.
        ]
    )
#endif

let package = Package(
    name: "ChaGok",
    dependencies: [
        // .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
    ]
)
