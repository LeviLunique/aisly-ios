import SwiftUI

struct AislyItemRow<TrailingAccessory: View>: View {
    private let title: String
    private let detail: Text
    private let note: Text?
    private let isChecked: Bool
    private let isFavorite: Bool
    private let primaryPrice: Text?
    private let secondaryPrice: Text?
    private let trailingAccessory: TrailingAccessory
    private let tapAction: (() -> Void)?

    init(
        title: String,
        detail: Text,
        note: Text? = nil,
        isChecked: Bool = false,
        isFavorite: Bool = false,
        primaryPrice: Text? = nil,
        secondaryPrice: Text? = nil,
        tapAction: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory
    ) {
        self.title = title
        self.detail = detail
        self.note = note
        self.isChecked = isChecked
        self.isFavorite = isFavorite
        self.primaryPrice = primaryPrice
        self.secondaryPrice = secondaryPrice
        self.tapAction = tapAction
        self.trailingAccessory = trailingAccessory()
    }

    var body: some View {
        Button(action: { tapAction?() }) {
            HStack(alignment: .top, spacing: AislySpacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AislySpacing.small) {
                        Text(title)
                            .font(AislyTypography.rowTitle)
                            .foregroundStyle(isChecked ? AislyColor.textSecondary : AislyColor.textPrimary)
                            .strikethrough(isChecked)

                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AislyColor.secondary)
                        }
                    }

                    detail
                        .font(AislyTypography.caption)
                        .foregroundStyle(AislyColor.textSecondary)

                    if let note {
                        note
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    if let primaryPrice {
                        primaryPrice
                            .font(AislyTypography.caption.weight(.semibold))
                            .foregroundStyle(isChecked ? AislyColor.textSecondary : AislyColor.textPrimary)
                    }

                    if let secondaryPrice {
                        secondaryPrice
                            .font(AislyTypography.small)
                            .foregroundStyle(AislyColor.textTertiary)
                    }
                }

                trailingAccessory
            }
            .padding(AislySpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                    .fill(isChecked ? AislyColor.surfaceSecondary : AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension AislyItemRow where TrailingAccessory == EmptyView {
    init(
        title: String,
        detail: Text,
        note: Text? = nil,
        isChecked: Bool = false,
        isFavorite: Bool = false,
        primaryPrice: Text? = nil,
        secondaryPrice: Text? = nil,
        tapAction: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            detail: detail,
            note: note,
            isChecked: isChecked,
            isFavorite: isFavorite,
            primaryPrice: primaryPrice,
            secondaryPrice: secondaryPrice,
            tapAction: tapAction,
            trailingAccessory: { EmptyView() }
        )
    }
}
