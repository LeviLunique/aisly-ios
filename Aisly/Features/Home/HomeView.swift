import SwiftUI

struct HomeView: View {
    enum SortOption: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case name = "Name"
        var id: String { rawValue }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case withBudget = "With budget"
        case noBudget = "No budget"
        var id: String { rawValue }
    }

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HomeViewModel
    // Shared toast presenter, hosted here (the navigation root) so success
    // feedback survives screen pops — e.g. finishing a purchase dismisses
    // the list before its toast appears.
    @StateObject private var toastCenter = AislyToastCenter()
    @State private var navigationPath: [AppRoute] = []
    @State private var searchQuery = ""
    @State private var isSearchActive = false
    @FocusState private var searchFocused: Bool

    // Sort / filter (TopBar menu).
    @State private var sortOption: SortOption = .manual
    @State private var filterOption: FilterOption = .all

    // Multi-select mode (native EditMode → selection circles + drag handles).
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<UUID> = []
    @State private var pendingBulkDelete = false

    // List Info editor.
    @State private var infoListID: UUID?
    @State private var infoName = ""
    @State private var infoBudget = ""
    @State private var infoIconName = ShoppingList.defaultIconName
    @State private var infoColorHex = ShoppingList.defaultColorHex

    // Single-row delete confirmation.
    @State private var pendingDeleteID: UUID?

    private let makeDestination: @MainActor (AppRoute) -> AnyView

    init(
        viewModel: HomeViewModel,
        makeDestination: @escaping @MainActor (AppRoute) -> AnyView
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeDestination = makeDestination
    }

    private var isSelecting: Bool { editMode.isEditing }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    content
                }
                .background(AislyColor.backgroundPrimary.ignoresSafeArea())
                .navigationDestination(for: AppRoute.self) { route in
                    makeDestination(route)
                }
                .toolbar(.hidden, for: .navigationBar)

                if isSelecting {
                    selectionBar
                } else if !isSearchActive && viewModel.canCreateList {
                    fab.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .aislyToastHost(toastCenter)
        .environmentObject(toastCenter)
        .onOpenURL(perform: handleOpenURL)
        .task {
            await viewModel.loadIfNeeded()
            applyPendingAppleSurfaceRouteIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            applyPendingAppleSurfaceRouteIfNeeded()
        }
        .onChange(of: navigationPath) { _, newPath in
            applyPendingAppleSurfaceRouteIfNeeded()
            if newPath.isEmpty {
                Task { await viewModel.reload() }
            }
        }
        .sheet(item: newListSheetBinding, onDismiss: { viewModel.dismissEditor() }) { _ in
            newListSheet
        }
        .sheet(isPresented: infoSheetPresented, onDismiss: resetInfoDraft) {
            listInfoSheet
        }
        .alert(
            Text(verbatim: "Delete list permanently?"),
            isPresented: deleteConfirmationBinding
        ) {
            Button(role: .destructive) {
                guard let pendingDeleteID else { return }
                Task {
                    await viewModel.deleteList(id: pendingDeleteID)
                    self.pendingDeleteID = nil
                }
            } label: { Text(AppStrings.Common.deleteButtonTitle) }
            Button(role: .cancel) { pendingDeleteID = nil } label: { Text(AppStrings.Common.cancelButtonTitle) }
        } message: {
            Text(verbatim: "This will remove the list, its sections, and current item values. This action cannot be undone.")
        }
        .alert(
            Text(verbatim: "Delete \(selectedIDs.count) lists permanently?"),
            isPresented: $pendingBulkDelete
        ) {
            Button(role: .destructive) {
                let ids = selectedIDs
                Task {
                    await viewModel.deleteLists(ids: ids)
                    exitSelection()
                }
            } label: { Text(AppStrings.Common.deleteButtonTitle) }
            Button(role: .cancel) {} label: { Text(AppStrings.Common.cancelButtonTitle) }
        } message: {
            Text(verbatim: "This will remove the lists, their sections, and current item values. This action cannot be undone.")
        }
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        if isSelecting {
            HStack {
                Button {
                    if selectedIDs == currentListIDs {
                        selectedIDs = []
                    } else {
                        selectedIDs = currentListIDs
                    }
                } label: {
                    Text(verbatim: selectedIDs == currentListIDs && currentListIDs.isEmpty == false ? "Deselect All" : "Select All")
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
                Spacer()
                HStack(spacing: AislySpacing.large) {
                    Button {
                        withAnimation(AislyMotion.quick) { isSearchActive = true }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(Text(verbatim: "Search"))

                    Menu {
                        menuContent
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
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

    @ViewBuilder
    private var menuContent: some View {
        Button {
            editMode = .active
            selectedIDs = []
        } label: {
            Label(String(localized: "Select Lists", defaultValue: "Select Lists"), systemImage: "checkmark.circle")
        }

        Picker(selection: $sortOption) {
            ForEach(SortOption.allCases) { option in
                Text(verbatim: option.rawValue).tag(option)
            }
        } label: {
            Text(verbatim: "Sort By")
        }

        Picker(selection: $filterOption) {
            ForEach(FilterOption.allCases) { option in
                Text(verbatim: option.rawValue).tag(option)
            }
        } label: {
            Text(verbatim: "Filter")
        }
    }

    // MARK: - FAB

    private var fab: some View {
        Button {
            viewModel.presentCreateList()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AislyColor.primaryForeground)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AislyColor.primary))
                .aislyShadow(AislyShadow.fab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AppStrings.Home.createListToolbarTitle))
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
                fill: AislyColor.primary,
                label: "Archive selected",
                enabled: !selectedIDs.isEmpty
            ) {
                let ids = selectedIDs
                Task {
                    await viewModel.archiveLists(ids: ids)
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

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.Home.loadingTitle)

        case .loaded(let snapshot):
            List(selection: $selectedIDs) {
                if !isSelecting {
                    shortcutGridSection
                }
                listsSection(snapshot)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundPrimary)
            .environment(\.editMode, $editMode)
            .tint(AislyColor.primary)
            .safeAreaInset(edge: .bottom) {
                if isSearchActive {
                    searchBar
                } else {
                    Color.clear.frame(height: isSelecting ? 76 : 88)
                }
            }

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(AislyColor.error),
                title: AppStrings.Home.failureTitle,
                description: AppStrings.Home.failureDescription
            ) {
                Button {
                    Task { await viewModel.load() }
                } label: { Text(AppStrings.Home.retryButtonTitle) }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    // MARK: - Search bar (docked above the keyboard, native TextField)

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $searchQuery,
                    prompt: Text(verbatim: "Search lists and items").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search lists and items"))
            }
            .padding(.horizontal, AislySpacing.medium)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )

            Button { closeSearch() } label: {
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
        // Focus once the field is actually in the hierarchy so the keyboard
        // reliably rises (focusing before it renders is silently dropped).
        .onAppear { searchFocused = true }
    }

    private func closeSearch() {
        searchFocused = false
        withAnimation(AislyMotion.quick) {
            isSearchActive = false
            searchQuery = ""
        }
    }

    // MARK: - My Lists (single grouped card)

    @ViewBuilder
    private func listsSection(_ snapshot: HomeViewModel.ListSnapshot) -> some View {
        let lists = displayedLists(snapshot.activeLists)

        Section {
            if lists.isEmpty {
                Text(verbatim: emptyListsMessage)
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
                    .listRowBackground(AislyColor.surfacePrimary)
            } else {
                ForEach(lists) { list in
                    shoppingListRow(list)
                }
                .onMove { indices, newOffset in
                    var ids = lists.map(\.id)
                    ids.move(fromOffsets: indices, toOffset: newOffset)
                    Task { await viewModel.reorderActiveLists(orderedIDs: ids) }
                }
            }

            if !isSelecting {
                archivedRow(count: snapshot.archivedLists.count)
            }
        } header: {
            AislySectionHeader(Text(verbatim: "My Lists"))
        }
    }

    private var emptyListsMessage: String {
        if searchQuery.isEmpty == false { return "No lists match your search." }
        if filterOption != .all { return "No lists match this filter." }
        return "No lists yet. Tap + to create your first shopping list."
    }

    // MARK: - Shortcut grid (2x2, no chevrons)

    private var shortcutGridSection: some View {
        Section {
            VStack(spacing: AislySpacing.medium) {
                HStack(spacing: AislySpacing.medium) {
                    shortcutTile(title: "History", iconName: "clock", route: .history)
                    shortcutTile(title: "Items", iconName: "tray.full", route: .itemDatabase)
                }
                HStack(spacing: AislySpacing.medium) {
                    shortcutTile(title: "Categories", iconName: "tag", route: .categories)
                    shortcutTile(title: "Templates", iconName: "square.stack", route: .templates)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: AislySpacing.large, bottom: AislySpacing.small, trailing: AislySpacing.large))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private func shortcutTile(title: String, iconName: String, route: AppRoute) -> some View {
        Button {
            navigationPath.append(route)
        } label: {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(AislyColor.primarySurface))

                Text(verbatim: title)
                    .font(AislyTypography.body.weight(.semibold))
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.medium)
            .padding(.vertical, AislySpacing.large)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .fill(AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - List rows

    @ViewBuilder
    private func shoppingListRow(_ list: HomeViewModel.ListRow) -> some View {
        let rowContent = AislyGroupedRow(
            title: list.name,
            subtitle: Text(verbatim: "\(list.itemCount) items · Planned \(currencyString(list.plannedTotal))"),
            leading: {
                AislyCategoryIcon(systemName: list.iconName, color: Color.aislyListHex(list.colorHex))
            },
            trailing: {
                HStack(spacing: AislySpacing.small) {
                    if list.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AislyColor.secondary)
                    }
                    budgetBadge(for: list)
                }
            }
        )
        .padding(.vertical, 4)

        Group {
            if isSelecting {
                // No NavigationLink in edit mode → no disclosure chevron, just the
                // native selection circle and drag handle.
                rowContent
            } else {
                NavigationLink(value: AppRoute.listDetail(list.id)) { rowContent }
            }
        }
        .listRowBackground(AislyColor.surfacePrimary)
        .alignmentGuide(.listRowSeparatorLeading) { dimension in
            dimension[.leading] + 44
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteID = list.id
            } label: {
                Label(String(localized: "Delete", defaultValue: "Delete"), systemImage: "trash")
            }
            .tint(AislyColor.error)

            Button {
                Task { await viewModel.archiveList(id: list.id) }
            } label: {
                Label(String(localized: "Archive", defaultValue: "Archive"), systemImage: "archivebox")
            }
            .tint(AislyColor.archive)

            Button {
                presentInfo(for: list.id)
            } label: {
                Label(String(localized: "Info", defaultValue: "Info"), systemImage: "info.circle")
            }
            .tint(AislyColor.primary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task { await viewModel.togglePin(id: list.id) }
            } label: {
                Label(
                    list.isPinned ? String(localized: "Unpin", defaultValue: "Unpin") : String(localized: "Pin", defaultValue: "Pin"),
                    systemImage: list.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(AislyColor.secondary)
        }
    }

    @ViewBuilder
    private func budgetBadge(for list: HomeViewModel.ListRow) -> some View {
        if list.budget != nil {
            if list.missingPriceCount > 0 {
                AislyBadge(Text(verbatim: "\(list.missingPriceCount) no price"), tone: .warning, size: .small)
            } else if let delta = list.budgetDelta {
                if delta >= .zero {
                    AislyBadge(Text(verbatim: "\(currencyString(delta)) under"), tone: .success, size: .small)
                } else {
                    AislyBadge(Text(verbatim: "\(currencyString(abs(delta))) over"), tone: .error, size: .small)
                }
            } else if let budget = list.budget {
                AislyBadge(Text(verbatim: currencyString(budget)), tone: .neutral, size: .small)
            }
        } else {
            AislyBadge(Text(verbatim: "No budget"), tone: .neutral, size: .small)
        }
    }

    private func archivedRow(count: Int) -> some View {
        NavigationLink(value: AppRoute.archivedLists) {
            AislyGroupedRow(
                title: "Archived",
                leading: {
                    AislyCategoryIcon(systemName: "archivebox", color: AislyColor.archive)
                },
                trailing: {
                    Text(verbatim: "\(count)")
                        .font(AislyTypography.body)
                        .foregroundStyle(AislyColor.textTertiary)
                        .monospacedDigit()
                }
            )
            .padding(.vertical, 4)
        }
        .listRowBackground(AislyColor.surfacePrimary)
        .alignmentGuide(.listRowSeparatorLeading) { dimension in
            dimension[.leading] + 44
        }
        .moveDisabled(true)
        .deleteDisabled(true)
    }

    // MARK: - Selection helpers

    private var currentListIDs: Set<UUID> {
        guard case .loaded(let snapshot) = viewModel.state else { return [] }
        return Set(displayedLists(snapshot.activeLists).map(\.id))
    }

    private func exitSelection() {
        editMode = .inactive
        selectedIDs = []
    }

    // MARK: - New List sheet

    private var newListSheet: some View {
        NewListSheet(
            selectedTab: createListTabBinding,
            name: draftNameBinding,
            budget: draftBudgetBinding,
            iconName: draftIconNameBinding,
            colorHex: draftColorHexBinding,
            availableColorHexes: viewModel.availableColorHexes,
            availableIconNames: viewModel.availableIconNames,
            templates: templateOptions,
            isConfirmDisabled: viewModel.isDraftSubmissionDisabled,
            onConfirm: {
                Task {
                    if let newID = await viewModel.createListReturningID() {
                        navigationPath.append(.listDetail(newID))
                    }
                }
            },
            onUseTemplate: { templateID in
                Task {
                    if let newID = await viewModel.generateListReturningID(fromTemplateID: templateID) {
                        navigationPath.append(.listDetail(newID))
                    }
                }
            },
            onClose: { viewModel.dismissEditor() }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var templateOptions: [NewListSheet.TemplateOption] {
        guard case .loaded(let snapshot) = viewModel.state else { return [] }
        return snapshot.templateLists.map { row in
            NewListSheet.TemplateOption(
                id: row.id,
                name: row.name,
                iconName: row.iconName,
                colorHex: row.colorHex,
                itemCount: row.itemCount,
                plannedTotal: row.plannedTotal
            )
        }
    }

    // MARK: - List Info sheet

    private var listInfoSheet: some View {
        ListInfoSheet(
            name: $infoName,
            budget: $infoBudget,
            iconName: $infoIconName,
            colorHex: $infoColorHex,
            showsBudget: true,
            availableColorHexes: viewModel.availableColorHexes,
            availableIconNames: viewModel.availableIconNames,
            isSaveDisabled: infoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                guard let infoListID else { return }
                Task {
                    await viewModel.updateListInfo(
                        id: infoListID,
                        name: infoName,
                        budget: budgetDecimal(from: infoBudget),
                        iconName: infoIconName,
                        colorHex: infoColorHex
                    )
                    self.infoListID = nil
                }
            },
            onClose: { infoListID = nil }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func presentInfo(for id: UUID) {
        guard let list = viewModel.list(for: id) else { return }
        infoName = list.name
        infoBudget = budgetString(from: list.budget)
        infoIconName = list.iconName
        infoColorHex = list.colorHex
        infoListID = id
    }

    private func resetInfoDraft() {
        infoName = ""
        infoBudget = ""
        infoIconName = ShoppingList.defaultIconName
        infoColorHex = ShoppingList.defaultColorHex
    }

    // MARK: - Filtering / sorting

    private func displayedLists(_ rows: [HomeViewModel.ListRow]) -> [HomeViewModel.ListRow] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        var result = rows.filter { row in
            let matchesQuery = query.isEmpty || row.name.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool
            switch filterOption {
            case .all: matchesFilter = true
            case .withBudget: matchesFilter = row.budget != nil
            case .noBudget: matchesFilter = row.budget == nil
            }
            return matchesQuery && matchesFilter
        }

        if sortOption == .name {
            result.sort { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }

        return result
    }

    // MARK: - Routing

    private func handleOpenURL(_ url: URL) {
        guard let route = AppRoute(url: url) else { return }
        navigate(to: route)
    }

    private func applyPendingAppleSurfaceRouteIfNeeded() {
        guard let route = AppleSurfaceRouteRequestStore.consumePendingRoute() else { return }
        navigate(to: route)
    }

    private func navigate(to route: AppRoute) {
        viewModel.dismissEditor()
        infoListID = nil
        exitSelection()
        if isSearchActive { closeSearch() }

        switch route {
        case .home:
            navigationPath = []
        default:
            navigationPath = [route]
        }
    }

    // MARK: - Bindings

    private var newListSheetBinding: Binding<HomeViewModel.EditorMode?> {
        Binding(
            get: {
                if case .create = viewModel.editorMode { return viewModel.editorMode }
                return nil
            },
            set: { updatedValue in
                if updatedValue == nil { viewModel.dismissEditor() }
            }
        )
    }

    private var infoSheetPresented: Binding<Bool> {
        Binding(
            get: { infoListID != nil },
            set: { isPresented in
                if isPresented == false { infoListID = nil }
            }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { isPresented in
                if isPresented == false { pendingDeleteID = nil }
            }
        )
    }

    private var draftNameBinding: Binding<String> {
        Binding(get: { viewModel.draftName }, set: { viewModel.updateDraftName($0) })
    }

    private var draftBudgetBinding: Binding<String> {
        Binding(get: { viewModel.draftBudget }, set: { viewModel.updateDraftBudget($0) })
    }

    private var draftIconNameBinding: Binding<String> {
        Binding(get: { viewModel.draftIconName }, set: { viewModel.updateDraftIconName($0) })
    }

    private var draftColorHexBinding: Binding<UInt32> {
        Binding(get: { viewModel.draftColorHex }, set: { viewModel.updateDraftColorHex($0) })
    }

    private var createListTabBinding: Binding<NewListSheet.Tab> {
        Binding(
            get: {
                switch viewModel.createListTab {
                case .newList: return .newList
                case .templates: return .templates
                }
            },
            set: { tab in
                switch tab {
                case .newList: viewModel.updateCreateListTab(.newList)
                case .templates: viewModel.updateCreateListTab(.templates)
                }
            }
        )
    }

    // MARK: - Formatting

    private func currencyString(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode))
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
