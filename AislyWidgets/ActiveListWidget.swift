import AppIntents
import SwiftUI
import WidgetKit

struct ActiveListWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "appleSurface.widget.configuration.title"
    static let description = IntentDescription(
        LocalizedStringResource("appleSurface.widget.configuration.description")
    )

    @Parameter(title: "appleSurface.list.parameter.title")
    var list: ShoppingListAppEntity?

    init() {
    }
}

struct ActiveListWidgetEntry: TimelineEntry {
    let date: Date
    let list: ShoppingList?
}

struct ActiveListWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ActiveListWidgetEntry {
        ActiveListWidgetEntry(date: .now, list: nil)
    }

    func snapshot(
        for configuration: ActiveListWidgetConfigurationIntent,
        in context: Context
    ) async -> ActiveListWidgetEntry {
        await makeEntry(for: configuration)
    }

    func timeline(
        for configuration: ActiveListWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<ActiveListWidgetEntry> {
        let entry = await makeEntry(for: configuration)
        return Timeline(
            entries: [entry],
            policy: .after(Date().addingTimeInterval(15 * 60))
        )
    }

    private func makeEntry(
        for configuration: ActiveListWidgetConfigurationIntent
    ) async -> ActiveListWidgetEntry {
        do {
            let list = try await selectedList(for: configuration)
            return ActiveListWidgetEntry(date: .now, list: list)
        } catch {
            return ActiveListWidgetEntry(date: .now, list: nil)
        }
    }

    private func selectedList(
        for configuration: ActiveListWidgetConfigurationIntent
    ) async throws -> ShoppingList? {
        if let selectedID = configuration.list?.id {
            return try await AppleSurfaceListStore.fetchActiveList(id: selectedID)
        }

        return try await AppleSurfaceListStore.fetchActiveLists().first
    }
}

struct ActiveListWidget: Widget {
    private let kind = "ActiveListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ActiveListWidgetConfigurationIntent.self,
            provider: ActiveListWidgetProvider()
        ) { entry in
            ActiveListWidgetView(entry: entry)
                .containerBackground(AislyColor.surfacePrimary, for: .widget)
        }
        .configurationDisplayName(AppStrings.AppleSurface.activeListWidgetTitle)
        .description(AppStrings.AppleSurface.activeListWidgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ActiveListWidgetView: View {
    let entry: ActiveListWidgetEntry

    var body: some View {
        if let list = entry.list {
            populatedContent(list)
                .widgetURL(widgetURL(for: list))
        } else {
            emptyContent
                .widgetURL(AppRoute.home.url)
        }
    }

    private func populatedContent(_ list: ShoppingList) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            Text(AppStrings.AppleSurface.activeListWidgetTitle)
                .font(AislyTypography.small.weight(.semibold))
                .foregroundStyle(AislyColor.textSecondary)

            Text(verbatim: list.name)
                .font(AislyTypography.cardTitle)
                .foregroundStyle(AislyColor.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack(spacing: AislySpacing.small) {
                metric(
                    title: AppStrings.ShoppingMode.progressTitle,
                    value: Text(list.completedItemCount, format: .number) + Text(verbatim: " / ") + Text(list.items.count, format: .number)
                )
                metric(
                    title: AppStrings.ListDetail.budgetSummaryTitle,
                    value: currencyText(list.actualTotal)
                )
            }

            ProgressView(value: progressValue(for: list))
                .tint(AislyColor.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AislySpacing.large)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            Image(systemName: "rectangle.grid.1x2")
                .font(.title2)
                .foregroundStyle(AislyColor.primary)

            Text(AppStrings.AppleSurface.emptyWidgetTitle)
                .font(AislyTypography.cardTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(AppStrings.AppleSurface.emptyWidgetDescription)
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textSecondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AislySpacing.large)
    }

    private func metric(title: LocalizedStringResource, value: Text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AislyTypography.small.weight(.semibold))
                .foregroundStyle(AislyColor.textTertiary)

            value
                .font(AislyTypography.caption.weight(.semibold))
                .foregroundStyle(AislyColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressValue(for list: ShoppingList) -> Double {
        guard list.items.isEmpty == false else {
            return 0
        }

        return Double(list.completedItemCount) / Double(list.items.count)
    }

    private func widgetURL(for list: ShoppingList) -> URL {
        list.items.isEmpty ? AppRoute.listDetail(list.id).url : AppRoute.shoppingMode(list.id).url
    }

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }
}
