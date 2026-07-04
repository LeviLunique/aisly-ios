import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastCenter: AislyToastCenter
    @StateObject private var viewModel: HistoryViewModel

    @State private var editMode: EditMode = .inactive

    // Multi-select mode (native EditMode → selection circles).
    @State private var selectedIDs: Set<UUID> = []
    @State private var pendingBulkDelete = false

    // Single-row delete confirmation.
    @State private var pendingDeleteID: UUID?

    // Purchase search (magnifier).
    @State private var isSearchActive = false
    @FocusState private var searchFocused: Bool

    // Custom more-menu (native Menu can't render the kit's teal highlight).
    @State private var isMoreMenuOpen = false

    init(viewModel: HistoryViewModel) {
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
            .alert(
                Text(verbatim: "Delete purchase history?"),
                isPresented: deleteConfirmationBinding
            ) {
                Button(role: .destructive) {
                    guard let pendingDeleteID else {
                        return
                    }

                    Task {
                        await viewModel.deleteHistory(id: pendingDeleteID)
                        self.pendingDeleteID = nil
                    }
                } label: {
                    Text(AppStrings.Common.deleteButtonTitle)
                }

                Button(role: .cancel) {
                    pendingDeleteID = nil
                } label: {
                    Text(AppStrings.Common.cancelButtonTitle)
                }
            } message: {
                Text(verbatim: "This will permanently remove this purchase record, including item values and totals. This action cannot be undone.")
            }
            .alert(
                Text(verbatim: "Delete \(selectedIDs.count) purchases from history?"),
                isPresented: $pendingBulkDelete
            ) {
                Button(role: .destructive) {
                    let ids = selectedIDs
                    Task {
                        await viewModel.deleteEntries(ids: ids)
                        exitSelection()
                    }
                } label: {
                    Text(AppStrings.Common.deleteButtonTitle)
                }

                Button(role: .cancel) {} label: {
                    Text(AppStrings.Common.cancelButtonTitle)
                }
            } message: {
                Text(verbatim: "This will permanently remove these purchase records, including item values and totals. This action cannot be undone.")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.Home.loadingTitle)

        case .loaded:
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    mainBody
                }

                if isSelecting {
                    selectionBar
                }

                if isMoreMenuOpen {
                    moreMenuOverlay
                }
            }

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AislyColor.error),
                title: AppStrings.Home.failureTitle,
                description: AppStrings.Home.failureDescription
            ) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text(AppStrings.Home.retryButtonTitle)
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var mainBody: some View {
        if viewModel.hasAnyEntry == false {
            AislyEmptyState(
                icon: Image(systemName: "clock"),
                title: AppStrings.ListsHub.historyPlaceholderTitle,
                description: AppStrings.ListsHub.historyPlaceholderDescription
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                titleView

                segmentedControl
                    .padding(.horizontal, AislySpacing.large)
                    .padding(.top, AislySpacing.medium)

                if viewModel.sections.isEmpty {
                    noResultsBody
                } else {
                    historyList
                }
            }
        }
    }

    private var titleView: some View {
        Text(verbatim: "History")
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
                    .accessibilityLabel(Text(verbatim: "Search purchases"))

                    Button {
                        withAnimation(AislyMotion.quick) { isMoreMenuOpen.toggle() }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(Text(verbatim: "History options"))
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
            segment(title: "All", filter: .all)
            segment(title: "This Month", filter: .thisMonth)
            segment(title: "3 Months", filter: .threeMonths)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func segment(title: String, filter: HistoryViewModel.Filter) -> some View {
        let isSelected = viewModel.filter == filter
        return Button {
            withAnimation(AislyMotion.quick) { viewModel.filter = filter }
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

    // MARK: - History list (one grouped card per month)

    private var historyList: some View {
        List(selection: $selectedIDs) {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        historyRow(row)
                    }
                } header: {
                    monthHeader(section.title)
                }
            }

            Section {
                helpText
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
                Color.clear.frame(height: isSelecting ? 80 : AislySpacing.large)
            }
        }
    }

    private func monthHeader(_ title: String) -> some View {
        Text(verbatim: title)
            .font(AislyTypography.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(AislyColor.textTertiary)
    }

    private var helpText: some View {
        Text(verbatim: "Tap a purchase to see its full snapshot.\nSwipe left for Repeat · Template · Delete.")
            .font(AislyTypography.small)
            .foregroundStyle(AislyColor.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AislySpacing.xSmall)
    }

    // MARK: - Rows

    @ViewBuilder
    private func historyRow(_ row: HistoryViewModel.HistoryRow) -> some View {
        Group {
            if isSelecting {
                // No NavigationLink in edit mode → no disclosure chevron, just
                // the native selection circle.
                rowContent(row)
            } else {
                NavigationLink(value: AppRoute.historyDetail(row.id)) {
                    rowContent(row)
                }
            }
        }
        .listRowBackground(AislyColor.surfacePrimary)
        .alignmentGuide(.listRowSeparatorLeading) { dimension in
            dimension[.leading] + 44
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isSelecting == false {
                Button(role: .destructive) {
                    pendingDeleteID = row.id
                } label: {
                    Label {
                        Text(verbatim: "Delete")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }

                Button {
                    Task {
                        if await viewModel.createTemplate(historyID: row.id) {
                            toastCenter.show("Template created")
                        }
                    }
                } label: {
                    Label {
                        Text(verbatim: "Template")
                    } icon: {
                        Image(systemName: "square.stack")
                    }
                }
                .tint(AislyColor.primary)

                Button {
                    Task {
                        if await viewModel.repeatList(historyID: row.id) {
                            toastCenter.show("List repeated")
                        }
                    }
                } label: {
                    Label {
                        Text(verbatim: "Repeat")
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .tint(AislyColor.success)
            }
        }
    }

    private func rowContent(_ row: HistoryViewModel.HistoryRow) -> some View {
        HStack(alignment: .center, spacing: AislySpacing.medium) {
            Image(systemName: "clock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AislyColor.textSecondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AislyColor.surfaceSecondary))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(AislyTypography.rowTitle)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)

                Text(verbatim: subtitle(for: row))
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: AislySpacing.xSmall) {
                Text(row.actualTotal, format: .currency(code: currencyCode))
                    .font(AislyTypography.rowTitle.weight(.semibold))
                    .foregroundStyle(AislyColor.textPrimary)

                budgetBadge(for: row.budgetDelta)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func budgetBadge(for delta: Decimal?) -> some View {
        if let delta {
            if delta >= .zero {
                AislyBadge(Text(verbatim: "\(currencyString(delta)) under"), tone: .success, size: .small)
            } else {
                AislyBadge(Text(verbatim: "\(currencyString(abs(delta))) over"), tone: .error, size: .small)
            }
        } else {
            AislyBadge(Text(verbatim: "No budget"), tone: .neutral, size: .small)
        }
    }

    private func subtitle(for row: HistoryViewModel.HistoryRow) -> String {
        let date = row.finishedAt.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(date) · \(row.purchasedItemCount) items purchased"
    }

    // MARK: - Search bar (docked above the keyboard, native TextField)

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $viewModel.searchQuery,
                    prompt: Text(verbatim: "Search purchases and items").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search purchases and items"))
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
        // Focus once the field is actually in the hierarchy so the keyboard
        // reliably rises (focusing before it renders is silently dropped).
        .onAppear { searchFocused = true }
    }

    // MARK: - Selection bar

    private var selectionBar: some View {
        HStack(spacing: AislySpacing.large) {
            Text(verbatim: selectedIDs.isEmpty ? "0 selected" : "\(selectedIDs.count) selected")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textSecondary)

            Spacer()

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
        Set(viewModel.filteredRows.map(\.id))
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

                    menuSectionHeader("BUDGET")

                    ForEach(HistoryViewModel.BudgetFilter.allCases) { option in
                        budgetMenuRow(option)
                    }

                    menuGroupSeparator

                    menuSectionHeader("SORT BY")

                    ForEach(HistoryViewModel.SortOption.allCases) { option in
                        sortMenuRow(option)
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

    private func budgetMenuRow(_ option: HistoryViewModel.BudgetFilter) -> some View {
        Button {
            closeMoreMenu()
            viewModel.budgetFilter = option
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .opacity(viewModel.budgetFilter == option ? 1 : 0)
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
        .accessibilityAddTraits(viewModel.budgetFilter == option ? .isSelected : [])
    }

    private func sortMenuRow(_ option: HistoryViewModel.SortOption) -> some View {
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

    // MARK: - Helpers

    private func currencyString(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDeleteID = nil
                }
            }
        )
    }
}
