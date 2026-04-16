import SwiftUI

struct FolderCardView: View {
    let name: String
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Group {
                Image(systemName: "folder")
                Text(name)
                    .font(Font.custom("Pretendard", size: 16))
                Spacer()
                Text(String(totalCount))
                    .font(Font.custom("Pretendard", size: 16))
                    .multilineTextAlignment(.trailing)
            }
            .foregroundColor(.gray800)
        }
        .padding(16)
        .background(.point200.opacity(0.2))
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }
}
