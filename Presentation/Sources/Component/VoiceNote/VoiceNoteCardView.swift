import SwiftUI

struct VoiceNoteCardView: View {
    var title: String
    var subTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                Text(title)
                    .foregroundStyle(.gray950)
                    .font(.system(size: 18))
                    .lineSpacing(1.3)
                Text(subTitle)
                    .foregroundStyle(.gray800)
                    .font(.body)
                    .font(.system(size: 16))
                    .lineSpacing(1.5)
                    .tracking(-0.03)
                Text("요약 필요")
                    .font(.system(size: 15))
                    .lineSpacing(1.3)
                    .tracking(-0.03)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .overlay(
                        Capsule()
                            .stroke(Color.point600, lineWidth: 1)
                    )
                    .background(.point600.opacity(0.2), in: .capsule)
                    .foregroundStyle(.gray750)
            }
        }
        .frame(minHeight: 118)
        .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
        .padding(.horizontal)
        .background(.point200.opacity(0.2))
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
    }
}

// #Preview {
//    VoiceNoteCardView(title: "test", subTitle: "qqweqfq")
// }
