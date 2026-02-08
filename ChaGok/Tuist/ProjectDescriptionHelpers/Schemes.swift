import ProjectDescription

// MARK: - 빌드/실행용

public let appScheme = Scheme.scheme(
    name: "App",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("App")],
        findImplicitDependencies: true
    ),
    runAction: .runAction(executable: .target("App"))
)

public let coreScheme = Scheme.scheme(
    name: "Core",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Core")],
        findImplicitDependencies: true
    )
)

public let domainScheme = Scheme.scheme(
    name: "Domain",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Domain")],
        findImplicitDependencies: true
    )
)

public let dataScheme = Scheme.scheme(
    name: "Data",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Data")],
        findImplicitDependencies: true
    )
)

public let presentationScheme = Scheme.scheme(
    name: "Presentation",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("Presentation")],
        findImplicitDependencies: true
    )
)

// MARK: - 테스트 전용

public let appTestsScheme = Scheme.scheme(
    name: "AppTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("AppTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("AppTests"), parallelization: .disabled),
    ])
)

public let coreTestsScheme = Scheme.scheme(
    name: "CoreTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("CoreTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("CoreTests"), parallelization: .disabled),
    ])
)

public let domainTestsScheme = Scheme.scheme(
    name: "DomainTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("DomainTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("DomainTests"), parallelization: .disabled),
    ])
)

public let dataTestsScheme = Scheme.scheme(
    name: "DataTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("DataTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("DataTests"), parallelization: .disabled),
    ])
)

public let presentationTestsScheme = Scheme.scheme(
    name: "PresentationTests",
    shared: true,
    buildAction: .buildAction(
        targets: [.target("PresentationTests")],
        findImplicitDependencies: true
    ),
    testAction: .targets([
        .testableTarget(target: .target("PresentationTests"), parallelization: .disabled),
    ])
)
