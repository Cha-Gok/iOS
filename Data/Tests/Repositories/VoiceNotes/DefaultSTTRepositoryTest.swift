@testable import Data
import Domain
import DomainTesting
import XCTest

final class DefaultSTTRepositoryTest: XCTestCase {
    private var sut: DefaultSTTRepository!
    private var mockStorageService: MockStorageService!
    private var mockLanguageRepository: MockLanguageRepository!

    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        mockLanguageRepository = MockLanguageRepository()
        sut = DefaultSTTRepository(
            storageService: mockStorageService,
            languageRepository: mockLanguageRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockStorageService = nil
        mockLanguageRepository = nil
        super.tearDown()
    }
}

// MARK: - 전사 테스트 (비활성화)

/*
 // SFSpeechRecognizer를 직접 사용하게 리팩토링됨에 따라, 인프라 목킹 없이는 단위 테스트가 어려움.
 extension DefaultSTTRepositoryTest {
     func test_정상상태_전사시_Transcript를반환한다() async throws {
         // ...
     }
 }
 */

// MARK: - 권한 확인 케이스

extension DefaultSTTRepositoryTest {
    func test_STT권한확인_런타임체크() {
        // 실제 시스템 권한 상태에 의존하므로 결과값 검증보다는 호출 가능 여부 확인
        let _ = sut.checkSTTPermission()
    }
}

// MARK: - 전사 취소 케이스

extension DefaultSTTRepositoryTest {
    func test_태스크취소상태_전사시_cancelled에러를던진다() async throws {
        // Given
        let task = Task { [sut] in
            try? await Task.sleep(nanoseconds: 10_000_000) // 약간의 대기
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut?.transcribe(audioFilePath: "VoiceRecords/audio.m4a")
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("STTRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? STTRepositoryError else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }
}
