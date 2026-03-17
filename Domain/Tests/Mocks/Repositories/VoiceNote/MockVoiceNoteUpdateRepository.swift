import Foundation
import XCTest

@testable import Domain

actor MockVoiceNoteUpdateRepository: VoiceNoteUpdateRepository {

    private var result: Result<VoiceNote, VoiceNoteUpdateRepositoryError>?

    private(set) var updateCallCount = 0
    private(set) var actualUpdatedVoiceNote: VoiceNote?

    private var expectedUpdateCallCount: Int?
    private var expectedUpdatedVoiceNote: VoiceNote?

    func setResult(_ result: Result<VoiceNote, VoiceNoteUpdateRepositoryError>) {
        self.result = result
    }

    func expectUpdate(callCount: Int, voiceNote: VoiceNote? = nil) {
        expectedUpdateCallCount = callCount
        expectedUpdatedVoiceNote = voiceNote
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(
                updateCallCount,
                expected,
                "update call count mismatch",
                file: file,
                line: line
            )
        }
        if let expectedNote = expectedUpdatedVoiceNote {
            XCTAssertEqual(
                actualUpdatedVoiceNote?.id,
                expectedNote.id,
                "update voiceNote id mismatch",
                file: file,
                line: line
            )
            XCTAssertEqual(
                actualUpdatedVoiceNote?.title,
                expectedNote.title,
                "update voiceNote title mismatch",
                file: file,
                line: line
            )
        }
    }

    func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUpdateRepositoryError) -> VoiceNote {
        updateCallCount += 1
        actualUpdatedVoiceNote = voiceNote

        switch result {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case .none:
            XCTFail("MockVoiceNoteUpdateRepository.updateResult 가 설정되지 않았습니다.")
            throw .unknown(
                NSError(domain: "MockVoiceNoteUpdateRepository.updateResult", code: -1)
            )
        }
    }
}
