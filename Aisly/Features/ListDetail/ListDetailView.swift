import SwiftUI

enum ListDetailMode {
    case list
    case template
}

struct ListDetailView: View {
    enum ItemSort: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case name = "Name"
        case price = "Price"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastCenter: AislyToastCenter
    @StateObject private var viewModel: ListDetailViewModel
    private let mode: ListDetailMode

    @State private var editMode: EditMode = .inactive
    @State private var collapsedSections: Set<String> = []

    // Multi-select mode (native EditMode → selection circles + drag handles).
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var pendingBulkItemDelete = false

    // Display controls (… menu).
    @State private var sortOption: ItemSort = .manual
    @State private var hidePurchased = false
    @State private var viewAsColumns = false

    // Item search (magnifier).
    @State private var isSearchActive = false
    @State private var searchQuery = ""
    @FocusState private var searchFocused: Bool

    // List Info sheet draft.
    @State private var isInfoPresented = false
    @State private var infoName = ""
    @State private var infoBudget = ""
    @State private var infoIconName = ShoppingList.defaultIconName
    @State private var infoColorHex = ShoppingList.defaultColorHex

    // Save-as-template sheet draft.
    @State private var isSaveTemplatePresented = false
    @State private var templateName = ""
    @State private var templateRecurrence: ShoppingList.TemplateRecurrence = .weekly

    // Custom more-menu (native Menu can't render the kit's teal highlight).
    @State private var isMoreMenuOpen = false

    // Reorder-categories sheet.
    @State private var isReorderCategoriesPresented = false

    // Delete confirmation.
    @State private var isDeleteListConfirmationPresented = false

    private let emptyStateSymbolName = ["list", "bullet", "clipboard"].joined(separator: ".")

