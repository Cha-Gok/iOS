import XCTest

@testable import Domain

final class CreateVoiceNoteUseCaseTests: XCTestCase {

    private var repository: MockVoiceNoteCreateRepository!
    private var sut: DefaultCreateVoiceNoteUseCase!

    override func setUp() {
        super.setUp()
        repository = MockVoiceNoteCreateRepository()
        sut = DefaultCreateVoiceNoteUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension CreateVoiceNoteUseCaseTests {

    func test_execute_유효한입력을넣으면_생성된보이스노트를반환한다() async throws {
        // Given
        let voiceRecord = VoiceRecord.stub(
            audioFilePath: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 1.0
        )
        let expected = VoiceNote.stub(title: "Created", voiceRecord: voiceRecord)
        await repository.setResult(.success(expected))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        let result = try await sut.execute(voiceRecord)

        // Then
        XCTAssertEqual(result.id, expected.id)
        XCTAssertEqual(result.title, "Created")
        XCTAssertEqual(result.voiceRecord.id, voiceRecord.id)
        await repository.verify()
    }

    func test_execute_대문자확장자여도_정상적으로생성한다() async throws {
        // Given
        let voiceRecord = VoiceRecord.stub(
            audioFilePath: URL(fileURLWithPath: "/tmp/TEST.M4A"),
            duration: 1.0
        )
        let expected = VoiceNote.stub(voiceRecord: voiceRecord)
        await repository.setResult(.success(expected))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        let result = try await sut.execute(voiceRecord)

        // Then
        XCTAssertEqual(result.id, expected.id)
        await repository.verify()
    }
}

// MARK: - 실패 / 에러 매핑
extension CreateVoiceNoteUseCaseTests {

    func test_execute_재생시간이0이면_invalidDuration에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub(duration: 0.0)
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .invalidDuration(let duration) = error else {
                return XCTFail("expected .invalidDuration, got \(error)")
            }
            XCTAssertEqual(duration, 0.0)
        }

        await repository.verify()
    }

    func test_execute_재생시간이NaN이면_invalidDuration에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub(duration: Double.nan)
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidDuration(let duration) = error else {
                return XCTFail("expected .invalidDuration, got \(error)")
            }
            XCTAssertTrue(duration.isNaN)
        }

        await repository.verify()
    }

    func test_execute_재생시간이무한이면_invalidDuration에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub(duration: Double.infinity)
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidDuration(let duration) = error else {
                return XCTFail("expected .invalidDuration, got \(error)")
            }
            XCTAssertTrue(duration.isInfinite)
        }

        await repository.verify()
    }

    func test_execute_오디오경로가파일URL이아니면_invalidAudioFilePath에러를던진다() async {
        // Given
        let url = URL(string: "https://example.com/test.m4a")!
        let voiceRecord = VoiceRecord.stub(audioFilePath: url)
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .invalidAudioFilePath(let mappedUrl) = error else {
                return XCTFail("expected .invalidAudioFilePath, got \(error)")
            }
            XCTAssertEqual(mappedUrl, url)
        }

        await repository.verify()
    }

    func test_execute_파일명이비어있으면_emptyFileName에러를던진다() async {
        // Given
        // "file://" 는 lastPathComponent가 빈 문자열이 됨
        let url = URL(string: "file://")!
        let voiceRecord = VoiceRecord.stub(audioFilePath: url)
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .emptyFileName = error else {
                return XCTFail("expected .emptyFileName, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_지원하지않는확장자이면_unsupportedExtension에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub(audioFilePath: URL(fileURLWithPath: "/tmp/test.txt"))
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .unsupportedExtension(let ext) = error else {
                return XCTFail("expected .unsupportedExtension, got \(error)")
            }
            XCTAssertEqual(ext, "txt")
        }

        await repository.verify()
    }

    func test_execute_리포지토리가생성실패를반환하면_createFailed에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        await repository.setResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .createFailed = error else {
                return XCTFail("expected .createFailed, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_리포지토리가취소를반환하면_cancelled에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        await repository.setResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_리포지토리가알수없는에러를반환하면_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}

        let voiceRecord = VoiceRecord.stub()
        await repository.setResult(.failure(.unknown(DummyError())))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        // When
        do {
            _ = try await sut.execute(voiceRecord)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .unknown(let underlying) = error else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertTrue(underlying is DummyError)
        }

        await repository.verify()
    }
}

// MARK: - Task 취소

extension CreateVoiceNoteUseCaseTests {

    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut should be initialized in setUp")
        }

        // Given
        let voiceRecord = VoiceRecord.stub()
        await repository.setResult(.success(VoiceNote.stub(voiceRecord: voiceRecord)))
        await repository.expectCreate(callCount: 0)

        // When
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute(voiceRecord)
        }

        // Then
        do {
            _ = try await task.value
            XCTFail("취소 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? CreateVoiceNoteUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }
}
