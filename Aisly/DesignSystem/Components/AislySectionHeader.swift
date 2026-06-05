import SwiftUI

struct AislySectionHeader: View {
    private let title: Text

    init(_ title: LocalizedStringResource) {
        self.title = Text(title)
    }

    init(_ title: Text) {
        self.title = title
    }

    var body: some View {
        title
            .font(AislyTypography.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(AislyColor.textSecondary)
            .padding(.bottom, AislySpacing.xSmall)
    }
}