    init(viewModel: ListDetailViewModel, mode: ListDetailMode = .list) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.mode = mode
    }

    private var isTemplate: Bool {
        mode == .template || viewModel.isTemplate
    }

    private var isSelecting: Bool { editMode.isEditing }

    private var listColor: Color {
        Color.aislyListHex(viewModel.listColorHex)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .environment(\.editMode, $editMode)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: editorModeBinding) { editorMode in
                editorSheet(editorMode)
            }
            .sheet(item: finishSummaryBinding) { summary in
                finishPurchaseSheet(summary)
            }
            .sheet(isPresented: $isInfoPresented) {
                listInfoSheet
            }
            .sheet(isPresented: $isSaveTemplatePresented) {
                saveTemplateSheet
            }
            .sheet(isPresented: $isReorderCategoriesPresented) {
                reorderCategoriesSheet
            }
            .alert(
                Text(verbatim: isTemplate ? "Delete template permanently?" : "Delete list permanently?"),
                isPresented: $isDeleteListConfirmationPresented
            ) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteList()
                        dismiss()
                    }
                } label: {
                    Text(AppStrings.Common.deleteButtonTitle)
                }
                Button(role: .cancel) {} label: {
                    Text(AppStrings.Common.cancelButtonTitle)
                }
            } message: {
                Text(verbatim: isTemplate ? "This will remove the template and its items. This action cannot be undone." : "This will remove the list, its sections, and current item values. This action cannot be undone.")
            }
            .alert(
                Text(verbatim: "Delete \(selectedItemIDs.count) items?"),
                isPresented: $pendingBulkItemDelete
            ) {
                Button(role: .destructive) {
                    let ids = selectedItemIDs
                    Task {
                        await viewModel.deleteItems(ids: ids)
                        exitSelection()
                    }
                } label: {
                    Text(AppStrings.Common.deleteButtonTitle)
                }
                Button(role: .cancel) {} label: {
                    Text(AppStrings.Common.cancelButtonTitle)
                }
            } message: {
                Text(verbatim: "This removes the selected items from the list.")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.ListDetail.loadingTitle)

        case .loaded(let snapshot):
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    mainBody(snapshot)
                }

                if isSelecting {
                    selectionBar
                } else if !isSearchActive {
                    addItemFab.frame(maxWidth: .infinity, alignment: .trailing)
                }

                if isMoreMenuOpen {
                    moreMenuOverlay
                }
            }

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(AislyColor.error),
                title: AppStrings.ListDetail.failureTitle,
                description: AppStrings.ListDetail.failureDescription
            ) {
                Button {
                    Task { await viewModel.load() }
                } label: { Text(AppStrings.ListDetail.retryButtonTitle) }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        if editMode.isEditing {
            HStack {
                Button {
                    if selectedItemIDs == currentItemIDs {
                        selectedItemIDs = []
                    } else {
                        selectedItemIDs = currentItemIDs
                    }
                } label: {
                    Text(verbatim: selectedItemIDs == currentItemIDs && currentItemIDs.isEmpty == false ? "Deselect All" : "Select All")
                        .font(AislyTypography.body.weight(.semibold))
                        .foregroundStyle(AislyColor.primary)
                        .padding(.horizontal, AislySpacing.large)
                        .frame(height: 36)
                        .background(Capsule(style: .continuous).fill(AislyColor.surfaceSecondary))
                }

                Spacer()

                Button { exitSelection() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AislyColor.primaryForeground)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AislyColor.primary))
                }
                .accessibilityLabel(Text(verbatim: "Done selecting"))
            }
            .padding(.horizontal, AislySpacing.large)
            .padding(.vertical, AislySpacing.small)
        } else {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AislyColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AislyColor.glassBackground))
                        .overlay(Circle().stroke(AislyColor.glassBorder, lineWidth: 1))
                }
                .accessibilityLabel(Text(verbatim: "Back"))

                Spacer()

                HStack(spacing: AislySpacing.large) {
                    Button {
                        withAnimation(AislyMotion.quick) { isSearchActive = true }
                    } label: {
                        Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(Text(verbatim: "Search items"))

                    Button {
                        withAnimation(AislyMotion.quick) { isMoreMenuOpen.toggle() }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(isMoreMenuOpen ? Color(uiColor: UIColor.systemBlue) : Color.clear, lineWidth: 2)
                            )
                    }
                    .accessibilityLabel(Text(verbatim: "List options"))
                }
                .foregroundStyle(AislyColor.textPrimary)
                .padding(.horizontal, AislySpacing.large)
                .frame(height: 40)
                .background(Capsule(style: .continuous).fill(AislyColor.glassBackground))
                .overlay(Capsule(style: .continuous).stroke(AislyColor.glassBorder, lineWidth: 1))
            }
            .padding(.horizontal, AislySpacing.large)
            .padding(.top, AislySpacing.small)
            .padding(.bottom, AislySpacing.small)
        }
    }

    // MARK: - List body

    private func listBody(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        List(selection: $selectedItemIDs) {
            Section {
                header(snapshot)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .selectionDisabled()
                    .moveDisabled(true)

                if isTemplate == false {
                    budgetSummaryCard(snapshot)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .selectionDisabled()
                        .moveDisabled(true)
                }
            }

            ForEach(snapshot.itemSections) { section in
                let items = displayedItems(section.items)
                Section {
                    if collapsedSections.contains(section.id) == false {
                        ForEach(items) { item in
                            itemCard(item)
                        }
                        .onMove { offsets, destination in
                            if canReorder {
                                handleMove(fromOffsets: offsets, toOffset: destination)
                            }
                        }
                    }
                } header: {
                    sectionHeader(section, count: items.count)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AislyColor.backgroundPrimary)
        .tint(AislyColor.primary)
        .safeAreaInset(edge: .bottom) {
            if isSearchActive {
                searchBar
            } else {
                Color.clear.frame(height: isSelecting ? 80 : 84)
            }
        }
    }

    private var canReorder: Bool {
        sortOption == .manual && hidePurchased == false && searchQuery.isEmpty
    }

    // MARK: - Header (colored title + subtitle · Clear)

    private func header(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.xSmall) {
            if isTemplate {
                HStack(spacing: AislySpacing.small) {
                    Text(snapshot.listName)
                        .font(AislyTypography.pageTitle)
                        .foregroundStyle(listColor)
                        .lineLimit(1)

                    AislyBadge(Text(verbatim: "Template"), tone: .primary, size: .small)
                }

                Text(verbatim: templateSubtitle(snapshot))
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
            } else {
                Text(snapshot.listName)
                    .font(AislyTypography.pageTitle)
                    .foregroundStyle(listColor)
                    .lineLimit(2)

                HStack(spacing: AislySpacing.xSmall) {
                    Text(verbatim: "\(snapshot.purchasedItemCount) of \(snapshot.items.count) purchased")
                        .font(AislyTypography.caption)
                        .foregroundStyle(AislyColor.textSecondary)

                    if snapshot.purchasedItemCount > 0 {
                        Text(verbatim: "·")
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)

                        Button {
                            Task { await viewModel.clearPurchased() }
                        } label: {
                            Text(verbatim: "Clear")
                                .font(AislyTypography.caption.weight(.semibold))
                                .foregroundStyle(AislyColor.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AislySpacing.xSmall)
    }

    private func templateSubtitle(_ snapshot: ListDetailViewModel.ListSnapshot) -> String {
        let itemsText = snapshot.items.count == 1 ? "1 item" : "\(snapshot.items.count) items"
        return "\(itemsText) · Default planned \(currencyString(snapshot.plannedTotal)) · Ready to reuse"
    }

    // MARK: - Section header (icon + name + count + chevron)

    private func sectionHeader(_ section: ListDetailViewModel.ItemSection, count: Int) -> some View {
        HStack(spacing: AislySpacing.small) {
            AislyCategoryIcon(
                systemName: section.iconName,
                color: Color.aislyListHex(section.colorHex),
                size: .small
            )

            Text(verbatim: section.title)
                .font(AislyTypography.cardTitle)
                .foregroundStyle(AislyColor.textPrimary)
                .textCase(nil)

            Text(verbatim: "\(count)")
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textTertiary)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AislyColor.textTertiary)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AislyColor.textTertiary)
                .rotationEffect(.degrees(collapsedSections.contains(section.id) ? -90 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AislyMotion.quick) {
                if collapsedSections.contains(section.id) {
                    collapsedSections.remove(section.id)
                } else {
                    collapsedSections.insert(section.id)
                }
            }
        }
        .draggable("category:\(section.id)")
        .dropDestination(for: String.self) { payloads, _ in
            reorderCategories(payloads, aheadOf: section.id)
        }
    }

    private func reorderCategories(_ payloads: [String], aheadOf targetID: String) -> Bool {
        var handled = false
        for payload in payloads where payload.hasPrefix("category:") {
            let movedID = String(payload.dropFirst("category:".count))
            if movedID != targetID {
                handled = true
                Task { await viewModel.moveCategory(movedID, aheadOf: targetID) }
            }
        }
        return handled
    }

    // MARK: - Item card (checkbox left, qty, prices right)

    // MARK: - Body dispatch (list vs. Kanban board)

    @ViewBuilder
    private func mainBody(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        if viewAsColumns && isSelecting == false {
            kanbanContent(snapshot)
        } else {
            listBody(snapshot)
        }
    }

    // MARK: - Kanban board (View as Columns)

    private struct BoardColumn: Identifiable {
        let id: String
        let category: ShoppingItem.Category
        let iconName: String
        let colorHex: UInt32
        let items: [ListDetailViewModel.ItemRow]
    }

    private func boardColumns(_ snapshot: ListDetailViewModel.ListSnapshot) -> [BoardColumn] {
        viewModel.availableCategories.map { category in
            let appearance = viewModel.categoryAppearance(for: category)
            return BoardColumn(
                id: category.id,
                category: category,
                iconName: appearance.iconName,
                colorHex: appearance.colorHex,
                items: snapshot.items.filter { $0.category.matches(category) }
            )
        }
    }

    @ViewBuilder
    private func kanbanContent(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.large) {
            header(snapshot)
                .padding(.horizontal, AislySpacing.large)
                .padding(.top, AislySpacing.xSmall)

            if isTemplate == false {
                budgetSummaryCard(snapshot)
                    .padding(.horizontal, AislySpacing.large)
            }

            kanbanBoard(snapshot)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AislyColor.backgroundPrimary)
    }

    private func kanbanBoard(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: AislySpacing.medium) {
                ForEach(boardColumns(snapshot)) { column in
                    kanbanColumn(column)
                }
            }
            .padding(.horizontal, AislySpacing.large)
            .padding(.bottom, AislySpacing.giant)
        }
    }

    private func kanbanColumn(_ column: BoardColumn) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                AislyCategoryIcon(systemName: column.iconName, color: Color.aislyListHex(column.colorHex), size: .small)
                Text(AppStrings.ListDetail.categoryTitle(for: column.category))
                    .font(AislyTypography.cardTitle)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)
                Text(verbatim: "\(column.items.count)")
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textTertiary)
                Spacer(minLength: 0)

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.textTertiary)
            }
            .contentShape(Rectangle())
            .draggable("category:\(column.id)")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AislySpacing.small) {
                    ForEach(column.items) { item in
                        // Checkbox stays visible on board cards so items can be
                        // marked purchased without leaving column view; dragging
                        // still works via long-press on the card body.
                        itemCardContent(item)
                            .onTapGesture { viewModel.presentEditItem(id: item.id) }
                            .draggable("item:\(item.id.uuidString)")
                    }

                    if column.items.isEmpty {
                        Text(verbatim: "Drop items here")
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AislySpacing.xxLarge)
                    }
                }
                .padding(.bottom, AislySpacing.small)
            }
        }
        .padding(AislySpacing.medium)
        .frame(width: 270)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
        .dropDestination(for: String.self) { payloads, _ in
            handleKanbanDrop(payloads, column: column)
        }
    }

    private func handleKanbanDrop(_ payloads: [String], column: BoardColumn) -> Bool {
        var handled = false
        for payload in payloads {
            if payload.hasPrefix("item:"), let id = UUID(uuidString: String(payload.dropFirst("item:".count))) {
                handled = true
                Task { await viewModel.assignCategory(ids: [id], to: column.category) }
            } else if payload.hasPrefix("category:") {
                let movedID = String(payload.dropFirst("category:".count))
                if movedID != column.id {
                    handled = true
                    Task { await viewModel.moveCategory(movedID, aheadOf: column.id) }
                }
            }
        }
        return handled
    }

    private func itemCard(_ item: ListDetailViewModel.ItemRow) -> some View {
        Group {
            if isSelecting {
                itemCardContent(item)
            } else {
                Button { viewModel.presentEditItem(id: item.id) } label: {
                    itemCardContent(item)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await viewModel.deleteItem(id: item.id) }
            } label: {
                Label(String(localized: "Delete", defaultValue: "Delete"), systemImage: "trash")
            }

            if viewModel.canMigrateItemsToTemplate {
                Button {
                    Task { await viewModel.migrateItemToTemplate(id: item.id) }
                } label: {
                    Label {
                        Text(AppStrings.ListDetail.sendToTemplateActionTitle)
                    } icon: {
                        Image(systemName: "plus.square.on.square")
                    }
                }
                .tint(AislyColor.primary)
            }
        }
    }

    private func itemCardContent(_ item: ListDetailViewModel.ItemRow, showsCheckbox: Bool = true) -> some View {
        let purchased = isTemplate ? false : item.isCompleted

        return HStack(alignment: .top, spacing: AislySpacing.medium) {
            if isTemplate == false && isSelecting == false && showsCheckbox {
                AislyCheckbox(isChecked: completionBinding(for: item))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AislySpacing.xSmall) {
                    Text(item.name)
                        .font(AislyTypography.rowTitle)
                        .foregroundStyle(purchased ? AislyColor.textTertiary : AislyColor.textPrimary)
                        .strikethrough(purchased)
                        .lineLimit(1)

                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AislyColor.secondary)
                    }
                }

                Text(verbatim: quantityText(item.quantity, unit: item.unit))
                    .font(AislyTypography.rowMetadata)
                    .foregroundStyle(AislyColor.textSecondary)

                if item.note.isEmpty == false {
                    Text(verbatim: item.note)
                        .font(AislyTypography.rowMetadata)
                        .foregroundStyle(AislyColor.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                if isTemplate, let planned = item.plannedTotal {
                    (Text(verbatim: "Planned ") + currencyText(planned))
                        .font(AislyTypography.caption.weight(.semibold))
                        .foregroundStyle(AislyColor.textPrimary)
                } else if let actual = item.actualTotal {
                    currencyText(actual)
                        .font(AislyTypography.caption.weight(.semibold))
                        .foregroundStyle(purchased ? AislyColor.textSecondary : AislyColor.textPrimary)
                } else if let planned = item.plannedTotal {
                    (Text(verbatim: "Planned ") + currencyText(planned))
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                }
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(purchased ? AislyColor.surfaceSecondary : AislyColor.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .stroke(AislyColor.borderSubtle, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func quantityText(_ quantity: Int, unit: ShoppingItem.Unit) -> String {
        "\(quantity) \(unit.rawValue)"
    }

    private func completionBinding(for item: ListDetailViewModel.ItemRow) -> Binding<Bool> {
        Binding(
            get: { item.isCompleted },
            set: { _ in Task { await viewModel.toggleCompletion(id: item.id) } }
        )
    }

    // MARK: - Item filtering / sorting

    private func displayedItems(_ items: [ListDetailViewModel.ItemRow]) -> [ListDetailViewModel.ItemRow] {
        var result = items

        if hidePurchased {
            result = result.filter { $0.isCompleted == false }
        }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty == false {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }

        switch sortOption {
        case .manual:
            break
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .price:
            result.sort { priceValue($0) > priceValue($1) }
        }

        return result
    }

    private func priceValue(_ item: ListDetailViewModel.ItemRow) -> Decimal {
        item.actualTotal ?? item.plannedTotal ?? .zero
    }

    // MARK: - Search bar (docked above keyboard)

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $searchQuery,
                    prompt: Text(verbatim: "Search items").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search items"))
            }
            .padding(.horizontal, AislySpacing.medium)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )

            Button {
                searchFocused = false
                withAnimation(AislyMotion.quick) {
                    isSearchActive = false
                    searchQuery = ""
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AislyColor.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AislyColor.surfaceSecondary))
            }
            .accessibilityLabel(Text(verbatim: "Close search"))
        }
        .padding(.horizontal, AislySpacing.large)
        .padding(.vertical, AislySpacing.small)
        .background(AislyColor.surfacePrimary)
        .overlay(alignment: .top) {
            Rectangle().fill(AislyColor.divider).frame(height: 1)
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Budget summary

    private func budgetSummaryCard(_ snapshot: ListDetailViewModel.ListSnapshot) -> some View {
        let missing = snapshot.missingActualPurchasedItemCount

        return AislyBudgetSummaryCard(
            title: Text(verbatim: budgetTitle(snapshot.budget)),
            progressSummary: Text(verbatim: budgetProgressSummary(snapshot)),
            estimatedLabel: Text(verbatim: "Planned"),
            estimatedValue: currencyText(snapshot.plannedTotal),
            actualLabel: Text(verbatim: "Actual"),
            actualValue: currencyText(snapshot.actualTotal),
            deltaTone: budgetDeltaTone(for: snapshot.budgetDelta),
            deltaTitle: budgetDeltaTitle(for: snapshot.budgetDelta),
            deltaSubtitle: Text(verbatim: missing > 0 ? "Actual total is partial" : "Based on current prices")
        )
    }

    private func budgetTitle(_ budget: Decimal?) -> String {
        guard let budget else { return "No budget" }
        return "Budget \(currencyString(budget))"
    }

    private func budgetProgressSummary(_ snapshot: ListDetailViewModel.ListSnapshot) -> String {
        let missing = snapshot.missingActualPurchasedItemCount
        if missing > 0 {
            return missing == 1 ? "1 item missing price" : "\(missing) items missing prices"
        }
        return "\(snapshot.purchasedItemCount) of \(snapshot.items.count) purchased"
    }

    private func budgetDeltaTitle(for delta: Decimal?) -> Text {
        guard let delta else {
            return Text(verbatim: "Awaiting prices")
        }
        if delta == .zero {
            return Text(verbatim: "On budget")
        }
        let suffix = delta > .zero ? "under budget" : "over budget"
        return Text(verbatim: "\(currencyString(abs(delta))) \(suffix)")
    }

    // MARK: - FAB / template action

    private var addItemFab: some View {
        Button {
            viewModel.presentCreateItem()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AislyColor.primaryForeground)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AislyColor.primary))
                .aislyShadow(AislyShadow.fab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AppStrings.ListDetail.addItemToolbarTitle))
        .padding(AislySpacing.xLarge)
    }

    private var useTemplateButton: some View {
        Button {
            Task {
                if let newID = await viewModel.generateListFromTemplate() {
                    AppleSurfaceRouteRequestStore.savePendingRoute(.listDetail(newID))
                    dismiss()
                    toastCenter.show("List created from template")
                }
            }
        } label: {
            Text(verbatim: "Use Template")
        }
        .buttonStyle(AislyButtonStyle(variant: .primary, size: .large, isFullWidth: true))
        .padding(AislySpacing.large)
    }

    // MARK: - Selection bar

    private var selectionBar: some View {
        HStack(spacing: AislySpacing.large) {
            Text(verbatim: selectedItemIDs.isEmpty ? "0 selected" : "\(selectedItemIDs.count) selected")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textSecondary)

            Spacer()

            moveToCategoryButton

            circleAction(
                systemImage: "cart",
                fill: AislyColor.primary,
                label: "Mark selected purchased",
                enabled: !selectedItemIDs.isEmpty
            ) {
                let ids = selectedItemIDs
                Task {
                    await viewModel.markItemsPurchased(ids: ids)
                    exitSelection()
                }
            }

            circleAction(
                systemImage: "trash",
                fill: AislyColor.error,
                label: "Delete selected",
                enabled: !selectedItemIDs.isEmpty
            ) {
                pendingBulkItemDelete = true
            }
        }
        .padding(.horizontal, AislySpacing.xLarge)
        .padding(.vertical, AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.xLarge, style: .continuous)
                .fill(AislyColor.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: AislyCornerRadius.xLarge, style: .continuous)
                        .stroke(AislyColor.borderSubtle, lineWidth: 1)
                )
                .aislyShadow(AislyShadow.fab)
        )
        .padding(.horizontal, AislySpacing.large)
        .padding(.bottom, AislySpacing.small)
    }

    private var moveToCategoryButton: some View {
        Menu {
            ForEach(viewModel.availableCategories) { category in
                Button {
                    let ids = selectedItemIDs
                    Task {
                        await viewModel.assignCategory(ids: ids, to: category)
                        exitSelection()
                    }
                } label: {
                    Text(AppStrings.ListDetail.categoryTitle(for: category))
                }
            }
        } label: {
            Image(systemName: "folder")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AislyColor.archive.opacity(selectedItemIDs.isEmpty ? 0.4 : 1)))
        }
        .disabled(selectedItemIDs.isEmpty)
        .accessibilityLabel(Text(verbatim: "Move selected to category"))
    }

    private func circleAction(
        systemImage: String,
        fill: Color,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(fill.opacity(enabled ? 1 : 0.4)))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .accessibilityLabel(Text(verbatim: label))
    }

    private var currentItemIDs: Set<UUID> {
        guard case .loaded(let snapshot) = viewModel.state else { return [] }
        var ids: Set<UUID> = []
        for section in snapshot.itemSections where collapsedSections.contains(section.id) == false {
            for item in displayedItems(section.items) {
                ids.insert(item.id)
            }
        }
        return ids
    }

    private func exitSelection() {
        editMode = .inactive
        selectedItemIDs = []
    }

    // MARK: - … menu (custom panel — native Menu can't tint items like the kit)

    private var moreMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Tap-outside catcher.
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { closeMoreMenu() }

            VStack(alignment: .leading, spacing: 0) {
                moreMenuRow(
                    title: viewAsColumns ? "View as List" : "View as Columns",
                    systemName: viewAsColumns ? "list.bullet" : "tablecells"
                ) {
                    withAnimation(AislyMotion.quick) { viewAsColumns.toggle() }
                }

                menuGroupSeparator

                moreMenuRow(title: isTemplate ? "Template Info" : "List Info", systemName: "info.circle") {
                    presentInfo()
                }

                if viewModel.canReorderItems {
                    moreMenuRow(title: "Select Items", systemName: "checkmark.circle") {
                        withAnimation { editMode = .active }
                        selectedItemIDs = []
                    }
                }

                manageCategoriesRow

                if isTemplate == false {
                    moreMenuRow(title: "Reorder Categories", systemName: "arrow.up.arrow.down") {
                        isReorderCategoriesPresented = true
                    }
                }

                menuGroupSeparator

                Text(verbatim: "SORT BY")
                    .font(AislyTypography.small.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(AislyColor.textTertiary)
                    .padding(.horizontal, AislySpacing.large)
                    .padding(.top, AislySpacing.medium)
                    .padding(.bottom, AislySpacing.xSmall)

                ForEach(ItemSort.allCases) { option in
                    sortMenuRow(option)
                }

                menuGroupSeparator

                if isTemplate {
                    moreMenuRow(title: "Use Template", systemName: "plus.square.on.square", tint: AislyColor.primary) {
                        Task {
                            if let newID = await viewModel.generateListFromTemplate() {
                                AppleSurfaceRouteRequestStore.savePendingRoute(.listDetail(newID))
                                dismiss()
                                toastCenter.show("List created from template")
                            }
                        }
                    }
                } else {
                    moreMenuRow(
                        title: hidePurchased ? "Show Purchased" : "Hide Purchased",
                        systemName: hidePurchased ? "eye" : "eye.slash"
                    ) {
                        withAnimation(AislyMotion.quick) { hidePurchased.toggle() }
                    }

                    if viewModel.canSaveAsTemplate {
                        moreMenuRow(title: "Save as Template", systemName: "square.stack") {
                            presentSaveAsTemplate()
                        }
                    }

                    if viewModel.canFinishPurchase {
                        // The kit's emphasized action: teal text and icon.
                        moreMenuRow(title: "Finish Purchase", systemName: "checkmark.seal", tint: AislyColor.primary) {
                            viewModel.presentFinishPurchase()
                        }
                    }
                }

                menuGroupSeparator

                if viewModel.isArchivedList == false {
                    moreMenuRow(title: isTemplate ? "Archive Template" : "Archive List", systemName: "archivebox") {
                        Task {
                            await viewModel.archiveList()
                            dismiss()
                        }
                    }
                }

                moreMenuRow(title: isTemplate ? "Delete Template" : "Delete List", systemName: "trash", tint: AislyColor.error) {
                    isDeleteListConfirmationPresented = true
                }
            }
            .padding(.vertical, AislySpacing.small)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.xLarge, style: .continuous)
                    .fill(AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.xLarge, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
            .aislyShadow(AislyShadow.toast)
            .padding(.trailing, AislySpacing.large)
            .padding(.top, 56)
            .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func closeMoreMenu() {
        withAnimation(AislyMotion.quick) { isMoreMenuOpen = false }
    }

    private var menuGroupSeparator: some View {
        Rectangle()
            .fill(AislyColor.divider)
            .frame(height: 1)
            .padding(.vertical, AislySpacing.xSmall)
    }

    private func moreMenuRow(
        title: String,
        systemName: String,
        tint: Color = AislyColor.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            closeMoreMenu()
            action()
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(verbatim: title)
                    .font(AislyTypography.body)
                    .foregroundStyle(tint)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var manageCategoriesRow: some View {
        NavigationLink(value: AppRoute.categories) {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "tag")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AislyColor.textPrimary)
                    .frame(width: 24)

                Text(verbatim: "Manage Categories")
                    .font(AislyTypography.body)
                    .foregroundStyle(AislyColor.textPrimary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { closeMoreMenu() })
    }

    private func sortMenuRow(_ option: ItemSort) -> some View {
        Button {
            closeMoreMenu()
            sortOption = option
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .opacity(sortOption == option ? 1 : 0)
                    .frame(width: 24)

                Text(verbatim: option.rawValue)
                    .font(AislyTypography.body)
                    .foregroundStyle(AislyColor.textPrimary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(sortOption == option ? .isSelected : [])
    }

    // MARK: - Item editor sheet

    private func editorSheet(_ editorMode: ListDetailViewModel.EditorMode) -> some View {
        let isEdit: Bool = {
            if case .edit = editorMode { return true }
            return false
        }()

        return AislySheetContainer(
            title: Text(verbatim: isEdit ? "Edit Item" : "Add Item"),
            trailing: {
                HStack(spacing: AislySpacing.medium) {
                    editorCircleButton(systemImage: "xmark", tone: AislyColor.textSecondary, label: "Close") {
                        viewModel.dismissEditor()
                    }
                    editorCircleButton(
                        systemImage: "checkmark",
                        tone: viewModel.isDraftSubmissionDisabled ? AislyColor.textTertiary : AislyColor.primary,
                        label: isEdit ? "Save item" : "Add item",
                        enabled: viewModel.isDraftSubmissionDisabled == false
                    ) {
                        Task { await viewModel.saveDraft() }
                    }
                }
            },
            content: {
                VStack(alignment: .leading, spacing: AislySpacing.xLarge) {
                    editorField(title: "Item Name") { nameField(isEdit: isEdit) }

                    if isEdit == false,
                       viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                       viewModel.quickEntrySuggestions.isEmpty == false {
                        VStack(spacing: AislySpacing.small) {
                            ForEach(viewModel.quickEntrySuggestions) { suggestion in
                                quickEntryRow(suggestion)
                            }
                        }
                    }

                    editorField(title: "Quantity") {
                        HStack(spacing: AislySpacing.medium) {
                            quantityField
                            unitSegmented
                        }
                    }

                    AislyInputField(
                        text: draftPlannedPriceBinding,
                        title: Text(verbatim: "Planned Value"),
                        prompt: Text(verbatim: "R$ 0,00"),
                        keyboardType: .decimalPad,
                        textInputAutocapitalization: .never
                    ) {
                        Text(verbatim: "BRL")
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
                    }

                    if isTemplate == false {
                        AislyInputField(
                            text: draftActualPriceBinding,
                            title: Text(verbatim: "Actual Value"),
                            prompt: Text(verbatim: "R$ 0,00"),
                            keyboardType: .decimalPad,
                            textInputAutocapitalization: .never
                        ) {
                            Text(verbatim: "BRL")
                                .font(AislyTypography.caption)
                                .foregroundStyle(AislyColor.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: AislySpacing.small) {
                        HStack {
                            Text(verbatim: "Category")
                                .font(AislyTypography.fieldLabel)
                                .foregroundStyle(AislyColor.textSecondary)
                            Spacer()
                            Text(verbatim: "Swipe for more")
                                .font(AislyTypography.small)
                                .foregroundStyle(AislyColor.textTertiary)
                        }
                        categoryChips
                    }

                    editorField(title: "Note (optional)") { noteField }

                    favoriteRow

                    let isTyping = isEdit == false && viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

                    if isTyping, viewModel.storeSuggestions.isEmpty == false {
                        VStack(alignment: .leading, spacing: AislySpacing.small) {
                            AislySectionHeader(AppStrings.ListDetail.storeSuggestionsSectionTitle)
                            ForEach(viewModel.storeSuggestions) { suggestion in
                                storeSuggestionRow(suggestion)
                            }
                        }
                    }

                    if isTyping, let priceMemorySuggestion = viewModel.priceMemorySuggestion {
                        VStack(alignment: .leading, spacing: AislySpacing.small) {
                            AislySectionHeader(AppStrings.ListDetail.priceMemorySectionTitle)
                            priceMemoryRow(priceMemorySuggestion)
                        }
                    }
                }
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Editor field building blocks

    private func editorField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            Text(verbatim: title)
                .font(AislyTypography.fieldLabel)
                .foregroundStyle(AislyColor.textSecondary)
            content()
        }
    }

    private func editorCircleButton(
        systemImage: String,
        tone: Color,
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tone)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AislyColor.surfaceSecondary))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .accessibilityLabel(Text(verbatim: label))
    }

    private func editorFieldBackground() -> some View {
        RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
            .fill(AislyColor.surfaceSecondary)
    }

    private func nameField(isEdit: Bool) -> some View {
        HStack(spacing: AislySpacing.small) {
            Image(systemName: isEdit ? "pencil" : "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AislyColor.textSecondary)

            TextField(
                text: draftNameBinding,
                prompt: Text(verbatim: isEdit ? "Item name" : "Search or type a new name")
                    .foregroundColor(AislyColor.textTertiary)
            ) { EmptyView() }
                .foregroundStyle(AislyColor.textPrimary)
                .font(AislyTypography.body)

            if viewModel.draftName.isEmpty == false {
                Button { viewModel.updateDraftName("") } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AislyColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 52)
        .background(editorFieldBackground())
    }

    private var quantityField: some View {
        HStack(spacing: AislySpacing.small) {
            TextField(
                text: quantityStringBinding,
                prompt: Text(verbatim: "1").foregroundColor(AislyColor.textTertiary)
            ) { EmptyView() }
                .keyboardType(.numberPad)
                .foregroundStyle(AislyColor.textPrimary)
                .font(AislyTypography.body)

            Text(verbatim: viewModel.draftUnit.rawValue)
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textTertiary)
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 52)
        .background(editorFieldBackground())
    }

    private var unitSegmented: some View {
        HStack(spacing: 0) {
            ForEach(ShoppingItem.Unit.allCases) { unit in
                let selected = viewModel.draftUnit == unit
                Button { viewModel.updateDraftUnit(unit) } label: {
                    Text(verbatim: unit.rawValue)
                        .font(AislyTypography.caption.weight(.semibold))
                        .foregroundStyle(selected ? AislyColor.textPrimary : AislyColor.textSecondary)
                        .frame(width: 34, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: AislyCornerRadius.small, style: .continuous)
                                .fill(selected ? AislyColor.surfacePrimary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private var orderedEditorCategories: [ShoppingItem.Category] {
        let selected = viewModel.draftCategory
        return [selected] + viewModel.availableCategories.filter { $0.matches(selected) == false }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AislySpacing.small) {
                ForEach(orderedEditorCategories) { category in
                    let selected = viewModel.draftCategory == category
                    let appearance = viewModel.categoryAppearance(for: category)
                    Button { viewModel.updateDraftCategory(category) } label: {
                        HStack(spacing: AislySpacing.small) {
                            AislyCategoryIcon(
                                systemName: appearance.iconName,
                                color: Color.aislyListHex(appearance.colorHex),
                                size: .small
                            )
                            Text(AppStrings.ListDetail.categoryTitle(for: category))
                                .font(AislyTypography.body.weight(.medium))
                                .foregroundStyle(AislyColor.textPrimary)
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AislyColor.primary)
                            }
                        }
                        .padding(.horizontal, AislySpacing.medium)
                        .padding(.vertical, AislySpacing.small)
                        .background(Capsule(style: .continuous).fill(AislyColor.surfaceSecondary))
                        .overlay(Capsule(style: .continuous).stroke(selected ? AislyColor.primary : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var noteField: some View {
        TextField(
            text: draftNoteBinding,
            prompt: Text(verbatim: "e.g. prefer organic").foregroundColor(AislyColor.textTertiary)
        ) { EmptyView() }
            .foregroundStyle(AislyColor.textPrimary)
            .font(AislyTypography.body)
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 52)
            .background(editorFieldBackground())
    }

    private var favoriteRow: some View {
        HStack(spacing: AislySpacing.small) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundStyle(AislyColor.secondary)
            Text(verbatim: "Favorite")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textPrimary)
            Spacer()
            AislySwitch(isOn: draftIsFavoriteBinding)
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 56)
        .background(editorFieldBackground())
    }

    private func quickEntryRow(_ suggestion: ListDetailViewModel.QuickEntrySuggestion) -> some View {
        AislyItemRow(
            title: suggestion.name,
            note: suggestion.storeName.map { Text(verbatim: $0) },
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
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func storeSuggestionRow(_ suggestion: ListDetailViewModel.StoreSuggestion) -> some View {
        AislyItemRow(
            title: suggestion.name,
            detail: Text(suggestion.lastUsedAt, format: .dateTime.month(.abbreviated).day().hour().minute()),
            tapAction: {
                viewModel.applyStoreSuggestion(id: suggestion.id)
            }
        ) {
            AislyBadge(
                Text(suggestion.usageCount, format: .number),
                tone: .neutral,
                size: .small
            )
        }
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func priceMemoryRow(_ suggestion: ListDetailViewModel.PriceMemorySuggestion) -> some View {
        AislyItemRow(
            title: String(localized: priceMemoryTitle(for: suggestion.kind)),
            detail: Text(suggestion.lastUsedAt, format: .dateTime.month(.abbreviated).day().hour().minute()),
            note: Text(verbatim: suggestion.storeName),
            primaryPrice: currencyText(suggestion.price),
            tapAction: {
                viewModel.applyPriceMemorySuggestion()
            }
        )
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // MARK: - Finish Purchase sheet

    private func finishPurchaseSheet(_ summary: ListDetailViewModel.FinishSummary) -> some View {
        FinishPurchaseSheet(
            summary: FinishPurchaseSheet.Summary(
                listName: summary.listName,
                finishedAt: Date(),
                purchasedItemCount: summary.purchasedItemCount,
                totalItemCount: summary.purchasedItemCount + summary.unpurchasedItemCount,
                unpurchasedItemCount: summary.unpurchasedItemCount,
                missingActualPriceCount: summary.missingActualPriceCount,
                plannedTotal: summary.plannedTotal,
                actualTotal: summary.actualTotal,
                budget: summary.budget,
                budgetDelta: summary.budgetDelta,
                planDelta: summary.planDelta
            ),
            onFinish: {
                Task {
                    if await viewModel.confirmFinishPurchase() {
                        dismiss()
                        toastCenter.show("Purchase saved to History")
                    }
                }
            },
            onReview: {
                viewModel.dismissFinishSummary()
            },
            onClose: {
                viewModel.dismissFinishSummary()
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - List Info sheet

    private var listInfoSheet: some View {
        ListInfoSheet(
            name: $infoName,
            budget: $infoBudget,
            iconName: $infoIconName,
            colorHex: $infoColorHex,
            showsBudget: isTemplate == false,
            title: isTemplate ? "Template Info" : "List Info",
            namePrompt: isTemplate ? "Template name" : "List name",
            availableColorHexes: viewModel.availableColorHexes,
            availableIconNames: viewModel.availableIconNames,
            isSaveDisabled: infoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                Task {
                    await viewModel.updateListInfo(
                        name: infoName,
                        budget: budgetDecimal(from: infoBudget),
                        iconName: infoIconName,
                        colorHex: infoColorHex
                    )
                    isInfoPresented = false
                }
            },
            onClose: {
                isInfoPresented = false
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func presentInfo() {
        infoName = viewModel.listName
        infoBudget = budgetString(from: viewModel.listBudget)
        infoIconName = viewModel.listIconName
        infoColorHex = viewModel.listColorHex
        isInfoPresented = true
    }

    // MARK: - Save as Template sheet

    private var saveTemplateSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $templateName,
                        prompt: Text(verbatim: "Template name")
                    ) {
                        Text(verbatim: "Template name")
                    }

                    Picker(selection: $templateRecurrence) {
                        ForEach(ShoppingList.TemplateRecurrence.allCases) { recurrence in
                            Text(verbatim: recurrenceLabel(recurrence)).tag(recurrence)
                        }
                    } label: {
                        Text(verbatim: "Recurrence")
                    }
                } header: {
                    AislySectionHeader(Text(verbatim: "Save as Template"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundSecondary)
            .navigationTitle(Text(verbatim: "Save as Template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isSaveTemplatePresented = false
                    } label: {
                        Text(AppStrings.Common.cancelButtonTitle)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let saved = await viewModel.saveAsTemplate(
                                name: templateName,
                                recurrence: templateRecurrence
                            )
                            isSaveTemplatePresented = false
                            if saved {
                                toastCenter.show("Template created")
                            }
                        }
                    } label: {
                        Text(verbatim: "Save")
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .tint(AislyColor.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func presentSaveAsTemplate() {
        templateName = viewModel.listName
        templateRecurrence = .weekly
        isSaveTemplatePresented = true
    }

    // MARK: - Reorder Categories sheet

    private var reorderCategoriesSheet: some View {
        ReorderCategoriesSheet(
            rows: viewModel.availableCategories.map { category in
                let appearance = viewModel.categoryAppearance(for: category)
                return ReorderCategoriesSheet.Row(
                    category: category,
                    iconName: appearance.iconName,
                    colorHex: appearance.colorHex
                )
            },
            onReorder: { orderedIDs in
                Task { await viewModel.applyCategoryOrder(orderedIDs) }
            },
            onClose: { isReorderCategoriesPresented = false }
        )
    }

    private func recurrenceLabel(_ recurrence: ShoppingList.TemplateRecurrence) -> String {
        switch recurrence {
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        }
    }

    // MARK: - Moves

    private func handleMove(fromOffsets: IndexSet, toOffset: Int) {
        Task {
            await viewModel.moveItems(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }

    // MARK: - Bindings

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

    private var finishSummaryBinding: Binding<ListDetailViewModel.FinishSummary?> {
        Binding(
            get: { viewModel.finishSummary },
            set: { updatedValue in
                if updatedValue == nil {
                    viewModel.dismissFinishSummary()
                }
            }
        )
    }

    private var draftNameBinding: Binding<String> {
        Binding(get: { viewModel.draftName }, set: { viewModel.updateDraftName($0) })
    }

    private var quantityStringBinding: Binding<String> {
        Binding(
            get: { String(viewModel.draftQuantity) },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                viewModel.updateDraftQuantity(max(1, Int(digits) ?? 1))
            }
        )
    }

    private var draftNoteBinding: Binding<String> {
        Binding(get: { viewModel.draftNote }, set: { viewModel.updateDraftNote($0) })
    }

    private var draftIsFavoriteBinding: Binding<Bool> {
        Binding(get: { viewModel.draftIsFavorite }, set: { viewModel.updateDraftIsFavorite($0) })
    }

    private var draftCategoryBinding: Binding<ShoppingItem.Category> {
        Binding(get: { viewModel.draftCategory }, set: { viewModel.updateDraftCategory($0) })
    }

    private var draftStoreNameBinding: Binding<String> {
        Binding(get: { viewModel.draftStoreName }, set: { viewModel.updateDraftStoreName($0) })
    }

    private var draftPlannedPriceBinding: Binding<String> {
        Binding(get: { viewModel.draftPlannedPrice }, set: { viewModel.updateDraftPlannedPrice($0) })
    }

    private var draftActualPriceBinding: Binding<String> {
        Binding(get: { viewModel.draftActualPrice }, set: { viewModel.updateDraftActualPrice($0) })
    }

    private var draftQuantityBinding: Binding<Int> {
        Binding(get: { viewModel.draftQuantity }, set: { viewModel.updateDraftQuantity($0) })
    }

    // MARK: - Formatting

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: AislySpacing.small,
            leading: AislySpacing.large,
            bottom: AislySpacing.small,
            trailing: AislySpacing.large
        )
    }

    private func editorTitle(for editorMode: ListDetailViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create: return AppStrings.ListDetail.addItemSheetTitle
        case .edit: return AppStrings.ListDetail.editItemSheetTitle
        }
    }

    private func editorActionTitle(for editorMode: ListDetailViewModel.EditorMode) -> LocalizedStringResource {
        switch editorMode {
        case .create: return AppStrings.ListDetail.addItemConfirmButtonTitle
        case .edit: return AppStrings.ListDetail.editItemConfirmButtonTitle
        }
    }

    private func budgetDeltaTone(for delta: Decimal?) -> AislyBudgetSummaryCard.DeltaTone {
        guard let delta else { return .neutral }
        if delta == .zero { return .neutral }
        return delta > .zero ? .underBudget : .overBudget
    }

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private func currencyString(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode))
    }

    private func priceMemoryTitle(for kind: ListDetailViewModel.PriceMemorySuggestion.Kind) -> LocalizedStringResource {
        switch kind {
        case .actual: return AppStrings.ListDetail.lastActualPriceMemoryTitle
        case .planned: return AppStrings.ListDetail.lastPlannedPriceMemoryTitle
        }
    }

    private func budgetString(from value: Decimal?) -> String {
        guard let value else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }

    private func budgetDecimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true

        let separator = Locale.autoupdatingCurrent.decimalSeparator ?? "."
        let candidates = [
            trimmed,
            trimmed.replacingOccurrences(of: ",", with: "."),
            trimmed.replacingOccurrences(of: ".", with: separator)
        ]

        for candidate in candidates {
            if let number = formatter.number(from: candidate) {
                let decimal = number.decimalValue
                return decimal >= .zero ? decimal : nil
            }
        }

        return nil
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }
}

/// Dedicated reorder mode for category sections — a native `List` locked in
/// edit mode, so every row gets a guaranteed drag handle (no long-press vs.
/// scroll conflicts). Each move persists the full order immediately.
private struct ReorderCategoriesSheet: View {
    struct Row: Identifiable {
        let category: ShoppingItem.Category
        let iconName: String
        let colorHex: UInt32

        var id: String { category.id }
    }

    @State var rows: [Row]
    let onReorder: ([String]) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows) { row in
                        HStack(spacing: AislySpacing.medium) {
                            AislyCategoryIcon(
                                systemName: row.iconName,
                                color: Color.aislyListHex(row.colorHex),
                                size: .small
                            )

                            Text(AppStrings.ListDetail.categoryTitle(for: row.category))
                                .font(AislyTypography.rowTitle)
                                .foregroundStyle(AislyColor.textPrimary)
                        }
                        .listRowBackground(AislyColor.surfacePrimary)
                    }
                    .onMove { offsets, destination in
                        rows.move(fromOffsets: offsets, toOffset: destination)
                        onReorder(rows.map(\.id))
                    }
                } footer: {
                    Text(verbatim: "Drag the handles to set the category order used in every list and board.")
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundSecondary)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(Text(verbatim: "Reorder Categories"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onClose) {
                        Text(verbatim: "Done")
                            .fontWeight(.semibold)
                    }
                    .tint(AislyColor.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
