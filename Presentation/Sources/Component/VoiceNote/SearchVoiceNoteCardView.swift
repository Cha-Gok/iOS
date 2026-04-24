import SwiftUI
import Domain

struct SearchVoiceNoteCardView: View {
    let folderTitle: String
    let voiceNoteTitle: String
    let keyword: String
    let transcript: Transcript
    let keywords: [Keyword]
    
    var body: some View {
        VStack(alignment: .leading) {
            topContent
            Divider().background(.gray300).padding(.vertical, 12)
            keywordContent
            Divider().background(.gray300).padding(.vertical, 12)
            bottomContent
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassEffect(
            .clear.tint(.point200.opacity(0.2)),
            in: .rect(cornerRadius: Constant.cornerRadius)
        )
    }
    
    private var topContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder")
                Text(folderTitle).typography(.label)
            }
            Text(fullText: voiceNoteTitle, keyword: keyword)
                .typography(.title3)
                .foregroundStyle(.gray750)
            Text(transcript: transcript, keyword: keyword)
                .typography(.body3)
                .lineLimit(2)
        }
    }
    
    private var keywordContent: some View {
        return VStack(alignment: .leading, spacing: 8) {
            Text("키워드 매치 결과")
                .typography(.caption)
                .foregroundStyle(.gray400)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(keywords) { item in
                        Text(fullText: "#\(item.word)", keyword: keyword)
                    }
                }
                .typography(.label)
            }
        }
    }
    
    private var bottomContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("일치 위치로 이동")
                .typography(.caption)
                .foregroundStyle(.gray400)
            HStack(spacing: 10) {
                indicatorCard(title: "AI요약 n곳", fill: .point600)
                indicatorCard(title: "스크립트 n곳", fill: .info)
            }
            Text("2025.02.03 (2026.03.04 수정됨)·2시간 29분")
                .typography(.label)
                .foregroundStyle(.gray750)
        }
    }
}

// MARK: - Helper Method
extension SearchVoiceNoteCardView {
    fileprivate func indicatorCard(
        title: String,
        fill: Color
    ) -> some View {
        HStack {
            Circle().fill(fill)
                .frame(maxWidth: 10, maxHeight: 10)
            Text(title).typography(.body2)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .overlay {
            RoundedRectangle(cornerRadius: 99)
                .fill(.clear)
                .stroke(.gray350)
        }
    }
}

#Preview {
    SearchVoiceNoteCardView(
        folderTitle: "강의",
        voiceNoteTitle: "녹음을 요약한 기록 제목 가을",
        keyword: "가을",
        transcript: .init(
            sections: [
                TranscriptSection(timestamp: 0.0, text: "안녕하세요, 차곡입니다."),
                TranscriptSection(timestamp: 2.5, text: "음성 메모에서 가을 키워드를 검색하는 테스트입니다."),
                TranscriptSection(timestamp: 5.0, text: "텍스트 강조 기능이 잘 동작하는지 확인해볼게요.")
            ]
        ),
        keywords: [
            Keyword(noteID: UUID(), word: "가을"),
            Keyword(noteID: UUID(), word: "123"),
            Keyword(noteID: UUID(), word: "asd"),
            Keyword(noteID: UUID(), word: "5324"),
            Keyword(noteID: UUID(), word: "asdasf"),
            Keyword(noteID: UUID(), word: "cas"),
            Keyword(noteID: UUID(), word: "안녕")
        ]
    )
    .padding()
}
