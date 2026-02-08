import ProjectDescription

let project = Project(
    name: "ChaGok",
    targets: [
        .target(
            name: "ChaGok",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.ChaGok",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "ChaGok/Sources",
                "ChaGok/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "ChaGokTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.ChaGokTests",
            infoPlist: .default,
            buildableFolders: [
                "ChaGok/Tests"
            ],
            dependencies: [.target(name: "ChaGok")]
        ),
    ]
)
