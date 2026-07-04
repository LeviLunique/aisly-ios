import Combine
import Foundation

@MainActor
final class CategoriesViewModel: ObservableObject {
    struct CategoryRow: Identifiable, Equatable {
        let id: String
        let name: String
        let iconName: String
        let colorHex: UInt32
        let itemCount: Int

        init(definition: ShoppingCategoryDefinition, itemCount: Int) {
            id = definition.id
            name = definition.name
            iconName = definition.iconName
            colorHex = definition.colorHex
            self.itemCount = itemCount
        }
    }

    struct CategorySnapshot: Equatable {
        let categories: [CategoryRow]
    }

    enum EditorMode: Equatable, Identifiable {
        case create
        case edit(String)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let categoryID):
                return "edit-\(categoryID)"
            }
        }
    }

    struct PendingDeletion: Identifiable, Equatable {
        let id: String
        let name: String
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(CategorySnapshot)
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var editorMode: EditorMode?
    @Published private(set) var pendingDeletion: PendingDeletion?
    @Published var draftName = ""
    @Published private(set) var draftIconName: String = CategoriesViewModel.defaultDraftIconName
    @Published private(set) var draftColorHex: UInt32 = CategoriesViewModel.defaultDraftColorHex

    let availableIconNames = ShoppingCategoryDefinition.availableIconNames
    let availableColorHexes = ShoppingCategoryDefinition.availableColorHexes

    private let categoryRepository: any ShoppingCategoryRepository
    private let listRepository: any ShoppingListRepository
    private var definitions: [ShoppingCategoryDefinition] = []
    private var lists: [ShoppingList] = []

    private static let fallbackCategory = ShoppingItem.Category.other
    private static let defaultDraftIconName = "cart"
    private static let defaultDraftColorHex: UInt32 = 0x38C4B3

    init(
        categoryRepository: any ShoppingCategoryRepository,
        listRepository: any ShoppingListRepository
    ) {
        self.categoryRepository = categoryRepository
        self.listRepository = listRepository
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
            async let loadedDefinitions = categoryRepository.fetchCategories()
            async let loadedLists = listRepository.fetchLists()

            let definitions = ShoppingCategoryDefinition.normalizedDefinitions(try await loadedDefinitions)
            let lists = try await loadedLists

            self.definitions = definitions.isEmpty ? ShoppingCategoryDefinition.defaultDefinitions : definitions
            self.lists = lists
            state = .loaded(makeSnapshot())
        } catch {
            state = .failed
        }
    }

    func presentCreateCategory() {
        draftName = ""
        draftIconName = Self.defaultDraftIconName
        draftColorHex = Self.defaultDraftColorHex
        editorMode = .create
    }

    func presentEditCategory(id: String) {
        guard let definition = editableDefinitions.first(where: { $0.id == id }) else {
            return
        }

        draftName = definition.name
        draftIconName = definition.iconName
        draftColorHex = definition.colorHex
        editorMode = .edit(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
        draftIconName = Self.defaultDraftIconName
        draftColorHex = Self.defaultDraftColorHex
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

    func saveDraft() async {
        guard
            let editorMode,
            let normalizedName = normalizedDraftName
        else {
            return
        }

        let updatedDefinition = ShoppingCategoryDefinition(
            name: normalizedName,
            iconName: draftIconName,
            colorHex: draftColorHex
        )

        var updatedDefinitions = definitions

        switch editorMode {
        case .create:
            guard updatedDefinitions.contains(where: { $0.category.matches(updatedDefinition.category) }) == false else {
                dismissEditor()
                return
            }

            updatedDefinitions.append(updatedDefinition)

        case .edit(let categoryID):
            guard let index = updatedDefinitions.firstIndex(where: { $0.id == categoryID }) else {
                dismissEditor()
                return
            }

            updatedDefinitions[index] = updatedDefinition
        }

        await persist(definitions: updatedDefinitions)
    }

    func moveCategories(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard editableDefinitions.count > 1 else {
            return
        }

        var reordered = editableDefinitions
        reordered.move(fromOffsets: source, toOffset: destination)

        let updatedDefinitions = ShoppingCategoryDefinition.normalizedDefinitions(reordered)

        Task {
            await persist(definitions: updatedDefinitions)
        }
    }

    func moveCategory(id: String, aheadOf targetID: String) {
        guard
            id != targetID,
            let sourceIndex = editableDefinitions.firstIndex(where: { $0.id == id }),
            let targetIndex = editableDefinitions.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        var reordered = editableDefinitions
        let moved = reordered.remove(at: sourceIndex)
        let adjustedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        reordered.insert(moved, at: adjustedTargetIndex)

        Task {
            await persist(definitions: ShoppingCategoryDefinition.normalizedDefinitions(reordered))
        }
    }

    func presentDeleteConfirmation(id: String) {
        guard let definition = editableDefinitions.first(where: { $0.id == id }) else {
            return
        }

        pendingDeletion = PendingDeletion(id: definition.id, name: definition.name)
    }

    func dismissDeleteConfirmation() {
        pendingDeletion = nil
    }

    func confirmDeletePendingCategory() async {
        guard
            let pendingDeletion,
            let definition = definitions.first(where: { $0.id == pendingDeletion.id })
        else {
            return
        }

        let updatedDefinitions = definitions.filter { $0.id != definition.id }
        let fallback = Self.fallbackCategory
        let updatedLists = lists.map { list in
            list.removingCategory(definition.category, fallback: fallback, updatedAt: Date())
        }

        do {
            try await categoryRepository.saveCategories(
                ShoppingCategoryDefinition.normalizedDefinitions(updatedDefinitions)
            )
            try await listRepository.saveLists(updatedLists)
            definitions = ShoppingCategoryDefinition.normalizedDefinitions(updatedDefinitions)
            lists = updatedLists
            state = .loaded(makeSnapshot())
            dismissDeleteConfirmation()
        } catch {
            dismissDeleteConfirmation()
            state = .failed
        }
    }

    func deleteCategories(ids: Set<String>) async {
        let removedDefinitions = definitions.filter { ids.contains($0.id) }
        guard removedDefinitions.isEmpty == false else {
            return
        }

        let removedCategories = removedDefinitions.map(\.category)
        let updatedDefinitions = definitions.filter { ids.contains($0.id) == false }
        let fallback = Self.fallbackCategory
        let updatedLists = lists.map { list in
            removedCategories.reduce(list) { updatedList, category in
                updatedList.removingCategory(category, fallback: fallback, updatedAt: Date())
            }
        }

        do {
            try await categoryRepository.saveCategories(
                ShoppingCategoryDefinition.normalizedDefinitions(updatedDefinitions)
            )
            try await listRepository.saveLists(updatedLists)
            definitions = ShoppingCategoryDefinition.normalizedDefinitions(updatedDefinitions)
            lists = updatedLists
            state = .loaded(makeSnapshot())
        } catch {
            state = .failed
        }
    }

    private func persist(definitions: [ShoppingCategoryDefinition]) async {
        let normalizedDefinitions = ShoppingCategoryDefinition.normalizedDefinitions(definitions)

        do {
            try await categoryRepository.saveCategories(normalizedDefinitions)
            self.definitions = normalizedDefinitions
            state = .loaded(makeSnapshot())
            dismissEditor()
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    private var editableDefinitions: [ShoppingCategoryDefinition] {
        definitions.filter { $0.category.matches(Self.fallbackCategory) == false }
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private func makeSnapshot() -> CategorySnapshot {
        let counts = itemCounts()
        let rows = editableDefinitions.map { definition in
            CategoryRow(
                definition: definition,
                itemCount: counts[definition.category.normalizedIdentifier] ?? 0
            )
        }

        return CategorySnapshot(categories: rows)
    }

    private func itemCounts() -> [String: Int] {
        lists
            .filter { $0.isArchived == false && $0.isTemplate == false }
            .flatMap(\.items)
            .reduce(into: [String: Int]()) { counts, item in
                counts[item.category.normalizedIdentifier, default: 0] += 1
            }
    }
}
