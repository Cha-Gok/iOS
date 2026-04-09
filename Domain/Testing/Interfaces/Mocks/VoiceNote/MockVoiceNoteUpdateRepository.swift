@testable import Domain
import Foundation
import XCTest

public actor MockVoiceNoteUpdateRepository: VoiceNoteUpdateRepository {
    public init() {}

    private var result: Result<VoiceNote, VoiceNoteUpdateRepositoryError>?

    private var updateCallCount = 0
    private var actualUpdatedVoiceNote: VoiceNote?

    private var expectedUpdateCallCount: Int?
    private var expectedUpdatedVoiceNote: VoiceNote?

    public func setResult(_ result: Result<VoiceNote, VoiceNoteUpdateRepositoryError>) {
        self.result = result
    }

    public func expectUpdate(callCount: Int, voiceNote: VoiceNote? = nil) {
        expectedUpdateCallCount = callCount
        expectedUpdatedVoiceNote = voiceNote
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(
                updateCallCount,
                expected,
                "수정 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedNote = expectedUpdatedVoiceNote {
            XCTAssertEqual(
                actualUpdatedVoiceNote?.id,
                expectedNote.id,
                "수정 음성 메모 ID가 일치하지 않습니다.",
                file: file,
                line: line
            )
            XCTAssertEqual(
                actualUpdatedVoiceNote?.title,
                expectedNote.title,
                "수정 음성 메모 제목이 일치하지 않습니다.",
                file: file,
                line: line
            )
            XCTAssertEqual(
                actualUpdatedVoiceNote?.voiceRecord.audioFilePath,
                expectedNote.voiceRecord.audioFilePath,
                "수정 시 오디오 파일 경로는 유지되어야 합니다.",
                file: file,
                line: line
            )
        }
    }

    public func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUpdateRepositoryError) -> VoiceNote {
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
