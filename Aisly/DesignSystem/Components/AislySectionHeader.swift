import SwiftUI

struct AislySectionHeader: View {
    private let title: LocalizedStringResource

    init(_ title: LocalizedStringResource) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(AislyTypography.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(AislyColor.textSecondary)
            .padding(.bottom, AislySpacing.xSmall)
    }
}
