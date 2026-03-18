@testable import Domain
import Core
import XCTest

final class SelectLanguageUseCaseTest: XCTestCase {
    private var repository: MockLanguageRepository!
    private var sut: DefaultSelectLanguageUseCase!

    override func setUp() {
        super.setUp()
        repository = MockLanguageRepository()
        sut = DefaultSelectLanguageUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension SelectLanguageUseCaseTest {
    func test_정상상태_언어설정시_리포지토리의저장메서드를호출한다() async throws {
        // Given
        await repository.setSaveResult(.success(()))
        await repository.expectSave(language: .ko, callCount: 1)

        // When
        try await sut.execute(lang: .ko)

        // Then
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension SelectLanguageUseCaseTest {
    func test_리포지토리저장실패상태_언어설정시_saveFailed에러를던진다() async {
        // Given
        await repository.setSaveResult(.failure(.saveFailed))
        await repository.expectSave(language: .ko, callCount: 1)

        // When & Then
        do {
            try await sut.execute(lang: .ko)
            XCTFail("SetLanguagesUseCaseError.saveFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .saveFailed = error else {
                return XCTFail(
                    "예상한 에러는 SetLanguagesUseCaseError.saveFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_언어설정시_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        await repository.setSaveResult(.failure(.unknown(DummyError())))
        await repository.expectSave(language: .ko, callCount: 1)

        // When & Then
        do {
            try await sut.execute(lang: .ko)
            XCTFail("SetLanguagesUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let repoError) = error else {
                return XCTFail(
                    "예상한 에러는 SetLanguagesUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(repoError is DummyError)
        }
        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension SelectLanguageUseCaseTest {
    func test_조회중취소상태_언어설정시_cancelled에러를던진다() async {
        // Given
        await repository.setSaveResult(.failure(.cancelled))
        await repository.expectSave(language: .ko, callCount: 1)

        // When & Then
        do {
            try await sut.execute(lang: .ko)
            XCTFail("SetLanguagesUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 SetLanguagesUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_태스크이미취소상태_언어설정시_즉시cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut가 초기화되지 않았습니다.")
        }
        // Given
        await repository.setSaveResult(.success(()))
        await repository.expectSave(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute(lang: .ko)
        }

        do {
            try await task.value
            XCTFail("SetLanguagesUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? SetLanguagesUseCaseError else {
                return XCTFail(
                    "예상한 에러는 SetLanguagesUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }
}
