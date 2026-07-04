import SwiftUI

struct ItemDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ItemDatabaseViewModel

    @State private var editMode: EditMode = .inactive

    // Multi-select mode (native EditMode → selection circles).
    @State private var selectedIDs: Set<UUID> = []
    @State private var pendingBulkDelete = false

    // Item search (magnifier).
    @State private var isSearchActive = false
    @FocusState private var searchFocused: Bool

    // Custom more-menu (native Menu can't render the kit's teal highlight).
    @State private var isMoreMenuOpen = false

    init(viewModel: ItemDatabaseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isSelecting: Bool { editMode.isEditing }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .environment(\.editMode, $editMode)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(isPresented: $viewModel.isAddSheetPresented) {
                ItemDraftSheet(viewModel: viewModel)
            }
            .alert(
                Text(verbatim: "Delete item"),
                isPresented: deleteAlertPresented,
                presenting: viewModel.pendingDeletion
            ) { _ in
                Button(role: .destructive) {
                    Task { await viewModel.confirmDeletePendingItem() }
                } label: {
                    Text(verbatim: "Delete")
                }

                Button(role: .cancel) {
                    viewModel.dismissDeleteConfirmation()
                } label: {
                    Text(verbatim: "Cancel")
                }
            } message: { deletion in
                Text(verbatim: "\"\(deletion.name)\" will be permanently removed from the item database. This cannot be undone.")
            }
            .alert(
                Text(verbatim: "Delete \(selectedIDs.count) items from the item database?"),
                isPresented: $pendingBulkDelete
            ) {
                Button(role: .destructive) {
                    let ids = selectedIDs
                    Task {
                        await viewModel.deleteItems(ids: ids)
                        exitSelection()
                    }
                } label: {
                    Text(verbatim: "Delete")
                }

                Button(role: .cancel) {} label: {
                    Text(verbatim: "Cancel")
                }
            } message: {
                Text(verbatim: "This cannot be undone.")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.ItemDatabase.screenLoadingTitle)

        case .loaded:
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    mainBody
                }

                if isSelecting {
                    selectionBar
                } else if !isSearchActive && viewModel.canCreateItem {
                    addItemFab.frame(maxWidth: .infinity, alignment: .trailing)
                }

                if isMoreMenuOpen {
                    moreMenuOverlay
                }
            }

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AislyColor.error),
                title: AppStrings.ItemDatabase.screenFailureTitle,
                description: AppStrings.ItemDatabase.screenFailureDescription
            ) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text(verbatim: "Retry")
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var mainBody: some View {
        if viewModel.hasAnyEntry == false {
            AislyEmptyState(
                icon: Image(systemName: "tray"),
                title: AppStrings.ItemDatabase.emptyTitle,
                description: AppStrings.ItemDatabase.emptyDescription
            ) {
                Button {
                    viewModel.presentAddItem()
                } label: {
                    Text(verbatim: "Add item")
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        } else {
            VStack(spacing: 0) {
                titleView

                segmentedControl
                    .padding(.horizontal, AislySpacing.large)
                    .padding(.top, AislySpacing.medium)

                if viewModel.rows.isEmpty {
                    noResultsBody
                } else {
                    itemsList
                }
            }
        }
    }

    private var titleView: some View {
        Text(verbatim: "Items")
            .font(AislyTypography.pageTitle)
            .foregroundStyle(AislyColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AislySpacing.large)
            .padding(.top, AislySpacing.xSmall)
    }

    private var noResultsBody: some View {
        AislyEmptyState(
            icon: Image(systemName: "magnifyingglass"),
            title: AppStrings.ItemDatabase.noResultsTitle,
            description: AppStrings.ItemDatabase.noResultsDescription
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            if isSearchActive {
                searchBar
            }
        }
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        if editMode.isEditing {
            HStack {
                Button {
                    if selectedIDs == currentRowIDs {
                        selectedIDs = []
                    } else {
                        selectedIDs = currentRowIDs
                    }
                } label: {
                    Text(verbatim: selectedIDs == currentRowIDs && currentRowIDs.isEmpty == false ? "Deselect All" : "Select All")
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
        } else if isSearchActive {
            Color.clear.frame(height: AislySpacing.small)
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
                        Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(Text(verbatim: "Item options"))
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

    // MARK: - Segmented control (custom, matches the kit)

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segment(title: "All", scope: .all)
            segment(title: "Active", scope: .active)
            segment(title: "Archived", scope: .archived)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func segment(title: String, scope: ItemDatabaseViewModel.Scope) -> some View {
        let isSelected = viewModel.scope == scope
        return Button {
            withAnimation(AislyMotion.quick) { viewModel.scope = scope }
        } label: {
            Text(verbatim: title)
                .font(AislyTypography.body.weight(.semibold))
                .foregroundStyle(isSelected ? AislyColor.textPrimary : AislyColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: AislyCornerRadius.small, style: .continuous)
                        .fill(isSelected ? AislyColor.surfacePrimary : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Items list

    private var itemsList: some View {
        List(selection: $selectedIDs) {
            Section {
                ForEach(viewModel.rows) { row in
                    itemRow(row)
                }
            }

            Section {
                helpText
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .selectionDisabled()
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(AislySpacing.small)
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

    private var helpText: some View {
        Text(verbatim: "Every item added to any list is stored here for reuse.\nSwipe left for Archive · Delete.")
            .font(AislyTypography.small)
            .foregroundStyle(AislyColor.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AislySpacing.xSmall)
    }

    // MARK: - Item row card

    private func itemRow(_ row: ItemDatabaseViewModel.ItemRow) -> some View {
        Group {
            if isSelecting {
                itemRowContent(row)
            } else {
                Button { viewModel.presentEditItem(id: row.id) } label: {
                    itemRowContent(row)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.presentDeleteConfirmation(id: row.id)
            } label: {
                Label {
                    Text(verbatim: "Delete")
                } icon: {
                    Image(systemName: "trash")
                }
            }

            Button {
                Task {
                    if row.isArchived {
                        await viewModel.unarchiveItem(id: row.id)
                    } else {
                        await viewModel.archiveItem(id: row.id)
                    }
                }
            } label: {
                Label {
                    Text(verbatim: row.isArchived ? "Unarchive" : "Archive")
                } icon: {
                    Image(systemName: row.isArchived ? "archivebox.fill" : "archivebox")
                }
            }
            .tint(row.isArchived ? AislyColor.success : AislyColor.archive)
        }
    }

    private func itemRowContent(_ row: ItemDatabaseViewModel.ItemRow) -> some View {
        HStack(alignment: .center, spacing: AislySpacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AislySpacing.xSmall) {
                    Text(row.name)
                        .font(AislyTypography.rowTitle)
                        .foregroundStyle(AislyColor.textPrimary)
                        .lineLimit(1)

                    if row.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AislyColor.secondary)
                    }
                }

                subtitleText(for: row)
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                if let actual = row.actualPrice {
                    currencyText(actual)
                        .font(AislyTypography.caption.weight(.semibold))
                        .foregroundStyle(AislyColor.textPrimary)
                }
                if let planned = row.plannedPrice {
                    (Text(verbatim: "Planned ") + currencyText(planned))
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                }
            }

            if row.isArchived {
                AislyBadge(Text(verbatim: "Archived"), tone: .archive, size: .small)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.textTertiary)
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .stroke(AislyColor.borderSubtle, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func subtitleText(for row: ItemDatabaseViewModel.ItemRow) -> Text {
        let usage = row.usageCount == 1
            ? Text(verbatim: " · used in 1 list")
            : Text(verbatim: " · used in \(row.usageCount) lists")
        return Text(AppStrings.ListDetail.categoryTitle(for: row.category)) + usage
    }

    // MARK: - Search bar (docked above keyboard)

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $viewModel.searchQuery,
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
                    viewModel.searchQuery = ""
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

    // MARK: - FAB

    private var addItemFab: some View {
        Button {
            viewModel.presentAddItem()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AislyColor.primaryForeground)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AislyColor.primary))
                .aislyShadow(AislyShadow.fab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Add item"))
        .padding(AislySpacing.xLarge)
    }

    // MARK: - Selection bar

    private var selectionBar: some View {
        HStack(spacing: AislySpacing.large) {
            Text(verbatim: selectedIDs.isEmpty ? "0 selected" : "\(selectedIDs.count) selected")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textSecondary)

            Spacer()

            circleAction(
                systemImage: "archivebox",
                fill: AislyColor.archive,
                label: "Archive selected",
                enabled: !selectedIDs.isEmpty
            ) {
                let ids = selectedIDs
                Task {
                    await viewModel.archiveItems(ids: ids)
                    exitSelection()
                }
            }

            circleAction(
                systemImage: "trash",
                fill: AislyColor.error,
                label: "Delete selected",
                enabled: !selectedIDs.isEmpty
            ) {
                pendingBulkDelete = true
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

    private var currentRowIDs: Set<UUID> {
        Set(viewModel.rows.map(\.id))
    }

    private func exitSelection() {
        editMode = .inactive
        selectedIDs = []
    }

    // MARK: - … menu (custom panel — native Menu can't tint items like the kit)

    private var moreMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Tap-outside catcher.
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { closeMoreMenu() }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    moreMenuRow(title: "Select Items", systemName: "checkmark.circle") {
                        withAnimation { editMode = .active }
                        selectedIDs = []
                    }

                    menuGroupSeparator

                    menuSectionHeader("SORT BY")

                    ForEach(ItemDatabaseViewModel.SortOption.allCases) { option in
                        sortMenuRow(option)
                    }

                    menuGroupSeparator

                    menuSectionHeader("CATEGORY")

                    categoryMenuRow(nil)

                    ForEach(viewModel.availableCategories) { category in
                        categoryMenuRow(category)
                    }
                }
                .padding(.vertical, AislySpacing.small)
            }
            .frame(width: 280)
            .frame(maxHeight: 520)
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

    private func menuSectionHeader(_ title: String) -> some View {
        Text(verbatim: title)
            .font(AislyTypography.small.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(AislyColor.textTertiary)
            .padding(.horizontal, AislySpacing.large)
            .padding(.top, AislySpacing.medium)
            .padding(.bottom, AislySpacing.xSmall)
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

    private func sortMenuRow(_ option: ItemDatabaseViewModel.SortOption) -> some View {
        Button {
            closeMoreMenu()
            viewModel.sortOption = option
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .opacity(viewModel.sortOption == option ? 1 : 0)
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
        .accessibilityAddTraits(viewModel.sortOption == option ? .isSelected : [])
    }

    private func categoryMenuRow(_ category: ShoppingItem.Category?) -> some View {
        let isSelected: Bool = {
            guard let category else {
                return viewModel.categoryFilter == nil
            }
            return viewModel.categoryFilter.map { $0.matches(category) } ?? false
        }()

        return Button {
            closeMoreMenu()
            viewModel.categoryFilter = category
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: 24)

                if let category {
                    Text(AppStrings.ListDetail.categoryTitle(for: category))
                        .font(AislyTypography.body)
                        .foregroundStyle(AislyColor.textPrimary)
                } else {
                    Text(verbatim: "All categories")
                        .font(AislyTypography.body)
                        .foregroundStyle(AislyColor.textPrimary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Helpers

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }

    private var rowInsets: EdgeInsets {
        // Tight vertical insets → ~8pt gap between cards, matching the kit.
        EdgeInsets(
            top: AislySpacing.xSmall,
            leading: AislySpacing.large,
            bottom: AislySpacing.xSmall,
            trailing: AislySpacing.large
        )
    }

    private var deleteAlertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeletion != nil },
            set: { updatedValue in
                if updatedValue == false {
                    viewModel.dismissDeleteConfirmation()
                }
            }
        )
    }
}

// MARK: - Add / Edit sheet

private struct ItemDraftSheet: View {
    @ObservedObject var viewModel: ItemDatabaseViewModel

    private var isEdit: Bool { viewModel.editingItemID != nil }

    var body: some View {
        AislySheetContainer(
            title: Text(verbatim: isEdit ? "Edit Item" : "Add Item"),
            trailing: {
                HStack(spacing: AislySpacing.medium) {
                    circleButton(systemImage: "xmark", tone: AislyColor.textSecondary, label: "Close") {
                        viewModel.dismissAddItem()
                    }
                    circleButton(
                        systemImage: "checkmark",
                        tone: viewModel.isAddSubmissionDisabled ? AislyColor.textTertiary : AislyColor.primary,
                        label: isEdit ? "Save item" : "Add item",
                        enabled: viewModel.isAddSubmissionDisabled == false
                    ) {
                        Task { await viewModel.saveDraft() }
                    }
                }
            },
            content: {
                VStack(alignment: .leading, spacing: AislySpacing.xLarge) {
                    fieldSection(title: "Item Name") { nameField }

                    fieldSection(title: "Quantity") {
                        HStack(spacing: AislySpacing.medium) {
                            quantityField
                            unitSegmented
                        }
                    }

                    AislyInputField(
                        text: $viewModel.draftPlannedPrice,
                        title: Text(verbatim: "Planned Value"),
                        prompt: Text(verbatim: "R$ 0,00"),
                        keyboardType: .decimalPad,
                        textInputAutocapitalization: .never
                    ) {
                        Text(verbatim: "BRL")
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
                    }

                    AislyInputField(
                        text: $viewModel.draftActualPrice,
                        title: Text(verbatim: "Actual Value"),
                        prompt: Text(verbatim: "R$ 0,00"),
                        keyboardType: .decimalPad,
                        textInputAutocapitalization: .never
                    ) {
                        Text(verbatim: "BRL")
                            .font(AislyTypography.caption)
                            .foregroundStyle(AislyColor.textTertiary)
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

                    fieldSection(title: "Note (optional)") { noteField }

                    favoriteRow

                    Spacer(minLength: 0)
                }
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var quantityBinding: Binding<String> {
        Binding(
            get: { String(viewModel.draftQuantity) },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                viewModel.draftQuantity = max(1, Int(digits) ?? 1)
            }
        )
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
            .fill(AislyColor.surfaceSecondary)
    }

    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            Text(verbatim: title)
                .font(AislyTypography.fieldLabel)
                .foregroundStyle(AislyColor.textSecondary)
            content()
        }
    }

    private var nameField: some View {
        HStack(spacing: AislySpacing.small) {
            Image(systemName: isEdit ? "pencil" : "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AislyColor.textSecondary)

            TextField(
                text: $viewModel.draftName,
                prompt: Text(verbatim: isEdit ? "Item name" : "Search or type a new name")
                    .foregroundColor(AislyColor.textTertiary)
            ) { EmptyView() }
                .foregroundStyle(AislyColor.textPrimary)
                .font(AislyTypography.body)

            if viewModel.draftName.isEmpty == false {
                Button { viewModel.draftName = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AislyColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 52)
        .background(fieldBackground)
    }

    private var quantityField: some View {
        HStack(spacing: AislySpacing.small) {
            TextField(
                text: quantityBinding,
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
        .background(fieldBackground)
    }

    private var unitSegmented: some View {
        HStack(spacing: 0) {
            ForEach(ShoppingItem.Unit.allCases) { unit in
                let selected = viewModel.draftUnit == unit
                Button { viewModel.draftUnit = unit } label: {
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

    private var noteField: some View {
        TextField(
            text: $viewModel.draftNote,
            prompt: Text(verbatim: "e.g. prefer organic").foregroundColor(AislyColor.textTertiary)
        ) { EmptyView() }
            .foregroundStyle(AislyColor.textPrimary)
            .font(AislyTypography.body)
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 52)
            .background(fieldBackground)
    }

    private var orderedCategories: [ShoppingItem.Category] {
        let selected = viewModel.draftCategory
        return [selected] + viewModel.availableCategories.filter { $0.matches(selected) == false }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AislySpacing.small) {
                ForEach(orderedCategories) { category in
                    let selected = viewModel.draftCategory == category
                    let appearance = viewModel.categoryAppearance(for: category)
                    Button { viewModel.draftCategory = category } label: {
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

    private var favoriteRow: some View {
        HStack(spacing: AislySpacing.small) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundStyle(AislyColor.secondary)
            Text(verbatim: "Favorite")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textPrimary)
            Spacer()
            AislySwitch(isOn: $viewModel.draftIsFavorite)
        }
        .padding(.horizontal, AislySpacing.large)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func circleButton(
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
}
