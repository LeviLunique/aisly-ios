import SwiftUI

struct AislyListRowCard: View {
    enum Tone {
        case active
        case archived

        fileprivate var accentColor: Color {
            switch self {
            case .active:
                return AislyColor.primary
            case .archived:
                return AislyColor.archive
            }
        }

        fileprivate var accentFill: Color {
            switch self {
            case .active:
                return AislyColor.primarySurface
            case .archived:
                return AislyColor.surfaceSecondary
            }
        }

        fileprivate var symbolName: String {
            switch self {
            case .active:
                return "cart"
            case .archived:
                return "archivebox"
            }
        }
    }

    private let title: String
    private let subtitle: Text
    private let tone: Tone

    init(
        title: String,
        subtitle: Text,
        tone: Tone
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tone = tone
    }

    var body: some View {
        AislySurfaceCard {
            HStack(alignment: .top, spacing: AislySpacing.medium) {
                Image(systemName: tone.symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tone.accentColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(tone.accentFill)
                    )

                VStack(alignment: .leading, spacing: AislySpacing.xSmall) {
                    Text(title)
                        .font(AislyTypography.rowTitle)
                        .foregroundStyle(AislyColor.textPrimary)
                    subtitle
                        .font(AislyTypography.rowMetadata)
                        .foregroundStyle(AislyColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
