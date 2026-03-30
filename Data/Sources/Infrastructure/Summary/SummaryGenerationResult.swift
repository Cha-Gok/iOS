import Core
import Foundation
import FoundationModels

@Generable
struct SummaryGenerationResult {
    let keywords: [String]
    let summary: String
}
