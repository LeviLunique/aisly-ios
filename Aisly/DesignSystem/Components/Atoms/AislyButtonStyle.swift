import SwiftUI

struct AislyButtonStyle: ButtonStyle {
    enum Variant: CaseIterable {
        case primary
        case secondary
        case success
        case destructive
        case ghost

        fileprivate var backgroundColor: Color {
            switch self {
            case .primary:
                return AislyColor.primary
            case .secondary:
                return AislyColor.surfaceSecondary
            case .success:
                return AislyColor.success
            case .destructive:
                return AislyColor.error
            case .ghost:
                return .clear
            }
        }

        fileprivate var foregroundColor: Color {
            switch self {
            case .primary:
                return AislyColor.primaryForeground
            case .secondary:
                return AislyColor.textPrimary
            case .success:
                return Color.white
            case .destructive:
                return Color.white
            case .ghost:
                return AislyColor.primary
            }
        }

        fileprivate var borderColor: Color {
            switch self {
            case .ghost:
                return AislyColor.primaryLight
            default:
                return .clear
            }
        }
    }

    enum Size: CaseIterable {
        case small
        case medium
        case large

        fileprivate var minHeight: CGFloat {
            switch self {
            case .small:
                return 36
            case .medium:
                return 44
            case .large:
                return 52
            }
        }

        fileprivate var horizontalPadding: CGFloat {
            switch self {
            case .small:
                return AislySpacing.medium
            case .medium:
                return AislySpacing.large
            case .large:
                return AislySpacing.xxLarge
            }
        }
    }

    private let variant: Variant
    private let size: Size
    private let isFullWidth: Bool

    init(
        variant: Variant = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false
    ) {
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AislyTypography.buttonLabel)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(variant.backgroundColor.opacity(configuration.isPressed ? 0.88 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .stroke(variant.borderColor, lineWidth: variant == .ghost ? 1 : 0)
            )
            .foregroundStyle(variant.foregroundColor.opacity(configuration.role == .cancel ? 0.8 : 1))
            .scaleEffect(configuration.isPressed ? AislyMotion.pressScale : 1)
            .animation(AislyMotion.quick, value: configuration.isPressed)
    }
}
