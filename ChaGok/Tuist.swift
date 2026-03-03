import ProjectDescription

let tuist = Tuist(
    fullHandle: "ChaGokChaGok/chagokchagok",
    project: .tuist(
        generationOptions: .options(
            enableCaching: true
        )
    )
)
