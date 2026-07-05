import SwiftUI

struct TemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TemplatesViewModel

    @State private var isMoreMenuOpen = false
    @State private var isSearchActive = false
    @State private var searchQuery = ""
    @State private var isSelecting = false
    @State private var isBulkDeletePresented = false
    @FocusState private var searchFocused: Bool

    init(viewModel: TemplatesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(isPresented: createTemplateBinding) {
                createTemplateSheet
                    .presentationDetents([.height(500), .large])
                    .presentationDragIndicator(.hidden)
            }
            .alert(
                Text(verbatim: "Delete template?"),
                isPresented: deletionAlertBinding,
                presenting: viewModel.pendingDeletionName
            ) { _ in
                Button(role: .destructive) {
                    Task { await viewModel.confirmDeletion() }
                } label: {
                    Text(verbatim: "Delete")
                }

                Button(role: .cancel) {
                    viewModel.cancelDeletion()
                } label: {
                    Text(verbatim: "Cancel")
                }
            } message: { name in
                Text(verbatim: "\"\(name)\" will be permanently removed. This cannot be undone.")
            }
            .alert(
                Text(verbatim: "Delete \(viewModel.selectedTemplateIDs.count) templates?"),
                isPresented: $isBulkDeletePresented
            ) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteSelectedTemplates()
                        exitSelection()
                    }
                } label: {
                    Text(verbatim: "Delete")
                }

                Button(role: .cancel) {} label: {
                    Text(verbatim: "Cancel")
                }
            } message: {
                Text(verbatim: "This removes the selected templates permanently.")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.Templates.screenLoadingTitle)

        case .loaded:
            loadedContent

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AislyColor.error),
                title: AppStrings.Templates.screenFailureTitle,
                description: AppStrings.Templates.screenFailureDescription
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

    private var loadedContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if isSelecting {
                    selectionTopBar
                } else if isSearchActive == false {
                    topBar
                }

                templatesBody
            }

            if isMoreMenuOpen {
                moreMenuOverlay
            }

            if isSelecting {
                selectionBar
                    .frame(maxWidth: .infinity, alignment: .bottom)
            } else if isSearchActive == false && viewModel.canCreateTemplate {
                createTemplateButton
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
                .accessibilityLabel(Text(verbatim: "Search templates"))

                Button {
                    withAnimation(AislyMotion.quick) { isMoreMenuOpen.toggle() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isMoreMenuOpen ? Color.dynamicBlue : Color.clear, lineWidth: 2)
                        )
                }
                .accessibilityLabel(Text(verbatim: "Template options"))
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

    private var selectionTopBar: some View {
        HStack {
            Button {
                if viewModel.selectedTemplateIDs.count == filteredRows.count {
                    viewModel.clearSelection()
                } else {
                    viewModel.select(ids: Set(filteredRows.map(\.id)))
                }
            } label: {
                Text(verbatim: viewModel.selectedTemplateIDs.count == filteredRows.count && filteredRows.isEmpty == false ? "Deselect All" : "Select All")
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
            .accessibilityLabel(Text(verbatim: "Done selecting templates"))
        }
        .padding(.horizontal, AislySpacing.large)
        .padding(.vertical, AislySpacing.small)
    }

    private var templatesBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AislySpacing.medium) {
                header
                scopeSegmentedControl

                if filteredRows.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: AislySpacing.small) {
                        ForEach(filteredRows) { row in
                            templateRow(row)
                        }
                    }

                    Text(verbatim: "Templates also appear in the New List sheet. Swipe left to manage.")
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AislySpacing.xxLarge)
                        .padding(.top, AislySpacing.small)
                }
            }
            .padding(.horizontal, AislySpacing.large)
            .padding(.top, isSearchActive ? 82 : AislySpacing.small)
            .padding(.bottom, isSelecting ? 104 : 96)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AislySpacing.xSmall) {
            Text(verbatim: "Templates")
                .font(AislyTypography.pageTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(verbatim: "Pre-made lists ready to reuse. Tap one to open it like a list.")
                .font(AislyTypography.small)
                .foregroundStyle(AislyColor.textSecondary)
        }
    }

    private var scopeSegmentedControl: some View {
        HStack(spacing: 0) {
            scopeButton("Active", scope: .active)
            scopeButton("Archived", scope: .archived)
        }
        .padding(2)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func scopeButton(_ title: String, scope: TemplatesViewModel.Scope) -> some View {
        Button {
            withAnimation(AislyMotion.quick) { viewModel.updateScope(scope) }
        } label: {
            Text(verbatim: title)
                .font(AislyTypography.small.weight(.semibold))
                .foregroundStyle(viewModel.scope == scope ? AislyColor.textPrimary : AislyColor.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AislyCornerRadius.small, style: .continuous)
                        .fill(viewModel.scope == scope ? AislyColor.surfaceTertiary : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyState: some View {
        AislyEmptyState(
            icon: Image(systemName: ["doc", "on", "doc"].joined(separator: ".")),
            title: viewModel.scope == .active
                ? AppStrings.Templates.activeEmptyTitle
                : AppStrings.Templates.archivedEmptyTitle,
            description: viewModel.scope == .active
                ? AppStrings.Templates.activeEmptyDescription
                : AppStrings.Templates.archivedEmptyDescription
        )
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(.top, AislySpacing.xxxLarge)
    }

    @ViewBuilder
    private func templateRow(_ row: TemplatesViewModel.TemplateRow) -> some View {
        if isSelecting {
            Button {
                viewModel.toggleSelection(id: row.id)
            } label: {
                templateRowContent(row)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: AppRoute.templateDetail(row.id)) {
                templateRowContent(row)
            }
            .buttonStyle(.plain)
            .contextMenu {
                if row.isArchived {
                    Button {
                        Task { await viewModel.unarchiveTemplate(id: row.id) }
                    } label: {
                        Label {
                            Text(verbatim: "Unarchive Template")
                        } icon: {
                            Image(systemName: "tray.and.arrow.up")
                        }
                    }
                } else {
                    Button {
                        Task { await viewModel.archiveTemplate(id: row.id) }
                    } label: {
                        Label {
                            Text(verbatim: "Archive Template")
                        } icon: {
                            Image(systemName: "archivebox")
                        }
                    }
                }

                Button(role: .destructive) {
                    viewModel.requestDeletion(id: row.id)
                } label: {
                    Label {
                        Text(verbatim: "Delete Template")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    private func templateRowContent(_ row: TemplatesViewModel.TemplateRow) -> some View {
        HStack(spacing: AislySpacing.medium) {
            if isSelecting {
                selectionCircle(isSelected: viewModel.selectedTemplateIDs.contains(row.id))
            }

            AislyCategoryIcon(
                systemName: row.iconName,
                color: row.isArchived ? AislyColor.archive : Color.templatesHex(row.colorHex)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: row.name)
                    .font(AislyTypography.listHeader)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)

                Text(verbatim: subtitle(for: row))
                    .font(AislyTypography.small)
                    .foregroundStyle(AislyColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AislySpacing.small)

            AislyBadge(
                Text(verbatim: row.isArchived ? "Archived" : "Template"),
                tone: row.isArchived ? .archive : .primary,
                size: .small
            )

            if isSelecting == false {
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

    private func selectionCircle(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
            } else {
                Image(systemName: "circle")
            }
        }
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(isSelected ? AislyColor.primary : AislyColor.textTertiary)
    }

    private var createTemplateButton: some View {
        Button {
            viewModel.presentCreateTemplate()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AislyColor.primaryForeground)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AislyColor.primary))
                .aislyShadow(AislyShadow.fab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "New Template"))
        .padding(AislySpacing.xLarge)
    }

    private var moreMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { closeMoreMenu() }

            VStack(alignment: .leading, spacing: 0) {
                moreMenuRow(title: "Select Templates", systemName: "checkmark.circle") {
                    enterSelection()
                }

                menuGroupSeparator

                Text(verbatim: "SORT BY")
                    .font(AislyTypography.small.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(AislyColor.textTertiary)
                    .padding(.horizontal, AislySpacing.large)
                    .padding(.top, AislySpacing.medium)
                    .padding(.bottom, AislySpacing.xSmall)

                ForEach(TemplatesViewModel.SortOption.allCases) { option in
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

    private func sortMenuRow(_ option: TemplatesViewModel.SortOption) -> some View {
        Button {
            closeMoreMenu()
            viewModel.updateSortOption(option)
        } label: {
            HStack(spacing: AislySpacing.medium) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AislyColor.primary)
                    .opacity(viewModel.sortOption == option ? 1 : 0)
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
        .accessibilityAddTraits(viewModel.sortOption == option ? .isSelected : [])
    }

    private var searchBar: some View {
        HStack(spacing: AislySpacing.medium) {
            HStack(spacing: AislySpacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AislyColor.textSecondary)

                TextField(
                    text: $searchQuery,
                    prompt: Text(verbatim: "Search templates").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search templates"))
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

    private var selectionBar: some View {
        HStack(spacing: AislySpacing.large) {
            Text(verbatim: viewModel.selectedTemplateIDs.isEmpty ? "0 selected" : "\(viewModel.selectedTemplateIDs.count) selected")
                .font(AislyTypography.body.weight(.medium))
                .foregroundStyle(AislyColor.textSecondary)

            Spacer()

            circleAction(
                systemImage: viewModel.scope == .active
                    ? "archivebox"
                    : ["tray", "and", "arrow", "up"].joined(separator: "."),
                fill: AislyColor.archive,
                label: viewModel.scope == .active ? "Archive selected templates" : "Unarchive selected templates",
                enabled: viewModel.selectedTemplateIDs.isEmpty == false
            ) {
                Task {
                    if viewModel.scope == .active {
                        await viewModel.archiveSelectedTemplates()
                    } else {
                        await viewModel.unarchiveSelectedTemplates()
                    }
                    exitSelection()
                }
            }

            circleAction(
                systemImage: "trash",
                fill: AislyColor.error,
                label: "Delete selected templates",
                enabled: viewModel.selectedTemplateIDs.isEmpty == false
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

    private var createTemplateSheet: some View {
        AislySheetContainer(
            title: Text(verbatim: "New Template"),
            trailing: {
                HStack(spacing: AislySpacing.medium) {
                    editorCircleButton(systemImage: "xmark", tone: AislyColor.textSecondary, label: "Close") {
                        viewModel.dismissCreateTemplate()
                    }

                    editorCircleButton(
                        systemImage: "checkmark",
                        tone: viewModel.isDraftSubmissionDisabled ? AislyColor.textTertiary : AislyColor.primary,
                        label: "Create template",
                        enabled: viewModel.isDraftSubmissionDisabled == false
                    ) {
                        Task { await viewModel.saveTemplateDraft() }
                    }
                }
            },
            content: {
                VStack(spacing: AislySpacing.large) {
                    AislyCategoryIcon(
                        systemName: viewModel.draftIconName,
                        color: Color.templatesHex(viewModel.draftColorHex),
                        size: .hero
                    )
                    .padding(.top, AislySpacing.small)

                    TextField(
                        text: draftNameBinding,
                        prompt: Text(verbatim: "List Name").foregroundColor(AislyColor.textTertiary)
                    ) {
                        Text(verbatim: "List Name")
                    }
                    .font(AislyTypography.screenTitle)
                    .foregroundStyle(AislyColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .padding(.horizontal, AislySpacing.large)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                            .fill(AislyColor.surfaceSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                            .stroke(AislyColor.borderHeavy, lineWidth: 1)
                    )

                    colorPickerGrid
                    iconPickerGrid
                }
            }
        )
    }

    private var colorPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AislySpacing.medium), count: 6),
            spacing: AislySpacing.medium
        ) {
            ForEach(viewModel.availableColorHexes, id: \.self) { hex in
                Button {
                    viewModel.updateDraftColorHex(hex)
                } label: {
                    Circle()
                        .fill(Color.templatesHex(hex))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(AislyColor.textPrimary, lineWidth: viewModel.draftColorHex == hex ? 2 : 0)
                                .padding(-3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private var iconPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AislySpacing.small), count: 6),
            spacing: AislySpacing.small
        ) {
            ForEach(viewModel.availableIconNames, id: \.self) { symbol in
                Button {
                    viewModel.updateDraftIconName(symbol)
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.draftIconName == symbol ? AislyColor.primaryForeground : AislyColor.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(viewModel.draftIconName == symbol ? Color.templatesHex(viewModel.draftColorHex) : AislyColor.surfaceTertiary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
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

    private var filteredRows: [TemplatesViewModel.TemplateRow] {
        let rows = viewModel.rows(for: viewModel.scope)
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else {
            return rows
        }

        return rows.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func subtitle(for row: TemplatesViewModel.TemplateRow) -> String {
        let itemsText = row.itemCount == 1 ? "1 item" : "\(row.itemCount) items"
        let plannedText = row.plannedTotal.formatted(
            .currency(code: Locale.autoupdatingCurrent.currency?.identifier ?? "USD")
        )
        return "\(itemsText) · Default planned \(plannedText)"
    }

    private func enterSelection() {
        isSelecting = true
        viewModel.clearSelection()
    }

    private func exitSelection() {
        isSelecting = false
        viewModel.clearSelection()
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

    private var draftNameBinding: Binding<String> {
        Binding(get: { viewModel.draftName }, set: { viewModel.updateDraftName($0) })
    }

    private var createTemplateBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isCreateTemplatePresented },
            set: { isPresented in
                if isPresented {
                    viewModel.presentCreateTemplate()
                } else {
                    viewModel.dismissCreateTemplate()
                }
            }
        )
    }

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeletionID != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.cancelDeletion()
                }
            }
        )
    }
}

private extension Color {
    static let dynamicBlue = Color(uiColor: UIColor.systemBlue)
}

extension Color {
    static func templatesHex(_ hex: UInt32) -> Color {
        Color(
            uiColor: UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        )
    }
}
