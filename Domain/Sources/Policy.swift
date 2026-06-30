import Foundation

public enum Policy {
    /// 제목 최대 글자 수
    static let maxNameLength: Int = 50

    /// AVAudioEngine installTap 버퍼 크기 (프레임 수)
    /// 44100 Hz 기준 약 93ms/buffer → ~10.7 Waveform/sec
    public static let waveformTapBufferSize: Int = 4096

    /// Waveform 당 amplitude 샘플 수 (파형 막대 개수)
    public static let waveformSamplesPerBuffer: Int = 20

    /// 앱 언어 설정을 저장하기 위한 UserDefaults 키
    public static let appSelectedLanguageKey: String = "app_selected_language"
    /// 기존 사용자 여부를 확인하기 위한 UserDefaults 키
    public static let isExistingUserKey: String = "isExistingUser"

    /// 온보딩 완료 시 자동 생성되는 기본 폴더 이름
    public static let defaultFolderName: String = "기본 폴더"

    /// 온보딩 완료 시 자동 생성되는 휴지통 폴더 이름
    public static let trashFolderName: String = "휴지통"

    /// 음성 노트 `Default Name`
    public static let voiceNoteDefaultName: String = "새 기록"

    /// 녹음 PCM 버퍼 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let audioBufferStreamBufferLimit: Int = 8

    /// UI 파형 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let waveformStreamBufferLimit: Int = 8

    /// 최근 기록 탭에서 표시할 최대 VoiceNote 개수
    public static let recentVoiceNoteLimit: Int = 5

    /// 재생 상태 스트림의 최대 대기 개수 (초과 시 최신값 유지)
    public static let playbackStateStreamBufferLimit: Int = 8

    /// 재생 진행률 업데이트 주기 (나노초, 0.1초)
    public static let playbackProgressUpdateInterval: UInt64 = 100_000_000

    /// 재생 빨리감기/뒤로가기 이동 간격 (초)
    public static let playbackSkipInterval: TimeInterval = 5

    /// 세그먼트 간 공백이 이 값(초)을 초과하면 새 섹션으로 분리
    public static let scriptGroupingPauseThreshold: TimeInterval = 2.0
}

// MARK: - 요약, 문법 교정 ( Prompt )

public extension Policy {
    /// AI 요약 프롬프트 텍스트 입니다.
    static func summaryPrompt(lang: String) -> String {
        """
        You summarize transcript text.
        Extract 3 to 5 concise keywords.
        Write 1 to 3 concise key points in \(lang) that capture the main ideas.
        Use fewer key points for short or single-topic transcripts, and more for longer or multi-topic ones.
        Each key point should be a single standalone sentence without bullet markers or numbering.
        Return content that matches the schema.
        """
    }

    /// Keyword 요약 프롬프트 텍스트 입니다
    static func keywordPrompt(transcript: String) -> String {
        """
        Read the following transcript and generate keywords and key points.

        Transcript:
        \(transcript)
        """
    }

    /// STT를 통해 전사된 문장을 교정하는 프롬포트 입니다.
    static let sttCorrectionPrompt: String = """
       You are a grammar correction assistant.

       Correct grammar, spelling, and punctuation only.
       Preserve meaning and tone.
       Keep the original language of the input text.
       Do not translate or rewrite unnecessarily.
       Return only the corrected text.
    """

    /// 교정할 문장을 주입하는 사용자 프롬프트 텍스트 입니다.
    static func correctionPrompt(text: String) -> String {
        """
         Correct the grammar of the following text and polish it to sound natural.
         Do not include any explanations, introduction, or additional text. Return ONLY the corrected text.

         Text:
         \(text)
         """
    }

    /// STT를 통해 전사된 여러 문장을 한 번에 교정하는 배치 프롬프트입니다.
    static let sttBatchCorrectionPrompt: String = """
       You are a grammar correction assistant.
       Your task is to correct the grammar, spelling, and punctuation of the provided numbered list of sentences.
       Preserve the meaning and tone of each sentence.
       Keep the original language of the input text.
       Return the corrected sentences in the exact same numbered format (e.g., [1] Corrected sentence).
       Do not include any explanations, introduction, or additional text. Return ONLY the numbered list of corrected sentences.
    """

    /// 교정할 문장 목록을 주입하는 사용자 배치 프롬프트 텍스트입니다.
    static func batchCorrectionPrompt(texts: [String]) -> String {
        var prompt = "Correct the grammar of the following sentences and polish them to sound natural.\n"
        prompt += "You must return them in the exact same format: [number] Corrected sentence.\n\n"
        for (index, text) in texts.enumerated() {
            prompt += "[\(index + 1)] \(text)\n"
        }
        return prompt
    }
}
