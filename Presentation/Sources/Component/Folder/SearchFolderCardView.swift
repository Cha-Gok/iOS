import SwiftUI

struct SearchFolderCardView: View {
    let fullText: String
    let keyword: String
    let timeline: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                fullText: fullText,
                keyword: keyword
            )
            .typography(.title3)
            Text(timeline)
                .typography(.label)
                .foregroundStyle(.gray750)
        }
        .padding()
        .glassEffect(.clear.tint(.point200.opacity(0.2)), in: .rect(cornerRadius: Constant.cornerRadius))
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    SearchFolderCardView(
        fullText: "가을 하늘 맑고 푸른데",
        keyword: "맑고",
        timeline: "2025.02.03 (2026.03.04 수정됨)·2시간 29분",
        action: {},
    )
}
