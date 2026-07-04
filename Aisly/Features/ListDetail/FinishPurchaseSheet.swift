import SwiftUI

/// Confirmation sheet shown before finishing a purchase. Summarizes purchased vs
/// unpurchased items, planned/actual totals, and budget/plan deltas, warns about
/// missing actual prices, and lets the shopper finish or go back to review.
struct FinishPurchaseSheet: View {
    struct Summary: Equatable {
        let listName: String
        let finishedAt: Date
        let purchasedItemCount: Int
        let totalItemCount: Int
        let unpurchasedItemCount: Int
        let missingActualPriceCount: Int
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budget: Decimal?
        let budgetDelta: Decimal?
        let planDelta: Decimal?
    }

    private let summary: Summary
    private let onFinish: () -> Void
    private let onReview: () -> Void
    private let onClose: () -> Void

    init(
        summary: Summary,
        onFinish: @escaping () -> Void,
        onReview: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.summary = summary
        self.onFinish = onFinish
        self.onReview = onReview
        self.onClose = onClose
    }

    var body: some View {
        AislySheetContainer(
            title: Text(verbatim: "Finish Purchase"),
            trailing: {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AislyColor.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(AislyColor.surfaceSecondary))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "Close"))
            },
            content: {
                VStack(alignment: .leading, spacing: AislySpacing.xLarge) {
                    header
                    summaryCard

                    if summary.missingActualPriceCount > 0 {
                        missingPricesWarning
                    }

                    actions

                    Text(verbatim: "Finishing creates a permanent snapshot in History.")
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AislySpacing.xSmall) {
            Text(summary.listName)
                .font(AislyTypography.screenTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(verbatim: relativeTimestamp)
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textSecondary)
        }
    }

    /// "Today, 18:42"-style timestamp, matching the kit.
    private var relativeTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: summary.finishedAt)
    }

    private var summaryCard: some View {
        AislySurfaceCard {
            VStack(spacing: AislySpacing.medium) {
                summaryRow(
                    title: Text(verbatim: "Purchased items"),
                    value: Text(verbatim: "\(summary.purchasedItemCount) of \(summary.totalItemCount)")
                )
                summaryRow(
                    title: Text(verbatim: "Not purchased"),
                    value: Text(verbatim: "\(summary.unpurchasedItemCount) items")
                )

                Divider().overlay(AislyColor.divider)

                summaryRow(
                    title: Text(verbatim: "Planned total"),
                    value: currencyText(summary.plannedTotal)
                )
                summaryRow(
                    title: Text(verbatim: "Actual total"),
                    value: currencyText(summary.actualTotal),
                    isEmphasized: true
                )

                if let budget = summary.budget {
                    summaryRow(
                        title: Text(verbatim: "Budget"),
                        value: currencyText(budget)
                    )
                }

                if let badge = budgetBadge {
                    badgeRow(title: Text(verbatim: "Budget delta"), badge: badge)
                }

                if let badge = planBadge {
                    badgeRow(title: Text(verbatim: "Plan delta"), badge: badge)
                }
            }
        }
    }

    private func badgeRow(title: Text, badge: AislyBadge) -> some View {
        HStack {
            title
                .font(AislyTypography.body)
                .foregroundStyle(AislyColor.textSecondary)
            Spacer()
            badge
        }
    }

    private var budgetBadge: AislyBadge? {
        guard let delta = summary.budgetDelta else {
            return nil
        }

        if delta >= .zero {
            return AislyBadge(Text(verbatim: "\(currencyString(delta)) under"), tone: .success)
        }

        return AislyBadge(Text(verbatim: "\(currencyString(abs(delta))) over"), tone: .error)
    }

    private var planBadge: AislyBadge? {
        guard let delta = summary.planDelta else {
            return nil
        }

        if delta >= .zero {
            return AislyBadge(Text(verbatim: "\(currencyString(delta)) under planned"), tone: .success)
        }

        return AislyBadge(Text(verbatim: "\(currencyString(abs(delta))) over planned"), tone: .error)
    }

    private var missingPricesWarning: some View {
        HStack(alignment: .top, spacing: AislySpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AislyColor.warning)

            Text(verbatim: "\(summary.missingActualPriceCount) purchased items have no actual price. Totals will be saved as partial.")
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AislySpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.secondaryLight)
        )
    }

    private var actions: some View {
        VStack(spacing: AislySpacing.medium) {
            Button(action: onFinish) {
                Text(verbatim: "Finish Anyway")
            }
            .buttonStyle(AislyButtonStyle(variant: .primary, size: .large, isFullWidth: true))

            Button(action: onReview) {
                Text(verbatim: "Review Items")
            }
            .buttonStyle(AislyButtonStyle(variant: .secondary, size: .large, isFullWidth: true))
        }
    }

    private func summaryRow(title: Text, value: Text, isEmphasized: Bool = false) -> some View {
        HStack {
            title
                .font(AislyTypography.body)
                .foregroundStyle(AislyColor.textSecondary)
            Spacer()
            value
                .font(isEmphasized ? AislyTypography.cardTitle : AislyTypography.body)
                .foregroundStyle(AislyColor.textPrimary)
        }
    }

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private func currencyString(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }
}
