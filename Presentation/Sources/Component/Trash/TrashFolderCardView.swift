import Domain
import SwiftUI

struct TrashFolderCardView: View {
    let isSelected: Bool
    var select: SelectionMode
    let folder: Folder
    let action: ((Folder, Bool) -> Void)?
    let completeAction: (() -> Void)?

    init(
        select: SelectionMode = .none,
        isSelected: Bool = false,
        folder: Folder,
        action: ((Folder, Bool) -> Void)? = nil,
        completeAction: (() -> Void)? = nil
    ) {
        self.select = select
        self.isSelected = isSelected
        self.folder = folder
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
            cardContent
        }
        .editfolderCardStyle(isSelected: isSelected)
        .onTapGesture {
            if isEdit {
                action?(folder, !isSelected)
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

    private var cardContent: some View {
        HStack(spacing: 8) {
            Group {
                Image(systemName: "folder")
                Text(folder.name)
                    .font(Font.custom("Pretendard", size: 16))
                Spacer()
            }
            .foregroundColor(.gray800)
        }
    }
}
