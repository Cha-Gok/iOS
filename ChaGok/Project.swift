import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project

let project = Project(
    name: "ChaGok",
    options: .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    ),
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
    ],
    schemes: [
        appScheme,
        coreScheme,
        domainScheme,
        dataScheme,
        presentationScheme,
        appTestsScheme,
        coreTestsScheme,
        domainTestsScheme,
        dataTestsScheme,
        presentationTestsScheme,
    ]
)
