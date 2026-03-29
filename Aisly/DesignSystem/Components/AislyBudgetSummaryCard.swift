import SwiftUI

struct AislyBudgetSummaryCard: View {
    enum DeltaTone: CaseIterable {
        case neutral
        case underBudget
        case overBudget

        fileprivate var badgeTone: AislyBadge.Tone {
            switch self {
            case .neutral:
                return .neutral
            case .underBudget:
                return .success
            case .overBudget:
                return .error
            }
        }

        fileprivate var iconName: String {
            switch self {
            case .neutral:
                return "minus"
            case .underBudget:
                return "arrow.down"
            case .overBudget:
                return "arrow.up"
            }
        }
    }

    private let title: Text
    private let progressSummary: Text
    private let estimatedLabel: Text
    private let estimatedValue: Text
    private let actualLabel: Text
    private let actualValue: Text
    private let deltaTone: DeltaTone
    private let deltaTitle: Text?
    private let deltaSubtitle: Text?

    init(
        title: Text,
        progressSummary: Text,
        estimatedLabel: Text,
        estimatedValue: Text,
        actualLabel: Text,
        actualValue: Text,
        deltaTone: DeltaTone = .neutral,
        deltaTitle: Text? = nil,
        deltaSubtitle: Text? = nil
    ) {
        self.title = title
        self.progressSummary = progressSummary
        self.estimatedLabel = estimatedLabel
        self.estimatedValue = estimatedValue
        self.actualLabel = actualLabel
        self.actualValue = actualValue
        self.deltaTone = deltaTone
        self.deltaTitle = deltaTitle
        self.deltaSubtitle = deltaSubtitle
    }

    var body: some View {
        AislySurfaceCard {
            VStack(alignment: .leading, spacing: AislySpacing.large) {
                HStack {
                    title
                        .font(AislyTypography.cardTitle)
                        .foregroundStyle(AislyColor.textPrimary)
                    Spacer()
                    progressSummary
                        .font(AislyTypography.caption)
                        .foregroundStyle(AislyColor.textSecondary)
                }

                HStack(spacing: AislySpacing.large) {
                    metricStack(label: estimatedLabel, value: estimatedValue)
                    metricStack(label: actualLabel, value: actualValue)
                }

                if let deltaTitle {
                    HStack(alignment: .top, spacing: AislySpacing.medium) {
                        Image(systemName: deltaTone.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AislyColor.textPrimary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(AislyColor.surfaceSecondary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            AislyBadge(deltaTitle, tone: deltaTone.badgeTone)

                            if let deltaSubtitle {
                                deltaSubtitle
                                    .font(AislyTypography.small)
                                    .foregroundStyle(AislyColor.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func metricStack(label: Text, value: Text) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label
                .font(AislyTypography.metricLabel)
                .foregroundStyle(AislyColor.textSecondary)

            value
                .font(AislyTypography.metricValue)
                .foregroundStyle(AislyColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
