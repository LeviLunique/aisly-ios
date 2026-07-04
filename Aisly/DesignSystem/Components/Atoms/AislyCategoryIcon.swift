import SwiftUI

/// Atom: a colored circle containing a white SF Symbol, used to represent a
/// category, list, or template throughout the app. Mirrors the design system's
/// `CategoryIcon` atom.
struct AislyCategoryIcon: View {
    enum Size {
        case small
        case medium
        case large
        case hero

        var diameter: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 36
            case .large: return 44
            case .hero: return 88
            }
        }

        var glyphScale: CGFloat {
            switch self {
            case .hero: return 0.42
            default: return 0.5
            }
        }
    }

    private let systemName: String
    private let color: Color
    private let size: Size

    init(systemName: String, color: Color, size: Size = .medium) {
        self.systemName = systemName
        self.color = color
        self.size = size
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size.diameter * size.glyphScale, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: size.diameter, height: size.diameter)
            .background(Circle().fill(color))
    }
}
