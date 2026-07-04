import Combine
import Foundation

@MainActor
final class TemplatesViewModel: ObservableObject {
    struct TemplateRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let updatedAt: Date
        let iconName: String
        let colorHex: UInt32
        let itemCount: Int
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budget: Decimal?
        let budgetDelta: Decimal?
        let templateRecurrence: ShoppingList.TemplateRecurrence?
        let isArchived: Bool

        init(list: ShoppingList) {
            id = list.id
            name = list.name
            updatedAt = list.updatedAt
            iconName = list.iconName
            colorHex = list.colorHex
            itemCount = list.items.count
            plannedTotal = list.plannedTotal
            actualTotal = list.actualTotal
            budget = list.budget
            budgetDelta = list.budgetDelta
            templateRecurrence = list.templateRecurrence
            isArchived = list.isArchived
        }
    }

    enum Scope: String, CaseIterable, Identifiable {
        case active
        case archived

        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case name = "Name"
        case itemCount = "Item count"

        var id: String { rawValue }
    }

    struct Snapshot: Equatable {
        let activeTemplates: [TemplateRow]
        let archivedTemplates: [TemplateRow]

        func rows(for scope: Scope) -> [TemplateRow] {
            switch scope {
            case .active:
                return activeTemplates
            case .archived:
                return archivedTemplates
            }
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(Snapshot)
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published var scope: Scope = .active
    @Published var sortOption: SortOption = .manual
    @Published var pendingDeletionID: UUID?
    @Published private(set) var selectedTemplateIDs: Set<UUID> = []
    @Published var isCreateTemplatePresented = false
    @Published private(set) var draftName = ""
    @Published private(set) var draftIconName = ShoppingList.defaultIconName
    @Published private(set) var draftColorHex = ShoppingList.defaultColorHex

    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private var lists: [ShoppingList] = []

    let availableIconNames: [String] = [
        "cart",
        "bag",
        "shippingbox",
        "stopwatch",
        "drop",
        "flame",
        "snowflake",
        "sparkles",
        "gift",
        "heart",
        "pawprint",
        "house",
        "hammer",
        "scissors",
        "bandage",
        "book",
        "gamecontroller",
        "desktopcomputer"
    ]

    let availableColorHexes: [UInt32] = [
        0xFF4545,
        0xFF7A33,
        0xFFD24A,
        0x43BE82,
        0x38C4B3,
        0x38B6EB,
        0x3478F6,
        0x5E6CE6,
        0xE85BA4,
        0xB779E8,
        0xD1B271,
        0x7E8796
    ]

    init(
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.repository = repository
        self.now = now
        self.makeUUID = makeUUID
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
            let loadedLists = try await repository.fetchLists()
            lists = loadedLists
            state = .loaded(makeSnapshot(from: loadedLists))
        } catch {
            state = .failed
        }
    }

    func updateScope(_ scope: Scope) {
        self.scope = scope
        selectedTemplateIDs = []
    }

    func updateSortOption(_ sortOption: SortOption) {
        self.sortOption = sortOption
    }

    func rows(for scope: Scope) -> [TemplateRow] {
        guard case .loaded(let snapshot) = state else {
            return []
        }

        return sortedRows(snapshot.rows(for: scope))
    }

    func presentCreateTemplate() {
        draftName = ""
        draftIconName = ShoppingList.defaultIconName
        draftColorHex = ShoppingList.defaultColorHex
        isCreateTemplatePresented = true
    }

    func dismissCreateTemplate() {
        isCreateTemplatePresented = false
    }

    func updateDraftName(_ name: String) {
        draftName = name
    }

    func updateDraftIconName(_ iconName: String) {
        draftIconName = iconName
    }

    func updateDraftColorHex(_ colorHex: UInt32) {
        draftColorHex = colorHex
    }

    var isDraftSubmissionDisabled: Bool {
        normalizedDraftName == nil
    }

    func saveTemplateDraft() async {
        guard let normalizedDraftName else {
            return
        }

        let template = ShoppingList.make(
            id: makeUUID(),
            name: normalizedDraftName,
            now: now(),
            iconName: draftIconName,
            colorHex: draftColorHex,
            templateConfiguration: .init(recurrence: .weekly)
        )
        let updatedLists = [template] + lists

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            scope = .active
            isCreateTemplatePresented = false
        } catch {
            state = .failed
        }
    }

    func archiveTemplate(id: UUID) async {
        await mutate { current in
            guard current.isArchived == false else {
                return nil
            }
            return current.archived(updatedAt: self.now())
        }(id)
    }

    func unarchiveTemplate(id: UUID) async {
        await mutate { current in
            guard current.isArchived else {
                return nil
            }
            return current.unarchived(updatedAt: self.now())
        }(id)
    }

    func requestDeletion(id: UUID) {
        pendingDeletionID = id
    }

    func toggleSelection(id: UUID) {
        if selectedTemplateIDs.contains(id) {
            selectedTemplateIDs.remove(id)
        } else {
            selectedTemplateIDs.insert(id)
        }
    }

    func selectAllVisible() {
        selectedTemplateIDs = Set(rows(for: scope).map(\.id))
    }

    func select(ids: Set<UUID>) {
        selectedTemplateIDs = ids
    }

    func clearSelection() {
        selectedTemplateIDs = []
    }

    func deleteSelectedTemplates() async {
        let ids = selectedTemplateIDs
        guard ids.isEmpty == false else {
            return
        }

        selectedTemplateIDs = []
        let updatedLists = lists.filter { ids.contains($0.id) == false }

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    func archiveSelectedTemplates() async {
        let ids = selectedTemplateIDs
        guard ids.isEmpty == false else {
            return
        }

        await mutateMany(ids: ids) { current in
            current.archived(updatedAt: self.now())
        }
    }

    func unarchiveSelectedTemplates() async {
        let ids = selectedTemplateIDs
        guard ids.isEmpty == false else {
            return
        }

        await mutateMany(ids: ids) { current in
            current.unarchived(updatedAt: self.now())
        }
    }

    func cancelDeletion() {
        pendingDeletionID = nil
    }

    func confirmDeletion() async {
        guard let id = pendingDeletionID else {
            return
        }

        pendingDeletionID = nil
        let updatedLists = lists.filter { $0.id != id }

        guard updatedLists.count != lists.count else {
            return
        }

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            selectedTemplateIDs.remove(id)
        } catch {
            state = .failed
        }
    }

    var canCreateTemplate: Bool {
        if case .loaded = state {
            return true
        }

        return false
    }

    var pendingDeletionName: String? {
        guard let pendingDeletionID else {
            return nil
        }

        return lists.first(where: { $0.id == pendingDeletionID })?.name
    }

    private func mutate(
        _ transform: @escaping (ShoppingList) -> ShoppingList?
    ) -> (UUID) async -> Void {
        { [weak self] id in
            guard let self else {
                return
            }

            guard
                let index = self.lists.firstIndex(where: { $0.id == id }),
                let updatedList = transform(self.lists[index])
            else {
                return
            }

            var updatedLists = self.lists
            updatedLists[index] = updatedList

            do {
                try await self.repository.saveLists(updatedLists)
                self.lists = updatedLists
                self.state = .loaded(self.makeSnapshot(from: updatedLists))
            } catch {
                self.state = .failed
            }
        }
    }

    private func mutateMany(ids: Set<UUID>, transform: (ShoppingList) -> ShoppingList) async {
        var updatedLists = lists
        var didChange = false

        for index in updatedLists.indices where ids.contains(updatedLists[index].id) {
            updatedLists[index] = transform(updatedLists[index])
            didChange = true
        }

        guard didChange else {
            return
        }

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            selectedTemplateIDs = []
        } catch {
            state = .failed
        }
    }

    private func makeSnapshot(from lists: [ShoppingList]) -> Snapshot {
        let templates = lists.filter(\.isTemplate)
        let activeTemplates = templates
            .filter { !$0.isArchived }
            .sorted(by: listSortComparator)
            .map(TemplateRow.init)
        let archivedTemplates = templates
            .filter(\.isArchived)
            .sorted(by: listSortComparator)
            .map(TemplateRow.init)

        return Snapshot(
            activeTemplates: activeTemplates,
            archivedTemplates: archivedTemplates
        )
    }

    private var listSortComparator: (ShoppingList, ShoppingList) -> Bool {
        { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func sortedRows(_ rows: [TemplateRow]) -> [TemplateRow] {
        switch sortOption {
        case .manual:
            return rows
        case .name:
            return rows.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .itemCount:
            return rows.sorted {
                if $0.itemCount == $1.itemCount {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.itemCount > $1.itemCount
            }
        }
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }
}
