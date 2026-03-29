import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @FocusState private var isEditorNameFieldFocused: Bool

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(AppStrings.Home.navigationTitle))
                .toolbar {
                    if viewModel.canCreateList {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.presentCreateList()
                            } label: {
                                Label {
                                    Text(AppStrings.Home.createListToolbarTitle)
                                } icon: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(item: editorModeBinding, onDismiss: handleEditorDismissal) { editorMode in
            editorSheet(editorMode)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView {
                Text(AppStrings.Home.loadingTitle)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let snapshot) where snapshot.activeLists.isEmpty && snapshot.archivedLists.isEmpty:
            ContentUnavailableView {
                Label {
                    Text(AppStrings.Home.emptyTitle)
                } icon: {
                    Image(systemName: "cart")
                }
            } description: {
                Text(AppStrings.Home.emptyDescription)
            } actions: {
                Button {
                    viewModel.presentCreateList()
                } label: {
                    Text(AppStrings.Home.createFirstListButtonTitle)
                }
            }

        case .loaded(let snapshot):
            List {
                if snapshot.activeLists.isEmpty == false {
                    Section {
                        ForEach(snapshot.activeLists) { list in
                            shoppingListRow(list, allowsArchiveActions: true)
                        }
                    } header: {
                        Text(AppStrings.Home.activeListsSectionTitle)
                    }
                }

                if snapshot.archivedLists.isEmpty == false {
                    Section {
                        ForEach(snapshot.archivedLists) { list in
                            shoppingListRow(list, allowsArchiveActions: false)
                        }
                    } header: {
                        Text(AppStrings.Home.archivedListsSectionTitle)
                    }
                }
            }
            .listStyle(.insetGrouped)

        case .failed:
            ContentUnavailableView {
                Label {
                    Text(AppStrings.Home.failureTitle)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } description: {
                Text(AppStrings.Home.failureDescription)
            } actions: {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(AppStrings.Home.retryButtonTitle)
                }
            }
        }
    }

    private func shoppingListRow(
        _ list: HomeViewModel.ListRow,
        allowsArchiveActions: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(list.name)
            Text(list.updatedAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if allowsArchiveActions {
                Button {
                    Task {
                        await viewModel.archiveList(id: list.id)
                    }
                } label: {
                    Text(AppStrings.Home.archiveListActionTitle)
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if allowsArchiveActions {
                Button {
                    viewModel.presentRenameList(id: list.id)
                } label: {
                    Text(AppStrings.Home.renameListActionTitle)
                }
                .tint(.blue)
            }
        }
    }

    private var editorModeBinding: Binding<HomeViewModel.EditorMode?> {
        Binding(
            get: { viewModel.editorMode },
            set: { updatedValue in
                if updatedValue == nil {
                    viewModel.dismissEditor()
                }
            }
        )
    }

    private var draftNameBinding: Binding<String> {
        Binding(
            get: { viewModel.draftName },
            set: { viewModel.updateDraftName($0) }
        )
    }

    @ViewBuilder
    private func editorSheet(_ editorMode: HomeViewModel.EditorMode) -> some View {
        NavigationStack {
            Form {
                TextField(
                    text: draftNameBinding,
                    prompt: Text(AppStrings.Home.listNamePlaceholder)
                ) {
                    Text(AppStrings.Home.listNameFieldTitle)
                }
                .focused($isEditorNameFieldFocused)
            }
            .navigationTitle(Text(editorTitle(for: editorMode)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.dismissEditor()
                    } label: {
                        Text(AppStrings.Common.cancelButtonTitle)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.saveDraft()
                        }
                    } label: {
                        Text(editorActionTitle(for: editorMode))
                    }
                    .disabled(viewModel.isDraftSubmissionDisabled)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task {
            isEditorNameFieldFocused = true
        }
    }

    private func handleEditorDismissal() {
        isEditorNameFieldFocused = false
    }

    private func editorTitle(for editorMode: HomeViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create:
            return AppStrings.Home.createListSheetTitle
        case .rename:
            return AppStrings.Home.renameListSheetTitle
        }
    }

    private func editorActionTitle(for editorMode: HomeViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create:
            return AppStrings.Home.createListConfirmButtonTitle
        case .rename:
            return AppStrings.Home.renameListConfirmButtonTitle
        }
    }
}

#Preview("Empty State") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])))
}

#Preview("Estado Vazio") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])))
        .environment(\.locale, Locale(identifier: "pt_BR"))
}

#Preview("Loaded State") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
        lists: makePreviewShoppingLists(locale: Locale(identifier: "en"))
    )))
}

#Preview("Estado Carregado") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
        lists: makePreviewShoppingLists(locale: Locale(identifier: "pt_BR"))
    )))
    .environment(\.locale, Locale(identifier: "pt_BR"))
}

private func makePreviewShoppingLists(locale: Locale) -> [ShoppingList] {
    [
        ShoppingList(
            id: UUID(),
            name: AppStrings.Mock.ShoppingList.weeklyGroceriesName(locale: locale),
            createdAt: .now,
            updatedAt: .now,
            isArchived: false
        ),
        ShoppingList(
            id: UUID(),
            name: AppStrings.Mock.ShoppingList.partySuppliesName(locale: locale),
            createdAt: .now,
            updatedAt: .now,
            isArchived: true
        )
    ]
}

private struct PreviewShoppingListRepository: ShoppingListRepository {
    let lists: [ShoppingList]

    func fetchLists() async throws -> [ShoppingList] {
        lists
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}
