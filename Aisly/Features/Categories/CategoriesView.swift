import SwiftUI

struct CategoriesView: View {
    private enum SortOption: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case name = "Name"
        case itemCount = "Item count"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CategoriesViewModel
    @State private var isSearchActive = false
    @State private var searchText = ""
    @State private var isMoreMenuOpen = false
    @State private var isSelecting = false
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var sortOption: SortOption = .manual
    @State private var isBulkDeletePresented = false
    @FocusState private var searchFocused: Bool

    init(viewModel: CategoriesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: editorModeBinding) { _ in
                CategoryEditSheet(viewModel: viewModel)
            }
            .alert(item: pendingDeletionBinding) { pendingDeletion in
                deleteAlert(for: pendingDeletion)
            }
            .alert(
                Text(verbatim: "Delete \(selectedCategoryIDs.count) categories?"),
                isPresented: $isBulkDeletePresented
            ) {
                Button(role: .destructive) {
                    let ids = selectedCategoryIDs
                    Task {
                        await viewModel.deleteCategories(ids: ids)
                        exitSelection()
                    }
                } label: {
                    Text(verbatim: "Delete")
                }

                Button(role: .cancel) {} label: {
                    Text(verbatim: "Cancel")
                }
            } message: {
                Text(verbatim: "Items in these categories will move to Others.")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.Categories.screenLoadingTitle)

        case .loaded(let snapshot):
            loadedContent(snapshot)

