@testable import Domain
import Core
import XCTest

final class CreateVoiceNoteUseCaseTest: XCTestCase {
    private var repository: MockVoiceNoteCreateRepository!
    private var sut: DefaultCreateVoiceNoteUseCase!

    override func setUp() {
        super.setUp()
        repository = MockVoiceNoteCreateRepository()
        sut = DefaultCreateVoiceNoteUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension CreateVoiceNoteUseCaseTest {
    func test_정상상태_음성메모생성시_생성된객체를반환한다() async throws {
        // Given
        let voiceRecord = VoiceRecord.stub()
        let expectedVoiceNote = VoiceNote.stub(voiceRecord: voiceRecord)

        await repository.setResult(.success(expectedVoiceNote))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        let result = try await sut.execute(voiceRecord)

        // Then
        XCTAssertEqual(result.id, expectedVoiceNote.id)
        XCTAssertEqual(result.voiceRecord.id, voiceRecord.id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension CreateVoiceNoteUseCaseTest {
    func test_리포지토리생성실패상태_음성메모생성시_createFailed에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()

        await repository.setResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("CreateVoiceNoteUseCaseError.createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error else {
                return XCTFail("예상한 에러는 CreateVoiceNoteUseCaseError.createFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_음성메모생성시_unknown에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        struct DummyError: Error {}
        let expectedError = DummyError()

        await repository.setResult(.failure(.unknown(expectedError)))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("CreateVoiceNoteUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail("예상한 에러는 CreateVoiceNoteUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await repository.verify()
    }

    func test_작업취소상태_음성메모생성시_cancelled에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()

        await repository.setResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("CreateVoiceNoteUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail("예상한 에러는 CreateVoiceNoteUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await repository.verify()
    }
}
