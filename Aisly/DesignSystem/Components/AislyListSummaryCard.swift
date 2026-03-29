import SwiftUI

struct AislyListSummaryCard<LeadingIcon: View, Accessory: View>: View {
    private let title: String
    private let subtitle: Text?
    private let progressSummary: Text?
    private let progressValue: Double?
    private let progressMaximum: Double
    private let estimatedSummary: Text?
    private let actualSummary: Text?
    private let deltaBadge: Text?
    private let leadingIcon: LeadingIcon
    private let accessory: Accessory

    init(
        title: String,
        subtitle: Text? = nil,
        progressSummary: Text? = nil,
        progressValue: Double? = nil,
        progressMaximum: Double = 100,
        estimatedSummary: Text? = nil,
        actualSummary: Text? = nil,
        deltaBadge: Text? = nil,
        @ViewBuilder leadingIcon: () -> LeadingIcon,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progressSummary = progressSummary
        self.progressValue = progressValue
        self.progressMaximum = progressMaximum
        self.estimatedSummary = estimatedSummary
        self.actualSummary = actualSummary
        self.deltaBadge = deltaBadge
        self.leadingIcon = leadingIcon()
        self.accessory = accessory()
    }

    var body: some View {
        AislySurfaceCard {
            VStack(alignment: .leading, spacing: AislySpacing.medium) {
                HStack(alignment: .top, spacing: AislySpacing.medium) {
                    leadingIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AislyTypography.cardTitle)
                            .foregroundStyle(AislyColor.textPrimary)

                        subtitle?
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    accessory
                }

                if let progressValue, let progressSummary {
                    VStack(alignment: .leading, spacing: AislySpacing.small) {
                        progressSummary
                            .font(AislyTypography.small)
                            .foregroundStyle(AislyColor.textSecondary)

                        AislyProgressBar(value: progressValue, maximum: progressMaximum)
                    }
                }

                if estimatedSummary != nil || actualSummary != nil || deltaBadge != nil {
                    HStack(alignment: .center, spacing: AislySpacing.medium) {
                        estimatedSummary?
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textSecondary)

                        Spacer(minLength: 0)

                        actualSummary?
                            .font(AislyTypography.caption.weight(.semibold))
                            .foregroundStyle(AislyColor.textPrimary)

                        if let deltaBadge {
                            AislyBadge(deltaBadge, tone: .warning, size: .small)
                        }
                    }
                }
            }
        }
    }
}

extension AislyListSummaryCard where LeadingIcon == EmptyView, Accessory == EmptyView {
    init(
        title: String,
        subtitle: Text? = nil,
        progressSummary: Text? = nil,
        progressValue: Double? = nil,
        progressMaximum: Double = 100,
        estimatedSummary: Text? = nil,
        actualSummary: Text? = nil,
        deltaBadge: Text? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            progressSummary: progressSummary,
            progressValue: progressValue,
            progressMaximum: progressMaximum,
            estimatedSummary: estimatedSummary,
            actualSummary: actualSummary,
            deltaBadge: deltaBadge,
            leadingIcon: { EmptyView() },
            accessory: { EmptyView() }
        )
    }
}