        case .failed:
            AislyEmptyState(
                icon:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(AislyColor.error),
                title: AppStrings.Categories.screenFailureTitle,
                description: AppStrings.Categories.screenFailureDescription
            ) {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(verbatim: "Try Again")
                }
                .buttonStyle(AislyPrimaryButtonStyle())
            }
        }
    }

    private func loadedContent(_ snapshot: CategoriesViewModel.CategorySnapshot) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if isSelecting {
                    selectionTopBar(categories: displayedCategories(snapshot.categories))
                } else if isSearchActive == false {
                    topBar
                }

                categoriesBody(snapshot)
            }

            if isMoreMenuOpen {
                moreMenuOverlay
            }

            if isSelecting {
                selectionBar
                    .frame(maxWidth: .infinity, alignment: .bottom)
            } else if isSearchActive == false {
                floatingAddButton
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSearchActive {
                searchBar
            }
        }
    }

    private var topBar: some View {
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
                    withAnimation(AislyMotion.quick) {
                        isMoreMenuOpen = false
                        isSearchActive = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel(Text(verbatim: "Search categories"))

                Button {
                    withAnimation(AislyMotion.quick) { isMoreMenuOpen.toggle() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isMoreMenuOpen ? Color(uiColor: UIColor.systemBlue) : Color.clear, lineWidth: 2)
                        )
                }
                .accessibilityLabel(Text(verbatim: "Category options"))
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

    private func selectionTopBar(categories: [CategoriesViewModel.CategoryRow]) -> some View {
        HStack {
            Button {
                if selectedCategoryIDs.count == categories.count {
                    selectedCategoryIDs = []
                } else {
                    selectedCategoryIDs = Set(categories.map(\.id))
                }
            } label: {
                Text(verbatim: selectedCategoryIDs.count == categories.count && categories.isEmpty == false ? "Deselect All" : "Select All")
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
            .accessibilityLabel(Text(verbatim: "Done selecting categories"))
        }
        .padding(.horizontal, AislySpacing.large)
        .padding(.vertical, AislySpacing.small)
    }

    private func categoriesBody(_ snapshot: CategoriesViewModel.CategorySnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AislySpacing.medium) {
                header

                sectionTitle("YOUR CATEGORIES")

                let categories = displayedCategories(snapshot.categories)
                if categories.isEmpty {
                    emptySearchState
                } else {
                    VStack(spacing: AislySpacing.small) {
                        ForEach(categories) { category in
                            categoryRow(category)
                        }
                    }
                }

                sectionTitle("FALLBACK")
                    .padding(.top, AislySpacing.xSmall)

                fallbackCard
            }
            .padding(.horizontal, AislySpacing.large)
            .padding(.top, isSearchActive ? 82 : AislySpacing.small)
            .padding(.bottom, isSelecting ? 104 : 96)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AislySpacing.xSmall) {
            Text(verbatim: "Categories")
                .font(AislyTypography.pageTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(verbatim: "Items are grouped by category in every list. Lists only control display order and collapsing.")
                .font(AislyTypography.small)
                .foregroundStyle(AislyColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(verbatim: title)
            .font(AislyTypography.small.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(AislyColor.textSecondary)
    }

    private var emptySearchState: some View {
        Text(verbatim: "No categories found")
            .font(AislyTypography.caption)
            .foregroundStyle(AislyColor.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AislySpacing.xxxLarge)
    }

    @ViewBuilder
    private func categoryRow(_ category: CategoriesViewModel.CategoryRow) -> some View {
        if isSelecting {
            HStack(spacing: AislySpacing.small) {
                Button {
                    toggleSelection(category.id)
                } label: {
                    selectionCircle(isSelected: selectedCategoryIDs.contains(category.id))
                }
                .buttonStyle(.plain)

                categoryCard(category, showsChevron: false, showsHandle: true)
                    .draggable(category.id)
                    .dropDestination(for: String.self) { payloads, _ in
                        handleCategoryDrop(payloads, targetID: category.id)
                    }
            }
        } else {
            Button {
                viewModel.presentEditCategory(id: category.id)
            } label: {
                categoryCard(category, showsChevron: true, showsHandle: false)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    viewModel.presentEditCategory(id: category.id)
                } label: {
                    Label {
                        Text(verbatim: "Edit Category")
                    } icon: {
                        Image(systemName: "info.circle")
                    }
                }

                Button(role: .destructive) {
                    viewModel.presentDeleteConfirmation(id: category.id)
                } label: {
                    Label {
                        Text(verbatim: "Delete Category")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    private func categoryCard(
        _ category: CategoriesViewModel.CategoryRow,
        showsChevron: Bool,
        showsHandle: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: AislySpacing.medium) {
            AislyCategoryIcon(
                systemName: category.iconName,
                color: Color.categoryHex(category.colorHex)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: category.name)
                    .font(AislyTypography.listHeader)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)

                Text(verbatim: itemCountText(category.itemCount))
                    .font(AislyTypography.small)
                    .foregroundStyle(AislyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.textTertiary)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AislyColor.textQuaternary)
            }
        }
        .padding(.horizontal, AislySpacing.medium)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .stroke(AislyColor.borderSubtle, lineWidth: 1)
        )
    }

    private var fallbackCard: some View {
        HStack(alignment: .center, spacing: AislySpacing.medium) {
            AislyCategoryIcon(
                systemName: "ellipsis",
                color: AislyColor.archive
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: "Others")
                    .font(AislyTypography.listHeader)
                    .foregroundStyle(AislyColor.textPrimary)

                Text(verbatim: "Unclassified items land here")
                    .font(AislyTypography.small)
                    .foregroundStyle(AislyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AislyBadge(Text(verbatim: "Fixed"), tone: .neutral, size: .small)
        }
        .padding(.horizontal, AislySpacing.medium)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .stroke(AislyColor.borderSubtle, lineWidth: 1)
        )
    }

    private func selectionCircle(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
            } else {
                Image(systemName: "circle")
            }
        }
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(isSelected ? AislyColor.primary : AislyColor.borderHeavy)
        .frame(width: 30, height: 60)
    }

    private var floatingAddButton: some View {
        Button {
            viewModel.presentCreateCategory()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AislyColor.primaryForeground)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AislyColor.primary))
                .aislyShadow(AislyShadow.fab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "New Category"))
        .padding(AislySpacing.xLarge)
    }

    private var moreMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { closeMoreMenu() }

            VStack(alignment: .leading, spacing: 0) {
                moreMenuRow(title: "Select Categories", systemName: "checkmark.circle") {
                    enterSelection()
                }

                moreMenuRow(title: "New Category", systemName: "plus.circle") {
                    viewModel.presentCreateCategory()
                }

                menuGroupSeparator

                Text(verbatim: "SORT BY")
                    .font(AislyTypography.small.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(AislyColor.textTertiary)
                    .padding(.horizontal, AislySpacing.large)
                    .padding(.top, AislySpacing.medium)
                    .padding(.bottom, AislySpacing.xSmall)

                ForEach(SortOption.allCases) { option in
                    sortMenuRow(option)
                }
            }
            .padding(.vertical, AislySpacing.small)
            .frame(width: 218)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .fill(AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
            .aislyShadow(AislyShadow.toast)
            .padding(.trailing, AislySpacing.large)
            .padding(.top, 56)
            .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(verbatim: title)
                    .font(AislyTypography.caption)
                    .foregroundStyle(tint)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sortMenuRow(_ option: SortOption) -> some View {
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
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textPrimary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(sortOption == option ? .isSelected : [])
    }

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $searchText,
                    prompt: Text(verbatim: "Search categories").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search categories"))
            }
            .padding(.horizontal, AislySpacing.medium)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )

            Button {
                searchFocused = false
                withAnimation(AislyMotion.quick) {
                    isSearchActive = false
                    searchText = ""
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

    private var selectionBar: some View {
        HStack(spacing: AislySpacing.large) {
            Text(verbatim: selectedCategoryIDs.isEmpty ? "0 selected" : "\(selectedCategoryIDs.count) selected")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textSecondary)

            Spacer()

            circleAction(
                systemImage: "trash",
                fill: AislyColor.error,
                label: "Delete selected categories",
                enabled: selectedCategoryIDs.isEmpty == false
            ) {
                isBulkDeletePresented = true
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

    private func deleteAlert(for pendingDeletion: CategoriesViewModel.PendingDeletion) -> Alert {
        Alert(
            title: Text(verbatim: "Delete \(pendingDeletion.name)?"),
            message: Text(verbatim: "Items in this category will move to Others."),
            primaryButton: .destructive(Text(verbatim: "Delete")) {
                Task {
                    await viewModel.confirmDeletePendingCategory()
                }
            },
            secondaryButton: .cancel(Text(verbatim: "Cancel")) {
                viewModel.dismissDeleteConfirmation()
            }
        )
    }

    private func displayedCategories(
        _ categories: [CategoriesViewModel.CategoryRow]
    ) -> [CategoriesViewModel.CategoryRow] {
        var result = categories
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty == false {
            result = result.filter { category in
                category.name.localizedCaseInsensitiveContains(query)
            }
        }

        switch sortOption {
        case .manual:
            return result
        case .name:
            return result.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .itemCount:
            return result.sorted {
                if $0.itemCount == $1.itemCount {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.itemCount > $1.itemCount
            }
        }
    }

    private func itemCountText(_ count: Int) -> String {
        count == 1 ? "1 item" : "\(count) items"
    }

    private func toggleSelection(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }

    private func handleCategoryDrop(_ payloads: [String], targetID: String) -> Bool {
        guard let movedID = payloads.first else {
            return false
        }

        viewModel.moveCategory(id: movedID, aheadOf: targetID)
        return true
    }

    private func enterSelection() {
        isSelecting = true
        selectedCategoryIDs = []
    }

    private func exitSelection() {
        isSelecting = false
        selectedCategoryIDs = []
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

    private var editorModeBinding: Binding<CategoriesViewModel.EditorMode?> {
        Binding(
            get: { viewModel.editorMode },
            set: { updatedValue in
                if updatedValue == nil {
                    viewModel.dismissEditor()
                }
            }
        )
    }

    private var pendingDeletionBinding: Binding<CategoriesViewModel.PendingDeletion?> {
        Binding(
            get: { viewModel.pendingDeletion },
            set: { updatedValue in
                if updatedValue == nil {
                    viewModel.dismissDeleteConfirmation()
                }
            }
        )
    }
}

extension Color {
    static func categoryHex(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
