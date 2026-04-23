#if canImport(FoundationModels)
    import FoundationModels

    @Generable
    struct SummaryGenerationResult {
        let keywords: [String]

        @Guide(description: "핵심 포인트 목록", .minimumCount(1), .maximumCount(3))
        let keyPoints: [String]
    }
#endif
