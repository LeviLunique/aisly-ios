import SwiftUI

struct ShoppingModeView: View {
    @StateObject private var viewModel: ShoppingModeViewModel

    init(viewModel: ShoppingModeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text(AppStrings.ShoppingMode.navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: priceEditorStateBinding) { editorState in
                priceEditorSheet(editorState)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.ShoppingMode.loadingTitle)

        case .loaded(let snapshot) where snapshot.itemCount == 0:
            AislyEmptyState(
                icon: Image(systemName: "cart"),
                title: AppStrings.ShoppingMode.emptyTitle,
                description: AppStrings.ShoppingMode.emptyDescription
            )

        case .loaded(let snapshot):
            List {
                Section {
                    sessionSummary(snapshot)
                }

                if snapshot.remainingItems.isEmpty == false {
                    Section {
                        ForEach(snapshot.remainingItems) { item in
                            itemRow(item)
                        }
                    } header: {
                        AislySectionHeader(AppStrings.ShoppingMode.remainingItemsSectionTitle)
                    }
                }

                if snapshot.completedItems.isEmpty == false {
                    Section {
                        ForEach(snapshot.completedItems) { item in
                            itemRow(item)
                        }
                    } header: {
                        AislySectionHeader(AppStrings.ShoppingMode.completedItemsSectionTitle)
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
                title: AppStrings.ShoppingMode.failureTitle,
                description: AppStrings.ShoppingMode.failureDescription
            ) {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(AppStrings.ShoppingMode.retryButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    private func sessionSummary(_ snapshot: ShoppingModeViewModel.SessionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.medium) {
            AislyBudgetSummaryCard(
                title: Text(AppStrings.ListDetail.budgetSummaryTitle),
                progressSummary: Text(snapshot.completedItemCount, format: .number) + Text(verbatim: " / ") + Text(snapshot.itemCount, format: .number),
                estimatedLabel: Text(AppStrings.ListDetail.plannedTotalTitle),
                estimatedValue: currencyText(snapshot.plannedTotal),
                actualLabel: Text(AppStrings.ListDetail.actualTotalTitle),
                actualValue: currencyText(snapshot.actualTotal),
                deltaTone: budgetDeltaTone(for: snapshot.budgetDelta),
                deltaTitle: Text(AppStrings.ListDetail.budgetDeltaTitle(for: snapshot.budgetDelta)),
                deltaSubtitle: budgetDeltaSubtitle(for: snapshot.budgetDelta)
            )

            AislySurfaceCard {
                AislyProgressBar(
                    value: Double(snapshot.completedItemCount),
                    maximum: Double(max(snapshot.itemCount, 1)),
                    tone: .success,
                    progressLabel: Text(AppStrings.ShoppingMode.progressTitle),
                    percentageLabel: Text(progressPercentage(snapshot), format: .percent.precision(.fractionLength(0)))
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

    private func itemRow(_ item: ShoppingModeViewModel.ItemRow) -> some View {
        AislySurfaceCard {
            HStack(alignment: .top, spacing: AislySpacing.medium) {
                AislyCheckbox(isChecked: completionBinding(for: item))

                VStack(alignment: .leading, spacing: AislySpacing.small) {
                    Text(item.name)
                        .font(AislyTypography.rowTitle)
                        .foregroundStyle(item.isCompleted ? AislyColor.textSecondary : AislyColor.textPrimary)
                        .strikethrough(item.isCompleted)

                    HStack(spacing: AislySpacing.small) {
                        AislyBadge(
                            Text(AppStrings.ListDetail.categoryTitle(for: item.category)),
                            tone: .neutral,
                            size: .small
                        )
                        AislyBadge(
                            Text(item.quantity, format: .number),
                            tone: item.isCompleted ? .success : .primary,
                            size: .small
                        )
                    }

                    if let storeName = item.storeName {
                        Text(verbatim: storeName)
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
                    }
                }

                Spacer(minLength: AislySpacing.small)

                Button {
                    viewModel.presentActualPriceEditor(id: item.id)
                } label: {
                    VStack(alignment: .trailing, spacing: 4) {
                        if let primaryPrice = rowPrimaryPrice(for: item) {
                            primaryPrice
                                .font(AislyTypography.caption.weight(.semibold))
                                .foregroundStyle(item.isCompleted ? AislyColor.textSecondary : AislyColor.textPrimary)
                        }

                        if let secondaryPrice = rowSecondaryPrice(for: item) {
                            secondaryPrice
                                .font(AislyTypography.small)
                                .foregroundStyle(AislyColor.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
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
            Button {
                viewModel.presentActualPriceEditor(id: item.id)
            } label: {
                Text(AppStrings.ShoppingMode.actualPriceFieldTitle)
            }
            .tint(AislyColor.primary)
        }
    }

    private var priceEditorStateBinding: Binding<ShoppingModeViewModel.PriceEditorState?> {
        Binding(
            get: { viewModel.priceEditorState },
            set: { updatedValue in
                if updatedValue == nil {
                    viewModel.dismissPriceEditor()
                }
            }
        )
    }

    private var draftActualPriceBinding: Binding<String> {
        Binding(
            get: { viewModel.draftActualPrice },
            set: { viewModel.updateDraftActualPrice($0) }
        )
    }

    @ViewBuilder
    private func priceEditorSheet(_ editorState: ShoppingModeViewModel.PriceEditorState) -> some View {
        NavigationStack {
            Form {
                if let itemName = viewModel.currentEditingItemName {
                    Section {
                        AislySurfaceCard {
                            Text(verbatim: itemName)
                                .font(AislyTypography.cardTitle)
                                .foregroundStyle(AislyColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                if let plannedPriceSuggestion = viewModel.plannedPriceSuggestion {
                    Section {
                        Button {
                            viewModel.applyPlannedPriceSuggestion()
                        } label: {
                            HStack {
                                Text(AppStrings.ShoppingMode.usePlannedPriceButtonTitle)
                                Spacer()
                                currencyText(plannedPriceSuggestion)
                                    .foregroundStyle(AislyColor.textSecondary)
                            }
                        }
                    }
                }

                Section {
                    AislyInputField(
                        text: draftActualPriceBinding,
                        title: Text(AppStrings.ShoppingMode.actualPriceFieldTitle),
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
            .navigationTitle(Text(editorTitle(for: editorState)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.dismissPriceEditor()
                    } label: {
                        Text(AppStrings.Common.cancelButtonTitle)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.saveActualPriceDraft()
                        }
                    } label: {
                        Text(AppStrings.ShoppingMode.saveActualPriceButtonTitle)
                    }
                    .disabled(viewModel.isDraftSubmissionDisabled)
                    .tint(AislyColor.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func editorTitle(for editorState: ShoppingModeViewModel.PriceEditorState) -> LocalizedStringResource {
        switch editorState {
        case .actualPrice:
            return AppStrings.ShoppingMode.actualPriceSheetTitle
        }
    }

    private func completionBinding(for item: ShoppingModeViewModel.ItemRow) -> Binding<Bool> {
        Binding(
            get: { item.isCompleted },
            set: { _ in
                Task {
                    await viewModel.toggleCompletion(id: item.id)
                }
            }
        )
    }

    private func rowPrimaryPrice(for item: ShoppingModeViewModel.ItemRow) -> Text? {
        if let actualTotal = item.actualTotal {
            return currencyText(actualTotal)
        }

        if let plannedTotal = item.plannedTotal {
            return currencyText(plannedTotal)
        }

        return nil
    }

    private func rowSecondaryPrice(for item: ShoppingModeViewModel.ItemRow) -> Text? {
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

    private func progressPercentage(_ snapshot: ShoppingModeViewModel.SessionSnapshot) -> Double {
        guard snapshot.itemCount > 0 else {
            return 0
        }

        return Double(snapshot.completedItemCount) / Double(snapshot.itemCount)
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }
}

#Preview("Shopping Mode Loaded") {
    NavigationStack {
        ShoppingModeView(
            viewModel: ShoppingModeViewModel(
                listID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                repository: PreviewShoppingModeRepository(lists: [
                    ShoppingList(
                        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                        name: AppStrings.Mock.ShoppingList.weeklyGroceriesName(locale: Locale(identifier: "en")),
                        createdAt: .now,
                        updatedAt: .now,
                        isArchived: false,
                        items: makeShoppingModePreviewItems(locale: Locale(identifier: "en"))
                    )
                ])
            )
        )
    }
}

private func makeShoppingModePreviewItems(locale: Locale) -> [ShoppingItem] {
    [
        ShoppingItem(
            id: UUID(),
            name: AppStrings.Mock.ShoppingItem.milkName(locale: locale),
            quantity: 2,
            category: .dairy,
            storeName: AppStrings.Mock.Store.freshMartName(locale: locale),
            plannedPrice: 4.50,
            actualPrice: 4.75,
            isCompleted: true,
            createdAt: .now,
            updatedAt: .now,
            sortOrder: 0
        ),
        ShoppingItem(
            id: UUID(),
            name: AppStrings.Mock.ShoppingItem.applesName(locale: locale),
            quantity: 6,
            category: .produce,
            storeName: AppStrings.Mock.Store.cityMarketName(locale: locale),
            plannedPrice: 0.80,
            actualPrice: nil,
            isCompleted: false,
            createdAt: .now,
            updatedAt: .now,
            sortOrder: 1
        )
    ]
}

private struct PreviewShoppingModeRepository: ShoppingListRepository {
    let lists: [ShoppingList]

    func fetchLists() async throws -> [ShoppingList] {
        lists
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}
