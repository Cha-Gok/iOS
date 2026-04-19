@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultSummaryRepositoryTest: XCTestCase {
    private var sut: DefaultSummaryRepository!

    override func setUp() {
        super.setUp()
        sut = DefaultSummaryRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

// MARK: - 요약 테스트 (비활성화)

/*
 // LanguageModelSession을 직접 사용하게 리팩토링됨에 따라, 인프라 목킹 없이는 단위 테스트가 어려움.
 extension DefaultSummaryRepositoryTest {
     func test_정상상태_요약시_도메인엔티티로변환하여반환한다() async throws {
         // ...
     }
 }
 */

// MARK: - 취소 케이스

extension DefaultSummaryRepositoryTest {
    func test_태스크취소상태_요약시_cancelled에러를던진다() async throws {
        // Given
        let task = Task { [sut] in
            try? await Task.sleep(nanoseconds: 10_000_000)
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut?.summarize(
                transcript: Domain.Transcript(id: UUID(), sections: [TranscriptSection(timestamp: 0, text: "텍스트")]),
                language: .ko
            )
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("SummaryRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? SummaryRepositoryError else {
                return XCTFail("예상한 에러는 SummaryRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}
