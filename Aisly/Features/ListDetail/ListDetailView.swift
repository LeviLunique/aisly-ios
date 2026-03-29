import SwiftUI

struct ListDetailView: View {
    @StateObject private var viewModel: ListDetailViewModel

    init(viewModel: ListDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: editorModeBinding) { editorMode in
                editorSheet(editorMode)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.ListDetail.loadingTitle)

        case .loaded(let snapshot) where snapshot.items.isEmpty:
            AislyEmptyState(
                icon: Image(systemName: "list.bullet.clipboard"),
                title: AppStrings.ListDetail.emptyTitle,
                description: AppStrings.ListDetail.emptyDescription
            ) {
                Button {
                    viewModel.presentCreateItem()
                } label: {
                    Text(AppStrings.ListDetail.createFirstItemButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
            .navigationTitle(Text(snapshot.listName))
            .toolbar {
                itemToolbar
            }

        case .loaded(let snapshot):
            List {
                Section {
                    ForEach(snapshot.items) { item in
                        itemRow(item)
                    }
                    .onMove(perform: handleMove)
                } header: {
                    AislySectionHeader(AppStrings.ListDetail.itemsSectionTitle)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundPrimary)
            .navigationTitle(Text(snapshot.listName))
            .toolbar {
                itemToolbar
            }

        case .failed:
            AislyEmptyState(
                icon:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(AislyColor.error),
                title: AppStrings.ListDetail.failureTitle,
                description: AppStrings.ListDetail.failureDescription
            ) {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(AppStrings.ListDetail.retryButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    @ToolbarContentBuilder
    private var itemToolbar: some ToolbarContent {
        if viewModel.canReorderItems {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }

        if viewModel.canCreateItem {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentCreateItem()
                } label: {
                    Label {
                        Text(AppStrings.ListDetail.addItemToolbarTitle)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .tint(AislyColor.primary)
            }
        }
    }

    private func itemRow(_ item: ListDetailViewModel.ItemRow) -> some View {
        AislyItemRow(
            title: item.name,
            detail: Text(item.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute()),
            tapAction: {
                viewModel.presentEditItem(id: item.id)
            }
        ) {
            HStack(spacing: AislySpacing.small) {
                AislyBadge(
                    Text(AppStrings.ListDetail.categoryTitle(for: item.category)),
                    tone: .neutral,
                    size: .small
                )
                AislyBadge(
                    Text(item.quantity, format: .number),
                    tone: .primary,
                    size: .small
                )
            }
        }
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
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteItem(id: item.id)
                }
            } label: {
                Text(AppStrings.Common.deleteButtonTitle)
            }
        }
    }

    private var editorModeBinding: Binding<ListDetailViewModel.EditorMode?> {
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

    private var draftCategoryBinding: Binding<ShoppingItem.Category> {
        Binding(
            get: { viewModel.draftCategory },
            set: { viewModel.updateDraftCategory($0) }
        )
    }

    private var draftQuantityBinding: Binding<Int> {
        Binding(
            get: { viewModel.draftQuantity },
            set: { viewModel.updateDraftQuantity($0) }
        )
    }

    @ViewBuilder
    private func editorSheet(_ editorMode: ListDetailViewModel.EditorMode) -> some View {
        NavigationStack {
            Form {
                AislyInputField(
                    text: draftNameBinding,
                    title: Text(AppStrings.ListDetail.itemNameFieldTitle),
                    prompt: Text(AppStrings.ListDetail.itemNamePlaceholder)
                )
                .listRowInsets(
                    EdgeInsets(
                        top: AislySpacing.small,
                        leading: AislySpacing.large,
                        bottom: AislySpacing.small,
                        trailing: AislySpacing.large
                    )
                )
                .listRowBackground(Color.clear)

                Section {
                    quantityField

                    Picker(selection: draftCategoryBinding) {
                        ForEach(ShoppingItem.Category.allCases) { category in
                            Text(AppStrings.ListDetail.categoryTitle(for: category)).tag(category)
                        }
                    } label: {
                        Text(AppStrings.ListDetail.categoryFieldTitle)
                    }
                }
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var quantityField: some View {
        Stepper(value: draftQuantityBinding, in: 1...99) {
            HStack {
                Text(AppStrings.ListDetail.quantityFieldTitle)
                Spacer()
                Text(viewModel.draftQuantity, format: .number)
                    .font(AislyTypography.body)
                    .foregroundStyle(AislyColor.textSecondary)
            }
        }
    }

    private func handleMove(fromOffsets: IndexSet, toOffset: Int) {
        Task {
            await viewModel.moveItems(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }

    private func editorTitle(for editorMode: ListDetailViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create:
            return AppStrings.ListDetail.addItemSheetTitle
        case .edit:
            return AppStrings.ListDetail.editItemSheetTitle
        }
    }

    private func editorActionTitle(for editorMode: ListDetailViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create:
            return AppStrings.ListDetail.addItemConfirmButtonTitle
        case .edit:
            return AppStrings.ListDetail.editItemConfirmButtonTitle
        }
    }
}

#Preview("List Detail Empty") {
    NavigationStack {
        ListDetailView(
            viewModel: ListDetailViewModel(
                listID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                repository: PreviewListDetailRepository(lists: [
                    ShoppingList(
                        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                        name: AppStrings.Mock.ShoppingList.weeklyGroceriesName(locale: Locale(identifier: "en")),
                        createdAt: .now,
                        updatedAt: .now,
                        isArchived: false
                    )
                ])
            )
        )
    }
}

#Preview("List Detail Loaded") {
    NavigationStack {
        ListDetailView(
            viewModel: ListDetailViewModel(
                listID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                repository: PreviewListDetailRepository(lists: [
                    ShoppingList(
                        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                        name: AppStrings.Mock.ShoppingList.weeklyGroceriesName(locale: Locale(identifier: "en")),
                        createdAt: .now,
                        updatedAt: .now,
                        isArchived: false,
                        items: makePreviewItems(locale: Locale(identifier: "en"))
                    )
                ])
            )
        )
    }
}

private func makePreviewItems(locale: Locale) -> [ShoppingItem] {
    [
        ShoppingItem(
            id: UUID(),
            name: AppStrings.Mock.ShoppingItem.milkName(locale: locale),
            quantity: 2,
            category: .dairy,
            createdAt: .now,
            updatedAt: .now,
            sortOrder: 0
        ),
        ShoppingItem(
            id: UUID(),
            name: AppStrings.Mock.ShoppingItem.applesName(locale: locale),
            quantity: 6,
            category: .produce,
            createdAt: .now,
            updatedAt: .now,
            sortOrder: 1
        )
    ]
}

private struct PreviewListDetailRepository: ShoppingListRepository {
    let lists: [ShoppingList]

    func fetchLists() async throws -> [ShoppingList] {
        lists
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}
