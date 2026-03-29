import SwiftUI

struct ListDetailView: View {
    @StateObject private var viewModel: ListDetailViewModel
    private let emptyStateSymbolName = ["list", "bullet", "clipboard"].joined(separator: ".")

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
                icon: Image(systemName: emptyStateSymbolName),
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
                    budgetSummaryCard(snapshot)
                }

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
            primaryPrice: rowPrimaryPrice(for: item),
            secondaryPrice: rowSecondaryPrice(for: item),
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

    private var draftPlannedPriceBinding: Binding<String> {
        Binding(
            get: { viewModel.draftPlannedPrice },
            set: { viewModel.updateDraftPlannedPrice($0) }
        )
    }

    private var draftActualPriceBinding: Binding<String> {
        Binding(
            get: { viewModel.draftActualPrice },
            set: { viewModel.updateDraftActualPrice($0) }
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

                if case .create = editorMode, viewModel.quickEntrySuggestions.isEmpty == false {
                    Section {
                        ForEach(viewModel.quickEntrySuggestions) { suggestion in
                            quickEntryRow(suggestion)
                        }
                    } header: {
                        AislySectionHeader(AppStrings.ListDetail.quickEntrySectionTitle)
                    }
                }

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

                Section {
                    AislyInputField(
                        text: draftPlannedPriceBinding,
                        title: Text(AppStrings.ListDetail.plannedPriceFieldTitle),
                        prompt: Text(AppStrings.Common.optionalFieldValue),
                        keyboardType: .decimalPad,
                        textInputAutocapitalization: .never
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

                    AislyInputField(
                        text: draftActualPriceBinding,
                        title: Text(AppStrings.ListDetail.actualPriceFieldTitle),
                        prompt: Text(AppStrings.Common.optionalFieldValue),
                        keyboardType: .decimalPad,
                        textInputAutocapitalization: .never
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

    private func quickEntryRow(_ suggestion: ListDetailViewModel.QuickEntrySuggestion) -> some View {
        AislyItemRow(
            title: suggestion.name,
            primaryPrice: suggestion.plannedPrice.map(currencyText),
            tapAction: {
                viewModel.applyQuickEntrySuggestion(id: suggestion.id)
            }
        ) {
            HStack(spacing: AislySpacing.small) {
                AislyBadge(
                    Text(AppStrings.ListDetail.categoryTitle(for: suggestion.category)),
                    tone: .neutral,
                    size: .small
                )
                AislyBadge(
                    Text(suggestion.quantity, format: .number),
                    tone: .success,
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
    }

    private func budgetSummaryCard(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        AislyBudgetSummaryCard(
            title: Text(AppStrings.ListDetail.budgetSummaryTitle),
            progressSummary: Text(snapshot.actualPricedItemCount, format: .number) + Text(verbatim: " / ") + Text(snapshot.items.count, format: .number),
            estimatedLabel: Text(AppStrings.ListDetail.plannedTotalTitle),
            estimatedValue: currencyText(snapshot.plannedTotal),
            actualLabel: Text(AppStrings.ListDetail.actualTotalTitle),
            actualValue: currencyText(snapshot.actualTotal),
            deltaTone: budgetDeltaTone(for: snapshot.budgetDelta),
            deltaTitle: Text(AppStrings.ListDetail.budgetDeltaTitle(for: snapshot.budgetDelta)),
            deltaSubtitle: budgetDeltaSubtitle(for: snapshot.budgetDelta)
        )
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

    private func rowPrimaryPrice(for item: ListDetailViewModel.ItemRow) -> Text? {
        if let actualTotal = item.actualTotal {
            return currencyText(actualTotal)
        }

        if let plannedTotal = item.plannedTotal {
            return currencyText(plannedTotal)
        }

        return nil
    }

    private func rowSecondaryPrice(for item: ListDetailViewModel.ItemRow) -> Text? {
        guard
            item.actualTotal != nil,
            let plannedTotal = item.plannedTotal
        else {
            return nil
        }

        return currencyText(plannedTotal)
    }

    private func budgetDeltaTone(for delta: Decimal?) -> AislyBudgetSummaryCard.DeltaTone {
        guard let delta else {
            return .neutral
        }

        if delta == .zero {
            return .neutral
        }

        return delta < .zero ? .underBudget : .overBudget
    }

    private func budgetDeltaSubtitle(for delta: Decimal?) -> Text {
        guard let delta else {
            return Text(AppStrings.ListDetail.awaitingActualPricesDescription)
        }

        return currencyText(abs(delta))
    }

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
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
            plannedPrice: 4.50,
            actualPrice: 4.75,
            createdAt: .now,
            updatedAt: .now,
            sortOrder: 0
        ),
        ShoppingItem(
            id: UUID(),
            name: AppStrings.Mock.ShoppingItem.applesName(locale: locale),
            quantity: 6,
            category: .produce,
            plannedPrice: 0.80,
            actualPrice: nil,
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
