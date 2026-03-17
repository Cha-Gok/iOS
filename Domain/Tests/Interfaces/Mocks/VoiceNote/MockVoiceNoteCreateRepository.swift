@testable import Domain
import Foundation
import XCTest

actor MockVoiceNoteCreateRepository: VoiceNoteCreateRepository {
    private var result: Result<VoiceNote, VoiceNoteCreateRepositoryError>?

    private var createCallCount = 0
    private var actualVoiceRecord: VoiceRecord?

    private var expectedCreateCallCount: Int?
    private var expectedVoiceRecordID: UUID?

    func setResult(_ result: Result<VoiceNote, VoiceNoteCreateRepositoryError>) {
        self.result = result
    }

    func expectCreate(callCount: Int, voiceRecordID: UUID? = nil) {
        expectedCreateCallCount = callCount
        expectedVoiceRecordID = voiceRecordID
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(
                createCallCount,
                expected,
                "create call count mismatch",
                file: file,
                line: line
            )
        }
        if let expectedID = expectedVoiceRecordID {
            XCTAssertEqual(
                actualVoiceRecord?.id,
                expectedID,
                "voiceRecord ID mismatch",
                file: file,
                line: line
            )
        }
    }

    func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteCreateRepositoryError)
        -> VoiceNote
    {
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
