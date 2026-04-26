import SwiftUI

struct SearchFolderCardView: View {
    let fullText: String
    let keyword: String
    let createdAt: String
    let voiceNoteCount: Int
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder")
                .frame(maxWidth: 20, maxHeight: 20)
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    fullText: fullText,
                    keyword: keyword
                )
                .typography(.title3)
                Text(createdAt)
                    .typography(.label)
                    .foregroundStyle(.gray750)
            }
            Spacer()
            Text(String(voiceNoteCount))
                .typography(.body2)
                .foregroundStyle(.gray750)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.clear.tint(.point200.opacity(0.2)), in: .rect(cornerRadius: Constant.cornerRadius))
        .contentShape(.rect(cornerRadius: Constant.cornerRadius))
        .onTapGesture { action() }
    }
}

#Preview {
    SearchFolderCardView(
        fullText: "가을 하늘 맑고 푸른데",
        keyword: "맑고",
        createdAt: Date.now.description,
        voiceNoteCount: 3,
        action: {}
    )
    .padding()
}
