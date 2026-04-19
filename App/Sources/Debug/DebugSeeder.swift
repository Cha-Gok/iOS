#if DEBUG
    import AVFoundation
    import Core
    import Domain
    import Foundation

    @MainActor
    struct DebugSeeder {
        private static let didSeedKey = "debug_did_seed_v1"

        let folderRepository: any FolderRepository
        let voiceNoteRepository: any VoiceNoteRepository

        func seedIfNeeded() {
            let defaults = UserDefaults.standard
            guard !defaults.bool(forKey: Self.didSeedKey) else {
                AppLogger.debug("시드 데이터가 이미 존재합니다. 스킵.")
                return
            }

            do {
                let folders = try folderRepository.fetchAll()
                guard folders.contains(where: { !$0.isDeletable }) else {
                    AppLogger.debug("기본 폴더 미존재. 온보딩 이후 다시 시도합니다.")
                    return
                }
                try performSeed()
                defaults.set(true, forKey: Self.didSeedKey)
                AppLogger.info("시드 데이터 생성 완료")
            } catch {
                AppLogger.error("시드 데이터 생성 실패: \(error)")
            }
        }

        // MARK: - Private

        private func performSeed() throws {
            let workFolder = try folderRepository.create(Folder(name: "업무"))
            let personalFolder = try folderRepository.create(Folder(name: "개인"))

            let now = Date.now
            let specs: [Spec] = [
                Spec(
                    folderID: workFolder.id,
                    title: "팀 회의 요약",
                    createdAt: now.addingTimeInterval(-3600 * 5),
                    sections: [
                        (0.0, "오늘 회의의 주요 안건은 다음 분기 목표 설정입니다."),
                        (2.5, "마케팅 팀에서 신규 캠페인 일정을 공유했습니다."),
                        (5.0, "개발 팀은 이번 달 말 베타 출시 예정이라고 확정했습니다.")
                    ],
                    summaryLines: [
                        "다음 분기 목표를 팀별로 확정",
                        "마케팅 캠페인 일정 공유 완료",
                        "베타 출시 일정 확정"
                    ],
                    keywords: ["회의", "분기 목표", "베타"]
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "스프린트 리뷰",
                    createdAt: now.addingTimeInterval(-3600 * 24),
                    sections: [
                        (0.0, "이번 스프린트 완료율은 85퍼센트입니다."),
                        (2.5, "블로커로 지목된 이슈는 다음 스프린트로 이월합니다.")
                    ],
                    summaryLines: ["스프린트 완료율 85퍼센트", "블로커 이슈 이월"],
                    keywords: ["스프린트", "리뷰"]
                ),
                Spec(
                    folderID: personalFolder.id,
                    title: "독서 메모",
                    createdAt: now.addingTimeInterval(-3600 * 48),
                    sections: [
                        (0.0, "성공하는 사람들의 습관 3장 요약입니다."),
                        (2.5, "루틴의 힘이 얼마나 중요한지 강조합니다.")
                    ],
                    summaryLines: ["성공 습관 3장", "루틴의 중요성"],
                    keywords: ["독서", "습관"]
                )
            ]

            for spec in specs {
                try createSeededNote(spec: spec)
            }
        }

        private func createSeededNote(spec: Spec) throws {
            let duration = (spec.sections.last?.0 ?? 0) + 2.5
            let audioPath = try makeSilentAudioFile(duration: duration)
            let record = VoiceRecord(
                createdAt: spec.createdAt,
                audioFilePath: audioPath,
                duration: duration
            )
            let created = try voiceNoteRepository.create(record)

            let transcript = Transcript(
                sections: spec.sections.map { TranscriptSection(timestamp: $0.0, text: $0.1) }
            )
            let summary = Summary(text: spec.summaryLines.joined(separator: "\n"))
            let keywords = spec.keywords.map { Keyword(noteID: created.id, word: $0) }

            let updated = VoiceNote(
                id: created.id,
                title: spec.title,
                createdAt: spec.createdAt,
                updatedAt: spec.createdAt,
                folderID: spec.folderID,
                voiceRecord: created.voiceRecord,
                keywords: keywords,
                transcript: transcript,
                summary: summary,
                analysisState: .completed
            )
            _ = try voiceNoteRepository.update(updated)
        }

        private func makeSilentAudioFile(duration: Double) throws -> String {
            let directory = "VoiceRecords"
            let fileName = "seed-\(UUID().uuidString).m4a"
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let directoryURL = docURL.appendingPathComponent(directory)
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let fileURL = directoryURL.appendingPathComponent(fileName)

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64000
            ]
            let file = try AVAudioFile(
                forWriting: fileURL,
                settings: settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
            let frameCount = AVAudioFrameCount(file.processingFormat.sampleRate * duration)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: frameCount
            ) else {
                throw SeedError.audioGenerationFailed
            }
            buffer.frameLength = frameCount
            try file.write(from: buffer)

            return "\(directory)/\(fileName)"
        }

        // MARK: - Types

        private struct Spec {
            let folderID: UUID
            let title: String
            let createdAt: Date
            let sections: [(TimeInterval, String)]
            let summaryLines: [String]
            let keywords: [String]
        }

        private enum SeedError: Error {
            case audioGenerationFailed
        }
    }
#endif
