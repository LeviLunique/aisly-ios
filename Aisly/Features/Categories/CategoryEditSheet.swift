import SwiftUI

struct CategoryEditSheet: View {
    @ObservedObject var viewModel: CategoriesViewModel

    var body: some View {
        AislySheetContainer(
            title: Text(verbatim: isEditing ? "Edit Category" : "New Category"),
            trailing: {
                HStack(spacing: AislySpacing.medium) {
                    editorCircleButton(systemImage: "xmark", tone: AislyColor.textSecondary, label: "Close") {
                        viewModel.dismissEditor()
                    }

                    editorCircleButton(
                        systemImage: "checkmark",
                        tone: viewModel.isDraftSubmissionDisabled ? AislyColor.textTertiary : AislyColor.primary,
                        label: isEditing ? "Save category" : "Create category",
                        enabled: viewModel.isDraftSubmissionDisabled == false
                    ) {
                        Task {
                            await viewModel.saveDraft()
                        }
                    }
                }
            },
            content: {
                VStack(spacing: AislySpacing.large) {
                    heroPreview
                        .padding(.top, AislySpacing.small)

                    nameField

                    colorGrid

                    iconGrid

                    Text(verbatim: "Items are grouped by category in every list. Unclassified items go to Others.")
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AislySpacing.xSmall)
                }
            }
        )
        .presentationDetents([.height(540), .large])
        .presentationDragIndicator(.hidden)
    }

    private var heroPreview: some View {
        AislyCategoryIcon(
            systemName: viewModel.draftIconName,
            color: Color.categoryHex(viewModel.draftColorHex),
            size: .hero
        )
        .frame(maxWidth: .infinity)
    }

    private var nameField: some View {
        TextField(
            text: $viewModel.draftName,
            prompt: Text(verbatim: "Category Name").foregroundColor(AislyColor.textTertiary)
        ) {
            Text(verbatim: "Category Name")
        }
        .font(AislyTypography.screenTitle)
        .foregroundStyle(Color.categoryHex(viewModel.draftColorHex))
        .multilineTextAlignment(.center)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                .stroke(AislyColor.borderHeavy, lineWidth: 1)
        )
    }

    private var colorGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AislySpacing.medium), count: 6),
            spacing: AislySpacing.medium
        ) {
            ForEach(displayedColorHexes, id: \.self) { colorHex in
                Button {
                    viewModel.updateDraftColorHex(colorHex)
                } label: {
                    Circle()
                        .fill(Color.categoryHex(colorHex))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(AislyColor.textPrimary, lineWidth: viewModel.draftColorHex == colorHex ? 2 : 0)
                                .padding(-3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private var iconGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AislySpacing.small), count: 6),
            spacing: AislySpacing.small
        ) {
            ForEach(displayedIconNames, id: \.self) { iconName in
                Button {
                    viewModel.updateDraftIconName(iconName)
                } label: {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.draftIconName == iconName ? AislyColor.primaryForeground : AislyColor.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(viewModel.draftIconName == iconName ? Color.categoryHex(viewModel.draftColorHex) : AislyColor.surfaceTertiary)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: iconName))
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func editorCircleButton(
        systemImage: String,
        tone: Color,
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tone)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AislyColor.surfaceSecondary))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .accessibilityLabel(Text(verbatim: label))
    }

    private var displayedColorHexes: [UInt32] {
        if viewModel.availableColorHexes.contains(viewModel.draftColorHex) {
            return viewModel.availableColorHexes
        }

        return [viewModel.draftColorHex] + viewModel.availableColorHexes
    }

    private var displayedIconNames: [String] {
        if viewModel.availableIconNames.contains(viewModel.draftIconName) {
            return viewModel.availableIconNames
        }

        return [viewModel.draftIconName] + viewModel.availableIconNames
    }

    private var isEditing: Bool {
        if case .edit = viewModel.editorMode {
            return true
        }

        return false
    }
}
