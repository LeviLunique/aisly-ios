import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    struct ListRow: Identifiable, Equatable {
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
        let missingPriceCount: Int
        let templateRecurrence: ShoppingList.TemplateRecurrence?
        let isPinned: Bool

        init(
            id: UUID,
            name: String,
            updatedAt: Date,
            iconName: String = ShoppingList.defaultIconName,
            colorHex: UInt32 = ShoppingList.defaultColorHex,
            itemCount: Int = 0,
            plannedTotal: Decimal = .zero,
            actualTotal: Decimal = .zero,
            budget: Decimal? = nil,
            budgetDelta: Decimal? = nil,
            missingPriceCount: Int = 0,
            templateRecurrence: ShoppingList.TemplateRecurrence? = nil,
            isPinned: Bool = false
        ) {
            self.id = id
            self.name = name
            self.updatedAt = updatedAt
            self.iconName = iconName
            self.colorHex = colorHex
            self.itemCount = itemCount
            self.plannedTotal = plannedTotal
            self.actualTotal = actualTotal
            self.budget = budget
            self.budgetDelta = budgetDelta
            self.missingPriceCount = missingPriceCount
            self.templateRecurrence = templateRecurrence
            self.isPinned = isPinned
        }

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
            missingPriceCount = list.itemsMissingActualPriceCount
            templateRecurrence = list.templateRecurrence
            isPinned = list.isPinned
        }
    }

    struct ListSnapshot: Equatable {
        let activeLists: [ListRow]
        let templateLists: [ListRow]
        let archivedLists: [ListRow]

        init(
            activeLists: [ListRow],
            templateLists: [ListRow] = [],
            archivedLists: [ListRow]
        ) {
            self.activeLists = activeLists
            self.templateLists = templateLists
            self.archivedLists = archivedLists
        }
    }

    enum EditorMode: Equatable, Identifiable {
        case create
        case rename(UUID)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .rename(let id):
                return "rename-\(id.uuidString)"
            }
        }
    }

    enum CreateListTab: String, CaseIterable, Identifiable {
        case newList
        case templates

        var id: String { rawValue }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(ListSnapshot)
        case failed
    }

    struct TemplateEditorState: Equatable, Identifiable {
        let sourceListID: UUID

        var id: UUID {
            sourceListID
        }
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var editorMode: EditorMode?
    @Published private(set) var templateEditorState: TemplateEditorState?
    @Published private(set) var draftName = ""
    @Published private(set) var draftBudget = ""
    @Published private(set) var draftIconName = ShoppingList.defaultIconName
    @Published private(set) var draftColorHex = ShoppingList.defaultColorHex
    @Published private(set) var createListTab: CreateListTab = .newList
    @Published private(set) var templateDraftName = ""
    @Published private(set) var templateDraftRecurrence: ShoppingList.TemplateRecurrence = .weekly

    let availableIconNames = ShoppingList.availableIconNames
    let availableColorHexes = ShoppingList.availableColorHexes

    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private let locale: Locale
    private var lists: [ShoppingList] = []

    init(
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.now = now
        self.makeUUID = makeUUID
        self.locale = locale
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await load()
    }

    func load() async {
        state = .loading
        await reload()
    }

    /// Refetches lists without flashing the loading state — used when
    /// returning to Home after a pushed screen may have mutated the store
    /// (finish purchase archives the list, detail screens delete/archive).
    func reload() async {
        do {
            let loadedLists = try await repository.fetchLists()
            lists = loadedLists
            state = .loaded(makeSnapshot(from: loadedLists))
        } catch {
            state = .failed
        }
    }

    func presentCreateList() {
        draftName = ""
        draftBudget = ""
        draftIconName = ShoppingList.defaultIconName
        draftColorHex = ShoppingList.defaultColorHex
        createListTab = .newList
        editorMode = .create
    }

    func presentRenameList(id: UUID) {
        guard let list = lists.first(where: { $0.id == id }) else {
            return
        }

        draftName = list.name
        draftBudget = draftString(for: list.budget)
        draftIconName = list.iconName
        draftColorHex = list.colorHex
        createListTab = .newList
        editorMode = .rename(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
        draftBudget = ""
        draftIconName = ShoppingList.defaultIconName
        draftColorHex = ShoppingList.defaultColorHex
        createListTab = .newList
    }

    func presentCreateTemplate(fromListID id: UUID) {
        guard let list = lists.first(where: { $0.id == id && $0.isArchived == false && $0.isTemplate == false }) else {
            return
        }

        templateDraftName = list.name
        templateDraftRecurrence = .weekly
        templateEditorState = .init(sourceListID: id)
    }

    func dismissTemplateEditor() {
        templateEditorState = nil
        templateDraftName = ""
        templateDraftRecurrence = .weekly
    }

    func updateDraftName(_ draftName: String) {
        self.draftName = draftName
    }

    func updateDraftBudget(_ draftBudget: String) {
        self.draftBudget = draftBudget
    }

    func updateDraftIconName(_ iconName: String) {
        draftIconName = iconName
    }

    func updateDraftColorHex(_ colorHex: UInt32) {
        draftColorHex = colorHex
    }

    func updateCreateListTab(_ tab: CreateListTab) {
        createListTab = tab
    }

    func updateTemplateDraftName(_ draftName: String) {
        templateDraftName = draftName
    }

    func updateTemplateDraftRecurrence(_ recurrence: ShoppingList.TemplateRecurrence) {
        templateDraftRecurrence = recurrence
    }

    func saveDraft() async {
        guard
            let editorMode,
            let normalizedName = normalizedDraftName,
            areDraftPricesValid
        else {
            return
        }

        do {
            let updatedLists: [ShoppingList]

            switch editorMode {
            case .create:
                updatedLists = [
                    ShoppingList.make(
                        id: makeUUID(),
                        name: normalizedName,
                        now: now(),
                        budget: normalizedDraftBudget,
                        iconName: draftIconName,
                        colorHex: draftColorHex
                    )
                ] + lists

            case .rename(let listID):
                updatedLists = try updateListInfo(id: listID, name: normalizedName)
            }

            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            dismissEditor()
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func archiveList(id: UUID) async {
        do {
            let updatedLists = try archiveListLocally(id: id)
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func unarchiveList(id: UUID) async {
        do {
            let updatedLists = try unarchiveListLocally(id: id)
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func saveTemplateDraft() async {
        guard
            let templateEditorState,
            let normalizedTemplateDraftName,
            let sourceList = lists.first(where: { $0.id == templateEditorState.sourceListID && $0.isTemplate == false })
        else {
            return
        }

        do {
            let templateList = sourceList.makingTemplate(
                id: makeUUID(),
                name: normalizedTemplateDraftName,
                recurrence: templateDraftRecurrence,
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let updatedLists = [templateList] + lists

            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            dismissTemplateEditor()
        } catch {
            dismissTemplateEditor()
            state = .failed
        }
    }

    func generateList(fromTemplateID id: UUID) async {
        _ = await generateListReturningID(fromTemplateID: id)
    }

    /// Generates an active list from a template and returns the new list's id so
    /// the caller can navigate to it. Returns `nil` on failure or if the template
    /// cannot be found.
    @discardableResult
    func generateListReturningID(fromTemplateID id: UUID) async -> UUID? {
        guard let templateList = lists.first(where: { $0.id == id && $0.isTemplate }) else {
            return nil
        }

        do {
            let generatedList = templateList.generatingListFromTemplate(
                id: makeUUID(),
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let updatedLists = [generatedList] + lists

            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            dismissEditor()
            return generatedList.id
        } catch {
            dismissTemplateEditor()
            state = .failed
            return nil
        }
    }

    /// Creates a brand-new active list from the current draft state and returns
    /// its id so the caller can push the detail screen. Returns `nil` when the
    /// draft is invalid.
    @discardableResult
    func createListReturningID() async -> UUID? {
        guard
            let normalizedName = normalizedDraftName,
            areDraftPricesValid
        else {
            return nil
        }

        let newList = ShoppingList.make(
            id: makeUUID(),
            name: normalizedName,
            now: now(),
            budget: normalizedDraftBudget,
            iconName: draftIconName,
            colorHex: draftColorHex
        )

        do {
            let updatedLists = [newList] + lists
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            dismissEditor()
            return newList.id
        } catch {
            dismissEditor()
            state = .failed
            return nil
        }
    }

    func deleteList(id: UUID) async {
        await deleteLists(ids: [id])
    }

    /// Toggles the pinned state of an active list (pinned lists float to the top).
    func togglePin(id: UUID) async {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            return
        }

        do {
            var updatedLists = lists
            updatedLists[index] = updatedLists[index].pinned(!updatedLists[index].isPinned, updatedAt: now())
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    /// Rearranges the stored order of the active (non-archived, non-template)
    /// lists to match `orderedIDs` — backs Home's drag-to-reorder. Non-active
    /// lists keep their positions.
    func reorderActiveLists(orderedIDs: [UUID]) async {
        let activeByID = Dictionary(
            uniqueKeysWithValues: lists
                .filter { !$0.isArchived && !$0.isTemplate }
                .map { ($0.id, $0) }
        )
        let reorderedActive = orderedIDs.compactMap { activeByID[$0] }
        guard reorderedActive.count == activeByID.count else {
            return
        }

        var iterator = reorderedActive.makeIterator()
        let updatedLists = lists.map { list -> ShoppingList in
            if !list.isArchived && !list.isTemplate, let next = iterator.next() {
                return next
            }
            return list
        }

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    /// Archives several lists at once (used by the Home selection bar).
    func archiveLists(ids: Set<UUID>) async {
        guard ids.isEmpty == false else {
            return
        }

        do {
            let timestamp = now()
            let updatedLists = lists.map { list in
                ids.contains(list.id) && list.isArchived == false
                    ? list.archived(updatedAt: timestamp)
                    : list
            }
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    /// Permanently deletes several lists at once (used by the Home selection bar).
    func deleteLists(ids: Set<UUID>) async {
        guard ids.isEmpty == false else {
            return
        }

        do {
            let updatedLists = lists.filter { ids.contains($0.id) == false }
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    /// Applies edited metadata (name, budget, appearance) to an existing list —
    /// used by the List Info sheet on Home.
    func updateListInfo(
        id: UUID,
        name: String,
        budget: Decimal?,
        iconName: String,
        colorHex: UInt32
    ) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            return
        }

        do {
            guard let index = lists.firstIndex(where: { $0.id == id }) else {
                throw HomeViewModelError.listNotFound
            }

            let timestamp = now()
            var updatedList = lists[index]
                .renamed(to: trimmedName, updatedAt: timestamp)
                .updatingAppearance(iconName: iconName, colorHex: colorHex, updatedAt: timestamp)
            updatedList.budget = budget

            var updatedLists = lists
            updatedLists[index] = updatedList

            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    /// The full domain list backing a row, for populating info/edit sheets.
    func list(for id: UUID) -> ShoppingList? {
        lists.first { $0.id == id }
    }

    var isDraftSubmissionDisabled: Bool {
        guard
            let normalizedDraftName,
            areDraftPricesValid
        else {
            return true
        }

        switch editorMode {
        case .create:
            return normalizedDraftName.isEmpty
        case .rename(let id):
            guard let existingList = lists.first(where: { $0.id == id }) else {
                return true
            }

            return existingList.name == normalizedDraftName &&
                existingList.budget == normalizedDraftBudget &&
                existingList.iconName == draftIconName &&
                existingList.colorHex == draftColorHex
        case .none:
            return true
        }
    }

    var canCreateList: Bool {
        if case .loaded = state {
            return true
        }

        return false
    }

    var isTemplateDraftSubmissionDisabled: Bool {
        guard normalizedTemplateDraftName != nil else {
            return true
        }

        return templateEditorState == nil
    }

    private func makeSnapshot(from lists: [ShoppingList]) -> ListSnapshot {
        // Manual order preserves the stored array order (what drag-to-reorder
        // rearranges), with pinned lists kept on top.
        let active = lists.filter { !$0.isArchived && !$0.isTemplate }
        let activeLists = (active.filter(\.isPinned) + active.filter { !$0.isPinned })
            .map(ListRow.init)
        let templateLists = lists
            .filter { !$0.isArchived && $0.isTemplate }
            .sorted(by: listSortComparator)
            .map(ListRow.init)
        let archivedLists = lists
            .filter(\.isArchived)
            .sorted(by: listSortComparator)
            .map(ListRow.init)

        return ListSnapshot(
            activeLists: activeLists,
            templateLists: templateLists,
            archivedLists: archivedLists
        )
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedName.isEmpty ? nil : trimmedName
    }

    private var normalizedTemplateDraftName: String? {
        let trimmedName = templateDraftName.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedName.isEmpty ? nil : trimmedName
    }

    private var normalizedDraftBudget: Decimal? {
        normalizedPrice(from: draftBudget)
    }

    private var areDraftPricesValid: Bool {
        isValidPriceDraft(draftBudget)
    }

    private var listSortComparator: (ShoppingList, ShoppingList) -> Bool {
        { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func updateListInfo(id: UUID, name: String) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            throw HomeViewModelError.listNotFound
        }

        let timestamp = now()
        var updatedList = lists[index]
            .renamed(to: name, updatedAt: timestamp)
            .updatingAppearance(iconName: draftIconName, colorHex: draftColorHex, updatedAt: timestamp)
        updatedList.budget = normalizedDraftBudget

        var updatedLists = lists
        updatedLists[index] = updatedList
        return updatedLists
    }

    private func archiveListLocally(id: UUID) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            throw HomeViewModelError.listNotFound
        }

        guard lists[index].isArchived == false else {
            return lists
        }

        var updatedLists = lists
        updatedLists[index] = updatedLists[index].archived(updatedAt: now())
        return updatedLists
    }

    private func unarchiveListLocally(id: UUID) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            throw HomeViewModelError.listNotFound
        }

        guard lists[index].isArchived else {
            return lists
        }

        var updatedLists = lists
        updatedLists[index] = updatedLists[index].unarchived(updatedAt: now())
        return updatedLists
    }

    private func draftString(for price: Decimal?) -> String {
        guard let price else {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    private func isValidPriceDraft(_ priceDraft: String) -> Bool {
        let trimmedDraft = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDraft.isEmpty || normalizedPrice(from: trimmedDraft) != nil
    }

    private func normalizedPrice(from priceDraft: String) -> Decimal? {
        let trimmedDraft = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedDraft.isEmpty == false else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true

        let fallbackInputs = [trimmedDraft]
            + [trimmedDraft.replacingOccurrences(of: ",", with: ".")]
            + [trimmedDraft.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")]

        for input in fallbackInputs {
            guard let number = formatter.number(from: input) else {
                continue
            }

            let decimal = number.decimalValue
            guard decimal >= .zero else {
                return nil
            }

            return decimal
        }

        return nil
    }
}

private enum HomeViewModelError: Error {
    case listNotFound
}
