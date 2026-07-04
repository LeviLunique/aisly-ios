import SwiftUI

struct AislySurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AislySpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .fill(AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
    }
}
