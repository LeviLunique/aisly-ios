import SwiftUI

struct AislyBadge: View {
    enum Tone: CaseIterable {
        case neutral
        case primary
        case success
        case warning
        case error
        case archive

        fileprivate var backgroundColor: Color {
            switch self {
            case .neutral:
                return AislyColor.surfaceSecondary
            case .primary:
                return AislyColor.primaryLight
            case .success:
                return AislyColor.successLight
            case .warning:
                return AislyColor.secondaryLight
            case .error:
                return AislyColor.error.opacity(0.14)
            case .archive:
                return AislyColor.archiveLight
            }
        }

        fileprivate var foregroundColor: Color {
            switch self {
            case .neutral:
                return AislyColor.textSecondary
            case .primary:
                return AislyColor.primaryStrong
            case .success:
                return AislyColor.success
            case .warning:
                return AislyColor.warning
            case .error:
                return AislyColor.error
            case .archive:
                return AislyColor.archive
            }
        }
    }

    enum Size: CaseIterable {
        case small
        case medium

        fileprivate var horizontalPadding: CGFloat {
            switch self {
            case .small:
                return AislySpacing.small
            case .medium:
                return AislySpacing.medium
            }
        }

        fileprivate var verticalPadding: CGFloat {
            switch self {
            case .small:
                return 2
            case .medium:
                return 4
            }
        }

        fileprivate var font: Font {
            switch self {
            case .small:
                return AislyTypography.small.weight(.semibold)
            case .medium:
                return AislyTypography.caption.weight(.semibold)
            }
        }
    }

    private let text: Text
    private let tone: Tone
    private let size: Size

    init(
        _ text: Text,
        tone: Tone = .neutral,
        size: Size = .medium
    ) {
        self.text = text
        self.tone = tone
        self.size = size
    }

    var body: some View {
        text
            .font(size.font)
            .foregroundStyle(tone.foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.backgroundColor)
            )
    }
}
