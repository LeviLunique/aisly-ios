import SwiftUI

struct AislyLogo: View {
    enum Size: CaseIterable {
        case small
        case medium
        case large
        case xLarge

        var dimension: CGFloat {
            switch self {
            case .small:
                return 40
            case .medium:
                return 64
            case .large:
                return 96
            case .xLarge:
                return 128
            }
        }
    }

    enum Variant: CaseIterable {
        case `default`
        case monochrome
        case light
        case dark

        fileprivate var style: Style {
            switch self {
            case .default:
                return Style(
                    background: AnyShapeStyle(
                        LinearGradient(
                            colors: [AislyColor.primary, AislyColor.primaryStrong],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ),
                    primary: .white,
                    secondary: .white,
                    accent: AislyColor.warning
                )
            case .monochrome:
                return Style(
                    background: AnyShapeStyle(AislyColor.textPrimary),
                    primary: .white,
                    secondary: .white,
                    accent: .white
                )
            case .light:
                return Style(
                    background: AnyShapeStyle(Color.white),
                    primary: AislyColor.primary,
                    secondary: AislyColor.primaryStrong,
                    accent: AislyColor.warning
                )
            case .dark:
                return Style(
                    background: AnyShapeStyle(AislyColor.brandDarkSurface),
                    primary: AislyColor.primary,
                    secondary: AislyColor.primaryStrong,
                    accent: AislyColor.warning
                )
            }
        }
    }

    struct Style {
        let background: AnyShapeStyle
        let primary: Color
        let secondary: Color
        let accent: Color
    }

    private let size: Size
    private let variant: Variant

    init(
        size: Size = .medium,
        variant: Variant = .default
    ) {
        self.size = size
        self.variant = variant
    }

    var body: some View {
        GeometryReader { proxy in
            let style = variant.style
            let side = min(proxy.size.width, proxy.size.height)
            let cornerRadius = side * 0.2167

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(style.background)

                logoContent(style: style, side: side)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(width: size.dimension, height: size.dimension)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func logoContent(style: Style, side: CGFloat) -> some View {
        let scale = side / 120

        ZStack {
            VStack(alignment: .leading, spacing: 20 * scale) {
                logoLine(width: 42 * scale, style: style)
                logoLine(width: 35 * scale, style: style)
                logoLine(width: 38 * scale, style: style)
            }
            .offset(x: -11 * scale, y: -1 * scale)

            AislyCheckmarkShape()
                .stroke(
                    style.primary,
                    style: StrokeStyle(
                        lineWidth: 9 * scale,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: 50 * scale, height: 38 * scale)
                .offset(x: 5 * scale, y: -3 * scale)

            Circle()
                .fill(style.accent)
                .frame(width: 10 * scale, height: 10 * scale)
                .offset(x: 25 * scale, y: 25 * scale)
        }
    }

    private func logoLine(width: CGFloat, style: Style) -> some View {
        Capsule(style: .continuous)
            .fill(style.secondary.opacity(0.25))
            .frame(width: width, height: 3.5)
    }
}

struct AislyAppIcon: View {
    var body: some View {
        AislyLogo(size: .large, variant: .default)
    }
}

struct AislyMark: View {
    enum Size: CaseIterable {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small:
                return 24
            case .medium:
                return 32
            case .large:
                return 48
            }
        }
    }

    private let size: Size
    private let color: Color

    init(
        size: Size = .medium,
        color: Color = AislyColor.primary
    ) {
        self.size = size
        self.color = color
    }

    var body: some View {
        let dimension = size.dimension
        let scale = dimension / 32

        ZStack {
            AislyMarkShape()
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 3 * scale,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 4 * scale, height: 4 * scale)
                .offset(x: 6 * scale, y: 6 * scale)
        }
        .frame(width: dimension, height: dimension)
        .accessibilityHidden(true)
    }
}

private struct AislyCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

private struct AislyMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.50))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.31))
        return path
    }
}

#Preview("Default Logo") {
    AislyLogo(size: .large, variant: .default)
        .padding()
        .background(AislyColor.backgroundPrimary)
}

#Preview("Logo Variants") {
    VStack(spacing: AislySpacing.large) {
        HStack(spacing: AislySpacing.large) {
            AislyLogo(size: .medium, variant: .default)
            AislyLogo(size: .medium, variant: .light)
        }
        HStack(spacing: AislySpacing.large) {
            AislyLogo(size: .medium, variant: .dark)
            AislyLogo(size: .medium, variant: .monochrome)
        }
        HStack(spacing: AislySpacing.large) {
            AislyMark(size: .small)
            AislyMark(size: .medium)
            AislyMark(size: .large)
        }
    }
    .padding()
    .background(AislyColor.backgroundPrimary)
}
