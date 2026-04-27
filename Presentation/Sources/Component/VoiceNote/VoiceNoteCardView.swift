import Domain
import SwiftUI

struct VoiceNoteCardView: View {
    let isSelected: Bool
    var select: SelectionMode
    let voiceNote: VoiceNote
    let action: ((VoiceNote, Bool) -> Void)?
    let completeAction: (() -> Void)?
    init(
        select: SelectionMode = .none,
        isSelected: Bool = false,
        voiceNote: VoiceNote,
        action: ((VoiceNote, Bool) -> Void)? = nil,
        completeAction: (() -> Void)? = nil
    ) {
        self.select = select
        self.isSelected = isSelected
        self.voiceNote = voiceNote
        self.action = action
        self.completeAction = completeAction
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
        .editVoiceNoteCardStyle(isSelected: isSelected)
        .onTapGesture {
            if isEdit {
                action?(voiceNote, !isSelected)
            } else {
                completeAction?()
            }
        }
    }

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
                .typography(.title2)
                .foregroundStyle(.gray950)
            Text(time)
                .typography(.body2)
                .foregroundStyle(.gray800)
            analysisText(binding: voiceNote.analysisState.bindingValue)
        }
    }
}

// MARK: - Helper

extension VoiceNoteCardView {
    /// 분석 상태에 따른 텍스트 뷰 (요약 중, 요약 실패, 요약 완료
    @ViewBuilder
    func analysisText(binding: AnalysisState.BindingKey) -> some View {
        switch binding {
        case .progress, .failed:
            Text(binding.currentText)
                .typography(.label)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .overlay(
                    Capsule()
                        .stroke(Color.gray500, lineWidth: 1)
                )
                .background(.gray200, in: .capsule)
                .foregroundStyle(.gray750)
        case .success:
            Text(binding.currentText)
                .typography(.label)
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

/// ViewModifier 확장
extension View {
    func editVoiceNoteCardStyle(isSelected: Bool) -> some View {
        modifier(
            EditVoiceNoteCardModifier(
                isSelected: isSelected
            )
        )
    }
}

/// 음성 노트 선택 모드 스타일 정의
struct EditVoiceNoteCardModifier: ViewModifier {
    let isSelected: Bool
    private let cornerRadius: CGFloat = 20

    private var borderColor: Color {
        isSelected ? .point900 : .gray500
    }

    func body(content: Content) -> some View {
        content
            .frame(minHeight: 118)
            .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
            .padding(.horizontal)
            .glassEffect(.clear.tint(.point200.opacity(0.2)), in: .rect(cornerRadius: 20))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.point900, lineWidth: 1)
                }
            }
            .contentShape(.rect(cornerRadius: 20))
    }
}

// #Preview {
//    VoiceNoteCardView(
//        select: .none,
//        voiceNote: .
//        action: nil
//    )
//    .padding()
//    .background(.gray50)
// }
