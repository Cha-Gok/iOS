import Domain

extension VoiceRecordEntity {
    func toDomain() -> VoiceRecord {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }
}
