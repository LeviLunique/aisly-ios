import SwiftUI

/// Molecule: the standard content layout for a row inside a native
/// inset-grouped `List` — a leading accessory (typically an `AislyCategoryIcon`),
/// a title with optional subtitle, and an optional trailing accessory. The
/// enclosing `List`/`NavigationLink` supplies the card background, dividers, and
/// disclosure chevron, keeping the row idiomatic on iOS.
struct AislyGroupedRow<Leading: View, Trailing: View>: View {
    private let leading: Leading
    private let title: String
    private let titleColor: Color
    private let subtitle: Text?
    private let trailing: Trailing

    init(
        title: String,
        titleColor: Color = AislyColor.textPrimary,
        subtitle: Text? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: AislySpacing.medium) {
            leading

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AislyTypography.rowTitle)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                if let subtitle {
                    subtitle
                        .font(AislyTypography.rowMetadata)
                        .foregroundStyle(AislyColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.vertical, 2)
    }
}

extension AislyGroupedRow where Trailing == EmptyView {
    init(
        title: String,
        titleColor: Color = AislyColor.textPrimary,
        subtitle: Text? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            title: title,
            titleColor: titleColor,
            subtitle: subtitle,
            leading: leading,
            trailing: { EmptyView() }
        )
    }
}
