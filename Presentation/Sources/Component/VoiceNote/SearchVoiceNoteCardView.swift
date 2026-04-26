import Domain
import SwiftUI

struct SearchVoiceNoteCardView: View {
    let title: String
    let keyword: String
    let timeline: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "microphone")
                .frame(maxWidth: 20, maxHeight: 20)
                .foregroundStyle(.gray750)
            VStack(alignment: .leading, spacing: 6) {
                Text(fullText: title, keyword: keyword)
                    .typography(.title3)
                    .foregroundStyle(.gray950)
                Text(timeline)
                    .typography(.label)
                    .foregroundStyle(.gray750)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(
            .clear.tint(.point200.opacity(0.2)),
            in: .rect(cornerRadius: Constant.cornerRadius)
        )
        .contentShape(.rect(cornerRadius: Constant.cornerRadius))
        .onTapGesture { action() }
    }
}

#Preview {
    SearchVoiceNoteCardView(
        title: "녹음을 요약한 기록 제목 가을",
        keyword: "녹음",
        timeline: "오후 4:30 * 1시간 54분",
        action: {}
    )
    .padding()
}
