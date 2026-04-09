@testable import Domain
import Foundation
import XCTest

public actor MockVoiceNoteCreateRepository: VoiceNoteCreateRepository {
    private var result: Result<VoiceNote, VoiceNoteCreateRepositoryError>?

    private var createCallCount = 0
    private var actualVoiceRecord: VoiceRecord?

    private var expectedCreateCallCount: Int?
    private var expectedVoiceRecordID: UUID?

    public init() {}

    public func setResult(_ result: Result<VoiceNote, VoiceNoteCreateRepositoryError>) {
        self.result = result
    }

    public func expectCreate(callCount: Int, voiceRecordID: UUID? = nil) {
        expectedCreateCallCount = callCount
        expectedVoiceRecordID = voiceRecordID
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(
                createCallCount,
                expected,
                "생성 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedID = expectedVoiceRecordID {
            XCTAssertEqual(
                actualVoiceRecord?.id,
                expectedID,
                "음성 녹음 ID가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    public func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteCreateRepositoryError) -> VoiceNote {
        createCallCount += 1
        actualVoiceRecord = voiceRecord

        switch result {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case .none:
            XCTFail("MockVoiceNoteCreateRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceNoteCreateRepository", code: -1))
        }
    }
}
