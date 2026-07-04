import SwiftUI

/// Elevation tokens mirrored from the Aisly design system (`tokens/shadows.css`).
enum AislyShadow {
    struct Style {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    /// Resting surface cards.
    static let card = Style(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    /// Transient toasts floating above content.
    static let toast = Style(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    /// Small control thumbs (switches).
    static let thumb = Style(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
    /// Floating action button.
    static let fab = Style(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 4)
}

extension View {
    /// Applies one of the shared Aisly elevation tokens.
    func aislyShadow(_ style: AislyShadow.Style) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
