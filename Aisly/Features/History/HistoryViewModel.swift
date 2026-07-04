import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    enum Filter: CaseIterable, Identifiable {
        case all
        case thisMonth
        case threeMonths

        var id: Self { self }
    }

    enum BudgetFilter: String, CaseIterable, Identifiable {
        case any = "Any"
        case under = "Under budget"
        case over = "Over budget"

        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case highestTotal = "Highest total"

        var id: String { rawValue }
    }

    struct HistoryRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let finishedAt: Date
        let actualTotal: Decimal
        let budgetDelta: Decimal?
        let purchasedItemCount: Int
    }

    struct MonthSection: Identifiable, Equatable {
        let id: String
        let title: String
        let rows: [HistoryRow]
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([HistoryRow])
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published var searchQuery = ""
    @Published var filter: Filter = .all
    @Published var budgetFilter: BudgetFilter = .any
    @Published var sortOption: SortOption = .newest

    private let historyRepository: any PurchaseHistoryRepository
    private let listRepository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private var entries: [PurchaseHistoryEntry] = []

    init(
        historyRepository: any PurchaseHistoryRepository,
        listRepository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.historyRepository = historyRepository
        self.listRepository = listRepository
        self.now = now
        self.makeUUID = makeUUID
    }

    var hasAnyEntry: Bool {
        entries.isEmpty == false
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await load()
    }

    func load() async {
        state = .loading

        do {
            entries = try await historyRepository.fetchEntries()
            state = .loaded(rows(from: entries))
        } catch {
            state = .failed
        }
    }

    // Pipeline: period filter → budget filter → search → sort → month grouping.
    var filteredRows: [HistoryRow] {
        sortedEntries(matchingEntries).map(row(from:))
    }

    var sections: [MonthSection] {
        let calendar = Calendar.current
        var order: [String] = []
        var grouped: [String: [HistoryRow]] = [:]

        for row in filteredRows {
            let components = calendar.dateComponents([.year, .month], from: row.finishedAt)
            let key = "\(components.year ?? 0)-\(components.month ?? 0)"
            if grouped[key] == nil {
                order.append(key)
                grouped[key] = []
            }
            grouped[key]?.append(row)
        }

        // For "Highest total" the rows keep their by-total order inside each
        // month, but the months themselves stay ordered by their newest entry.
        if sortOption == .highestTotal {
            order.sort { lhs, rhs in
                let lhsNewest = grouped[lhs]?.map(\.finishedAt).max() ?? .distantPast
                let rhsNewest = grouped[rhs]?.map(\.finishedAt).max() ?? .distantPast
                return lhsNewest > rhsNewest
            }
        }

        return order.compactMap { key in
            guard let rows = grouped[key], let first = rows.first else {
                return nil
            }

            return MonthSection(
                id: key,
                title: Self.monthFormatter.string(from: first.finishedAt),
                rows: rows
            )
        }
    }

    @discardableResult
    func repeatList(historyID: UUID) async -> Bool {
        guard let entry = entries.first(where: { $0.id == historyID }) else {
            return false
        }

        do {
            let activeList = entry.repeatingAsList(
                id: makeUUID(),
                makeItemID: makeUUID,
                finishedAt: now()
            )
            let updatedLists = [activeList] + (try await listRepository.fetchLists())
            try await listRepository.saveLists(updatedLists)
            return true
        } catch {
            state = .failed
            return false
        }
    }

    /// Returns true when the template was persisted, so the view can show
    /// success feedback only for real saves.
    @discardableResult
    func createTemplate(historyID: UUID) async -> Bool {
        guard let entry = entries.first(where: { $0.id == historyID }) else {
            return false
        }

        do {
            let activeList = entry.repeatingAsList(
                id: makeUUID(),
                makeItemID: makeUUID,
                finishedAt: now(),
                useActualPricesAsPlan: true
            )
            let template = activeList.makingTemplate(
                id: makeUUID(),
                name: entry.name,
                recurrence: .weekly,
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let updatedLists = [template] + (try await listRepository.fetchLists())
            try await listRepository.saveLists(updatedLists)
            return true
        } catch {
            state = .failed
            return false
        }
    }

    func deleteHistory(id: UUID) async {
        await deleteEntries(ids: [id])
    }

    func deleteEntries(ids: Set<UUID>) async {
        do {
            let updatedEntries = entries.filter { ids.contains($0.id) == false }
            try await historyRepository.saveEntries(updatedEntries)
            entries = updatedEntries
            state = .loaded(rows(from: updatedEntries))
        } catch {
            state = .failed
        }
    }

    // MARK: - Filtering / sorting

    private var matchingEntries: [PurchaseHistoryEntry] {
        let query = Self.normalized(searchQuery)

        return entries.filter { entry in
            guard filter.matches(finishedAt: entry.finishedAt, now: now()) else {
                return false
            }

            guard budgetFilter.matches(budgetDelta: entry.budgetDelta) else {
                return false
            }

            guard query.isEmpty == false else {
                return true
            }

            if Self.normalized(entry.name).contains(query) {
                return true
            }

            return entry.sections.contains { section in
                section.items.contains { item in
                    Self.normalized(item.name).contains(query)
                }
            }
        }
    }

    private func sortedEntries(_ entries: [PurchaseHistoryEntry]) -> [PurchaseHistoryEntry] {
        switch sortOption {
        case .newest:
            return entries.sorted { $0.finishedAt > $1.finishedAt }
        case .oldest:
            return entries.sorted { $0.finishedAt < $1.finishedAt }
        case .highestTotal:
            return entries.sorted { $0.actualTotal > $1.actualTotal }
        }
    }

    private func rows(from entries: [PurchaseHistoryEntry]) -> [HistoryRow] {
        entries
            .sorted { lhs, rhs in
                lhs.finishedAt > rhs.finishedAt
            }
            .map(row(from:))
    }

    private func row(from entry: PurchaseHistoryEntry) -> HistoryRow {
        HistoryRow(
            id: entry.id,
            name: entry.name,
            finishedAt: entry.finishedAt,
            actualTotal: entry.actualTotal,
            budgetDelta: entry.budgetDelta,
            purchasedItemCount: entry.purchasedItemCount
        )
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()
}

private extension HistoryViewModel.Filter {
    func matches(finishedAt: Date, now: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .thisMonth:
            return Calendar.current.isDate(finishedAt, equalTo: now, toGranularity: .month)
        case .threeMonths:
            guard let cutoff = Calendar.current.date(byAdding: .month, value: -3, to: now) else {
                return true
            }
            return finishedAt >= cutoff
        }
    }
}

private extension HistoryViewModel.BudgetFilter {
    func matches(budgetDelta: Decimal?) -> Bool {
        switch self {
        case .any:
            return true
        case .under:
            return budgetDelta.map { $0 >= .zero } ?? false
        case .over:
            return budgetDelta.map { $0 < .zero } ?? false
        }
    }
}
