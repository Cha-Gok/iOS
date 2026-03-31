#if canImport(FoundationModels)
    import FoundationModels

    @Generable
    struct SummaryGenerationResult {
        let keywords: [String]
        let summary: String
    }
#endif
