import SwiftUI

struct AislyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AislyButtonStyle(variant: .primary, size: .medium).makeBody(configuration: configuration)
    }
}
