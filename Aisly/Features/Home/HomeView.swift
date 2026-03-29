import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let makeListDetailViewModel: @MainActor (UUID) -> ListDetailViewModel
    @FocusState private var isEditorNameFieldFocused: Bool

    init(
        viewModel: HomeViewModel,
        makeListDetailViewModel: @escaping @MainActor (UUID) -> ListDetailViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeListDetailViewModel = makeListDetailViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .background(AislyColor.backgroundPrimary.ignoresSafeArea())
                .navigationTitle(Text(AppStrings.Home.navigationTitle))
                .navigationDestination(for: UUID.self) { listID in
                    ListDetailView(viewModel: makeListDetailViewModel(listID))
                }
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
                            .tint(AislyColor.primary)
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
            AislyLoadingState(message: AppStrings.Home.loadingTitle)

        case .loaded(let snapshot) where snapshot.activeLists.isEmpty && snapshot.archivedLists.isEmpty:
            AislyEmptyState(
                icon: AislyMark(size: .large),
                title: AppStrings.Home.emptyTitle,
                description: AppStrings.Home.emptyDescription
            ) {
                Button {
                    viewModel.presentCreateList()
                } label: {
                    Text(AppStrings.Home.createFirstListButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }

        case .loaded(let snapshot):
            List {
                if snapshot.activeLists.isEmpty == false {
                    Section {
                        ForEach(snapshot.activeLists) { list in
                            shoppingListRow(list, allowsArchiveActions: true)
                        }
                    } header: {
                        AislySectionHeader(AppStrings.Home.activeListsSectionTitle)
                    }
                }

                if snapshot.archivedLists.isEmpty == false {
                    Section {
                        ForEach(snapshot.archivedLists) { list in
                            shoppingListRow(list, allowsArchiveActions: false)
                        }
                    } header: {
                        AislySectionHeader(AppStrings.Home.archivedListsSectionTitle)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundPrimary)

        case .failed:
            AislyEmptyState(
                icon:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(AislyColor.error),
                title: AppStrings.Home.failureTitle,
                description: AppStrings.Home.failureDescription
            ) {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(AppStrings.Home.retryButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    private func shoppingListRow(
        _ list: HomeViewModel.ListRow,
        allowsArchiveActions: Bool
    ) -> some View {
        let rowCard = AislyListRowCard(
            title: list.name,
            subtitle: Text(
                list.updatedAt,
                format: .dateTime.month(.abbreviated).day().year().hour().minute()
            ),
            tone: allowsArchiveActions ? .active : .archived
        )

        let navigationWrappedRow = Group {
            if allowsArchiveActions {
                NavigationLink(value: list.id) {
                    rowCard
                }
            } else {
                rowCard
            }
        }

        return navigationWrappedRow
            .listRowInsets(
            EdgeInsets(
                top: AislySpacing.small,
                leading: AislySpacing.large,
                bottom: AislySpacing.small,
                trailing: AislySpacing.large
            )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if allowsArchiveActions {
                    Button {
                        Task {
                            await viewModel.archiveList(id: list.id)
                        }
                    } label: {
                        Text(AppStrings.Home.archiveListActionTitle)
                    }
                    .tint(AislyColor.warning)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if allowsArchiveActions {
                    Button {
                        viewModel.presentRenameList(id: list.id)
                    } label: {
                        Text(AppStrings.Home.renameListActionTitle)
                    }
                    .tint(AislyColor.primary)
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
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundSecondary)
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
                    .tint(AislyColor.primary)
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
    HomeView(
        viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])),
        makeListDetailViewModel: { listID in
            ListDetailViewModel(listID: listID, repository: PreviewShoppingListRepository(lists: []))
        }
    )
}

#Preview("Estado Vazio") {
    HomeView(
        viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])),
        makeListDetailViewModel: { listID in
            ListDetailViewModel(listID: listID, repository: PreviewShoppingListRepository(lists: []))
        }
    )
        .environment(\.locale, Locale(identifier: "pt_BR"))
}

#Preview("Loaded State") {
    HomeView(
        viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
            lists: makePreviewShoppingLists(locale: Locale(identifier: "en"))
        )),
        makeListDetailViewModel: { listID in
            ListDetailViewModel(
                listID: listID,
                repository: PreviewShoppingListRepository(
                    lists: makePreviewShoppingLists(locale: Locale(identifier: "en"))
                )
            )
        }
    )
}

#Preview("Estado Carregado") {
    HomeView(
        viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
            lists: makePreviewShoppingLists(locale: Locale(identifier: "pt_BR"))
        )),
        makeListDetailViewModel: { listID in
            ListDetailViewModel(
                listID: listID,
                repository: PreviewShoppingListRepository(
                    lists: makePreviewShoppingLists(locale: Locale(identifier: "pt_BR"))
                )
            )
        }
    )
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
