import SwiftUI
import Domain

struct VoiceNoteCardView: View {
    let isSelected: Bool
    var select: FolderDetailViewModel.Select
    let voiceNote: VoiceNote
    let action: ((VoiceNote, Bool) -> Void)?
    
    init(
        select: FolderDetailViewModel.Select = .none,
        isSelected: Bool = false,
        voiceNote: VoiceNote,
        action: ((VoiceNote, Bool) -> Void)? = nil
    ) {
        self.select = select
        self.isSelected = isSelected
        self.voiceNote = voiceNote
        self.action = action
    }
    
    var isEdit: Bool {
        select != .none
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isEdit {
                checkIcon
            }
            VStack(alignment: .leading, spacing: 6) {
                cardContent
            }

        }
        .onChange(of: select) { _,newValue in
            print("내부 VoiceNote select : \(newValue)")
        }
        .editCardStyle(isSelected: isSelected)
        .onTapGesture {
            if isEdit {
                action?(voiceNote, !isSelected)
            }
        }
    }
    
    @ViewBuilder
    private var checkIcon: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.gray950, .point600)
                .overlay {
                    if !isSelected {
                        Circle()
                            .fill(.gray850)
                    }
                }
        }
        .padding(.trailing)
    }
    
    @ViewBuilder
    private var cardContent: some View {
        let time: String = Date.now.voiceNoteDay(
            createdAt: voiceNote.createdAt,
            updatedAt: voiceNote.updatedAt,
            duration: voiceNote.voiceRecord.duration
        )
        Group {
            Text(voiceNote.title)
                .foregroundStyle(.gray950)
                .font(.system(size: 18))
                .lineSpacing(1.3)
            Text(time)
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
}

extension View {
    func editCardStyle(isSelected: Bool) -> some View {
        self
        .modifier(
            EditVoiceNoteCardModifier(
                isSelected: isSelected
            )
        )
    }
}

struct EditVoiceNoteCardModifier: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: 118)
            .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
            .padding(.horizontal)
            .background(.point200.opacity(0.2))
            .glassEffect(.clear, in: .rect(cornerRadius: 20))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.point900, lineWidth: 1)
                }
            }
    }
}


//#Preview {
//    VoiceNoteCardView(
//        select: .none,
//        voiceNote: .
//        action: nil
//    )
//    .padding()
//    .background(.gray50)
//}
