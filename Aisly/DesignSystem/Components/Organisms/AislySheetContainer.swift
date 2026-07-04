import SwiftUI

struct AislySheetContainer<HeaderTrailing: View, Content: View>: View {
    private let title: Text?
    private let trailing: HeaderTrailing
    private let content: Content

    init(
        title: Text? = nil,
        @ViewBuilder trailing: () -> HeaderTrailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AislySpacing.small) {
                Capsule(style: .continuous)
                    .fill(AislyColor.surfaceTertiary)
                    .frame(width: 36, height: 5)
                    .padding(.top, AislySpacing.medium)

                HStack(spacing: AislySpacing.medium) {
                    if let title {
                        title
                            .font(AislyTypography.listHeader)
                            .foregroundStyle(AislyColor.textPrimary)
                    }

                    Spacer()

                    trailing
                }
                .padding(.horizontal, AislySpacing.large)
                .padding(.bottom, AislySpacing.medium)
            }
            .background(AislyColor.surfacePrimary)

            Divider()
                .overlay(AislyColor.divider)

            ScrollView {
                content
                    .padding(AislySpacing.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AislyColor.surfacePrimary)
        }
        .background(AislyColor.surfacePrimary)
    }
}

extension AislySheetContainer where HeaderTrailing == EmptyView {
    init(
        title: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, trailing: { EmptyView() }, content: content)
    }
}
