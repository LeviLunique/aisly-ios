import SwiftUI

struct AislyPageHeader<Leading: View, Trailing: View>: View {
    private let title: Text
    private let subtitle: Text?
    private let leading: Leading
    private let trailing: Trailing
    private let isGlass: Bool

    init(
        title: Text,
        subtitle: Text? = nil,
        isGlass: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.isGlass = isGlass
    }

    var body: some View {
        HStack(spacing: AislySpacing.medium) {
            leading
                .frame(minWidth: 44, alignment: .leading)

            VStack(spacing: 2) {
                title
                    .font(AislyTypography.listHeader)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)

                if let subtitle {
                    subtitle
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)

            trailing
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 56)
        .background(
            Group {
                if isGlass {
                    Rectangle()
                        .fill(AislyColor.glassBackground)
                } else {
                    Rectangle()
                        .fill(AislyColor.surfacePrimary)
                }
            }
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(isGlass ? AislyColor.glassBorder : AislyColor.divider)
                .frame(height: 1)
        }
    }
}

extension AislyPageHeader where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: Text,
        subtitle: Text? = nil,
        isGlass: Bool = true
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            isGlass: isGlass,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}
