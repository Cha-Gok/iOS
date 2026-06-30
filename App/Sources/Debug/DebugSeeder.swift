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
            do {
                let folders = try folderRepository.fetchAll()
                guard folders.contains(where: { $0.kind == .default }) else {
                    AppLogger.debug("기본 폴더 미존재. 온보딩 이후 다시 시도합니다.")
                    return
                }

                // 디버그 빌드 시 매번 실행하여 최신 시드 데이터를 갱신합니다.
                // 중복 및 이전 시드를 방지하기 위해 기존 시드 폴더를 먼저 삭제합니다 (Core Data cascade 삭제됨).
                let seedFolderNames = ["업무", "개인", "학습", "회의록"]
                for folder in folders {
                    if seedFolderNames.contains(folder.name) {
                        try folderRepository.delete(id: folder.id)
                    }
                }

                try performSeed()
                AppLogger.info("시드 데이터 초기화 및 재설정 완료")
            } catch {
                AppLogger.error("시드 데이터 초기화 실패: \(error)")
            }
        }

        // MARK: - Private

        private func performSeed() throws {
            let workFolder = try folderRepository.create(Folder(name: "업무"))
            let personalFolder = try folderRepository.create(Folder(name: "개인"))
            let studyFolder = try folderRepository.create(Folder(name: "학습"))
            let meetingFolder = try folderRepository.create(Folder(name: "회의록"))

            let now = Date.now
            let h: TimeInterval = 3600
            let specs: [Spec] = [
                // MARK: 업무

                Spec(
                    folderID: workFolder.id,
                    title: "팀 주간 미팅 - 2026 Q1 회고와 Q2 목표 설정",
                    createdAt: now.addingTimeInterval(-h * 4),
                    texts: SeedContent.weeklyMeeting,
                    summaryLines: [
                        "Q1 핵심 지표 달성률 92퍼센트, 아웃풋 대비 아웃컴 개선 필요",
                        "Q2에는 온보딩 퍼널 개선과 신규 사용자 리텐션 지표를 최우선으로 설정",
                        "팀 간 커뮤니케이션 비용을 줄이기 위해 주간 싱크 포맷 재정비"
                    ],
                    keywords: ["주간회의", "Q1회고", "Q2목표", "리텐션", "퍼널", "OKR", "팀싱크"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "신규 프로젝트 킥오프 미팅",
                    createdAt: now.addingTimeInterval(-h * 12),
                    texts: SeedContent.projectKickoff,
                    summaryLines: [
                        "프로젝트 범위와 마일스톤, 리스크 및 담당자 최종 확정",
                        "첫 데모는 4주 뒤 내부 리뷰, 정식 런칭은 8주 뒤 목표"
                    ],
                    keywords: ["킥오프", "스코프", "마일스톤", "담당자", "리스크", "런칭", "데모", "타임라인"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "1on1 - 매니저 면담",
                    createdAt: now.addingTimeInterval(-h * 26),
                    texts: SeedContent.oneOnOne,
                    summaryLines: [
                        "다음 분기 커리어 목표로 시니어 엔지니어 승진 준비 합의"
                    ],
                    keywords: ["1on1", "커리어", "성장", "피드백", "시니어", "승진"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "고객사 온보딩 미팅 - Acme Corp",
                    createdAt: now.addingTimeInterval(-h * 50),
                    texts: SeedContent.customerMeeting,
                    summaryLines: [
                        "SSO 연동 스펙과 일정 공유",
                        "다음 미팅 전까지 관리자 대시보드 프로토타입 공유",
                        "계약 범위 외 추가 요구사항은 별도 견적 프로세스 진행"
                    ],
                    keywords: ["고객사", "온보딩", "SSO", "대시보드", "프로토타입", "계약"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "Apple Intelligence 기술 조사 녹음",
                    createdAt: now.addingTimeInterval(-h * 72),
                    texts: SeedContent.techResearch,
                    summaryLines: [],
                    keywords: ["AppleIntelligence", "Foundation", "온디바이스LLM", "프라이버시"],
                    analysisState: .summarizationFailed
                ),
                Spec(
                    folderID: workFolder.id,
                    title: "오늘 녹음한 메모 (정리 전)",
                    createdAt: now.addingTimeInterval(-h * 1),
                    texts: [],
                    summaryLines: [],
                    keywords: [],
                    analysisState: .pending
                ),

                // MARK: 개인

                Spec(
                    folderID: personalFolder.id,
                    title: "이번 주 회고 일기",
                    createdAt: now.addingTimeInterval(-h * 20),
                    texts: SeedContent.weeklyReflection,
                    summaryLines: [
                        "업무 집중 시간 확보 성공, 다만 운동 루틴은 2회만 지킴",
                        "다음 주는 자기계발 시간 블록을 캘린더에 미리 잡기로 결심"
                    ],
                    keywords: ["회고", "습관", "루틴", "시간관리", "운동"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: personalFolder.id,
                    title: "다음 달 제주도 여행 계획 브레인스토밍",
                    createdAt: now.addingTimeInterval(-h * 40),
                    texts: SeedContent.travelPlanning,
                    summaryLines: [
                        "항공편과 숙소는 이번 주 안으로 예약 마감",
                        "첫째 날은 서귀포 중심, 둘째 날 동쪽, 셋째 날 서쪽 코스로 동선 확정",
                        "우중 대비 실내 일정은 박물관과 카페 중심으로 백업 준비"
                    ],
                    keywords: ["여행", "제주도", "일정", "숙소", "항공편", "맛집", "렌터카"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: personalFolder.id,
                    title: "운동 루틴 정리",
                    createdAt: now.addingTimeInterval(-h * 60),
                    texts: SeedContent.workoutRoutine,
                    summaryLines: [
                        "주 4회 분할 루틴, 유산소 20분 병행으로 최종 확정"
                    ],
                    keywords: ["운동", "루틴", "헬스", "유산소", "분할"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: personalFolder.id,
                    title: "독서 메모 - 아주 작은 습관의 힘",
                    createdAt: now.addingTimeInterval(-h * 90),
                    texts: SeedContent.bookNotes,
                    summaryLines: [
                        "1퍼센트의 개선이 복리로 누적되는 핵심 원리 정리",
                        "환경 설계와 정체성 기반 습관 두 축으로 행동 설계"
                    ],
                    keywords: ["독서", "습관", "복리", "정체성", "환경설계", "자기계발"],
                    analysisState: .completed
                ),

                // MARK: 학습

                Spec(
                    folderID: studyFolder.id,
                    title: "iOS 강의 녹음 - Swift 동시성 딥다이브",
                    createdAt: now.addingTimeInterval(-h * 34),
                    texts: SeedContent.swiftConcurrencyLecture,
                    summaryLines: [
                        "actor와 Sendable은 데이터 레이스 방지의 핵심 도구",
                        "Task.isCancelled 체크와 Typed Throws로 안전한 비동기 경계 설계",
                        "MainActor 격리를 과도하게 쓰면 성능 병목이 될 수 있음"
                    ],
                    keywords: ["Swift6", "동시성", "actor", "Sendable", "MainActor", "TypedThrows", "Task"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: studyFolder.id,
                    title: "면접 대비 - 아키텍처 패턴 정리",
                    createdAt: now.addingTimeInterval(-h * 48),
                    texts: SeedContent.architectureStudy,
                    summaryLines: [
                        "Clean Architecture의 의존성 방향 규칙이 핵심",
                        "MVVM, MVI, TCA 각각의 트레이드오프 비교 정리"
                    ],
                    keywords: ["아키텍처", "MVVM", "MVI", "TCA", "CleanArchitecture", "면접"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: studyFolder.id,
                    title: "Core Data 마이그레이션 실습 녹음",
                    createdAt: now.addingTimeInterval(-h * 65),
                    texts: SeedContent.coreDataStudy,
                    summaryLines: [],
                    keywords: ["CoreData", "마이그레이션", "NSPersistentContainer"],
                    analysisState: .transcribed
                ),

                // MARK: 회의록

                Spec(
                    folderID: meetingFolder.id,
                    title: "디자인 리뷰 - 온보딩 화면 4차 개선안",
                    createdAt: now.addingTimeInterval(-h * 8),
                    texts: SeedContent.designReview,
                    summaryLines: [
                        "온보딩 3단계 순서 변경과 CTA 카피 개선",
                        "권한 요청 시점을 명확한 가치 제공 직후로 이동",
                        "다크 모드 대응 미비 항목 8건 다음 스프린트 백로그로 편입"
                    ],
                    keywords: ["디자인리뷰", "온보딩", "CTA", "권한", "다크모드", "UX"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: meetingFolder.id,
                    title: "월간 전사 공유 - 2026년 3월",
                    createdAt: now.addingTimeInterval(-h * 120),
                    texts: SeedContent.allHands,
                    summaryLines: [
                        "분기별 주요 지표와 전략 우선순위 공유",
                        "신규 입사자 소개 및 하반기 채용 계획 안내"
                    ],
                    keywords: ["전사공유", "월간", "지표", "전략", "채용", "입사자"],
                    analysisState: .completed
                ),
                Spec(
                    folderID: meetingFolder.id,
                    title: "긴급 장애 대응 미팅 녹음",
                    createdAt: now.addingTimeInterval(-h * 36),
                    texts: SeedContent.incidentMeeting,
                    summaryLines: [],
                    keywords: ["장애", "인시던트", "포스트모템"],
                    analysisState: .transcriptionFailed
                ),
                Spec(
                    folderID: personalFolder.id,
                    title: "일정 및 버그 관련 푸념 메모 (문법 교정 테스트용)",
                    createdAt: now.addingTimeInterval(-h * 2),
                    texts: SeedContent.grammarCheckTest,
                    summaryLines: [],
                    keywords: [],
                    analysisState: .transcribed
                )
            ]

            for spec in specs {
                try createSeededNote(spec: spec)
            }
        }

        private func createSeededNote(spec: Spec) throws {
            let sections = spec.title.contains("문법")
                ? SeedContent.buildLongSections(texts: spec.texts, totalDuration: 3600)
                : SeedContent.buildSections(texts: spec.texts)
            let duration = (sections.last?.timestamp ?? 0) + 3.0
            let audioPath = try makeSilentAudioFile(duration: max(duration, 2.5))
            let record = VoiceRecord(
                createdAt: spec.createdAt,
                audioFilePath: audioPath,
                duration: max(duration, 2.5)
            )
            let baseNote = VoiceNote(
                title: spec.title,
                createdAt: spec.createdAt,
                updatedAt: spec.createdAt,
                folderID: spec.folderID,
                voiceRecord: record,
                analysisState: spec.analysisState
            )
            let created = try voiceNoteRepository.create(baseNote)

            let transcript: Transcript? = shouldIncludeTranscript(for: spec.analysisState) && !sections.isEmpty
                ? Transcript(sections: sections)
                : nil
            let summary: Summary? = spec.analysisState == .completed && !spec.summaryLines.isEmpty
                ? Summary(text: spec.summaryLines.joined(separator: "\n"))
                : nil
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
                analysisState: spec.analysisState
            )
            _ = try voiceNoteRepository.update(updated)
        }

        private func shouldIncludeTranscript(for state: AnalysisState) -> Bool {
            switch state {
            case .pending, .transcribing, .transcriptionFailed, .waiting:
                return false
            case .transcribed, .summarizing, .regenerating, .completed, .summarizationFailed, .grammarCheckFailed,
                 .grammarChecked, .grammarChecking:
                return true
            }
        }

        private func makeSilentAudioFile(duration: Double) throws -> String {
            // 디버그용 무음 파일이므로 실제 파일 길이는 최대 5초로 제한하여
            // 메인 스레드 병목 및 과도한 메모리/디스크 사용을 방지합니다.
            let physicalDuration = min(duration, 5.0)
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
            let frameCount = AVAudioFrameCount(file.processingFormat.sampleRate * physicalDuration)
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
            let texts: [String]
            let summaryLines: [String]
            let keywords: [String]
            let analysisState: AnalysisState
        }

        private enum SeedError: Error {
            case audioGenerationFailed
        }
    }
#endif
