import SwiftUI
import UIKit

enum AislyColor {
    static let backgroundPrimary = Color.dynamic(light: 0xF9F9F7, dark: 0x000000)
    static let backgroundSecondary = Color.dynamic(light: 0xF5F5F3, dark: 0x1C1C1E)
    static let backgroundTertiary = Color.dynamic(light: 0xECECEA, dark: 0x2C2C2E)
    static let surfacePrimary = Color.dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let surfaceSecondary = Color.dynamic(light: 0xF5F5F3, dark: 0x2C2C2E)
    static let surfaceTertiary = Color.dynamic(light: 0xECECEA, dark: 0x3A3A3C)
    static let surfaceElevated = Color.dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let glassBackground = Color.dynamic(
        light: UIColor(white: 1, alpha: 0.8),
        dark: UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 0.85)
    )
    static let glassBorder = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.08),
        dark: UIColor(white: 1, alpha: 0.12)
    )

    static let textPrimary = Color.dynamic(light: 0x1C1C1E, dark: 0xFFFFFF)
    static let textSecondary = Color.dynamic(light: 0x6B6B70, dark: 0x98989F)
    static let textTertiary = Color.dynamic(light: 0x98989F, dark: 0x6B6B70)
    static let textQuaternary = Color.dynamic(light: 0xC7C7CC, dark: 0x48484A)

    static let primary = Color.dynamic(light: 0x14B8A6, dark: 0x2DD4BF)
    static let primaryStrong = Color.dynamic(light: 0x0D9488, dark: 0x14B8A6)
    static let primaryLight = Color.dynamic(light: 0xCCFBF1, dark: 0x134E4A)
    static let primarySurface = Color.dynamic(light: 0xF0FDFA, dark: 0x0F3A36)
    static let primaryForeground = Color.dynamic(light: 0xFFFFFF, dark: 0x000000)
    static let secondary = Color.dynamic(light: 0xF59E0B, dark: 0xFCD34D)
    static let secondaryLight = Color.dynamic(light: 0xFEF3C7, dark: 0x78350F)
    static let secondaryForeground = Color.dynamic(light: 0xFFFFFF, dark: 0x000000)
    static let warning = Color.dynamic(light: 0xF59E0B, dark: 0xFBBF24)
    static let error = Color.dynamic(light: 0xEF4444, dark: 0xF87171)
    static let success = Color.dynamic(light: 0x10B981, dark: 0x34D399)
    static let successLight = Color.dynamic(light: 0xD1FAE5, dark: 0x064E3B)
    static let archive = Color.dynamic(light: 0x6B7280, dark: 0x9CA3AF)
    static let archiveLight = Color.dynamic(light: 0xE5E7EB, dark: 0x374151)
    static let brandDarkSurface = Color.dynamic(light: 0x1C1C1E, dark: 0x1C1C1E)
    static let overlay = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.4),
        dark: UIColor(white: 0, alpha: 0.6)
    )

    static let borderSubtle = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.08),
        dark: UIColor(white: 1, alpha: 0.12)
    )
    static let borderEmphasis = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.12),
        dark: UIColor(white: 1, alpha: 0.18)
    )
    static let borderHeavy = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.18),
        dark: UIColor(white: 1, alpha: 0.24)
    )
    static let divider = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.06),
        dark: UIColor(white: 1, alpha: 0.08)
    )
}

private extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        dynamic(
            light: UIColor(hex: light),
            dark: UIColor(hex: dark)
        )
    }

    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
