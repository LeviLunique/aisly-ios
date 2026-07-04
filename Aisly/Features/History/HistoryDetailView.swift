import SwiftUI

struct HistoryDetailView: View {
    @StateObject private var viewModel: HistoryDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastCenter: AislyToastCenter

    // Delete confirmation.
    @State private var isConfirmingDelete = false

    // Item search (magnifier).
    @State private var isSearchActive = false
    @FocusState private var searchFocused: Bool

    // Custom more-menu (native Menu can't render the kit's teal highlight).
    @State private var isMoreMenuOpen = false

    init(viewModel: HistoryDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .alert(
                Text(verbatim: "Delete purchase history?"),
                isPresented: $isConfirmingDelete
            ) {
                Button(role: .destructive) {
                    Task {
                        let didDelete = await viewModel.deleteHistory()
                        if didDelete {
                            dismiss()
                        }
                    }
                } label: {
                    Text(AppStrings.Common.deleteButtonTitle)
                }

                Button(role: .cancel) {
                    isConfirmingDelete = false
                } label: {
                    Text(AppStrings.Common.cancelButtonTitle)
                }
            } message: {
                Text(verbatim: "This will permanently remove this purchase record, including item values and totals. This action cannot be undone.")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.Home.loadingTitle)

        case .loaded(let entry):
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    snapshotList(entry)
                }

                if isMoreMenuOpen {
                    moreMenuOverlay
                }
            }

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

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        if isSearchActive {
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
                    .accessibilityLabel(Text(verbatim: "Search purchased items"))

                    Button {
                        withAnimation(AislyMotion.quick) { isMoreMenuOpen.toggle() }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(Text(verbatim: "Snapshot options"))
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

    // MARK: - Snapshot list

    private func snapshotList(_ entry: PurchaseHistoryEntry) -> some View {
        List {
            Section {
                header(for: entry)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                budgetCard(for: entry)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.filteredSections) { section in
                Section {
                    ForEach(section.items) { item in
                        itemCard(item)
                            .listRowInsets(rowInsets)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader(section)
                }
            }

            Section {
                helpText
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
                Color.clear.frame(height: AislySpacing.large)
            }
        }
    }

    // MARK: - Header (title + Snapshot badge + finished metadata)

    private func header(for entry: PurchaseHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            HStack(alignment: .center, spacing: AislySpacing.medium) {
                Text(entry.name)
                    .font(AislyTypography.pageTitle)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(2)

                AislyBadge(Text(verbatim: "Snapshot"), tone: .neutral)
            }

            Text(verbatim: metadata(for: entry))
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AislySpacing.xSmall)
    }

    // MARK: - Budget summary

    private func budgetCard(for entry: PurchaseHistoryEntry) -> some View {
        AislyBudgetSummaryCard(
            title: budgetTitle(for: entry),
            progressSummary: Text(verbatim: progressSummary(for: entry)),
            estimatedLabel: Text(verbatim: "Planned"),
            estimatedValue: currencyText(entry.plannedTotal),
            actualLabel: Text(verbatim: "Actual"),
            actualValue: currencyText(entry.actualTotal),
            deltaTone: deltaTone(for: entry.budgetDelta),
            deltaTitle: budgetDeltaTitle(for: entry.budgetDelta),
            deltaSubtitle: planDeltaSubtitle(for: entry.planDelta)
        )
    }

    // MARK: - Section header (icon + name + count)

    private func sectionHeader(_ section: PurchaseHistoryEntry.SectionSnapshot) -> some View {
        let appearance = viewModel.categoryAppearance(forSectionName: section.name)

        return HStack(spacing: AislySpacing.small) {
            AislyCategoryIcon(
                systemName: appearance.iconName,
                color: Color.aislyListHex(appearance.colorHex),
                size: .small
            )

            Text(verbatim: section.name)
                .font(AislyTypography.cardTitle)
                .foregroundStyle(AislyColor.textPrimary)
                .textCase(nil)

            Text(verbatim: "\(section.items.count)")
                .font(AislyTypography.caption)
                .foregroundStyle(AislyColor.textTertiary)

            Spacer()
        }
    }

    // MARK: - Item card (read-only snapshot row)

    private func itemCard(_ item: PurchaseHistoryEntry.ItemSnapshot) -> some View {
        HStack(alignment: .center, spacing: AislySpacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AislyTypography.rowTitle)
                    .foregroundStyle(AislyColor.textPrimary)
                    .lineLimit(1)

                Text(verbatim: "\(item.quantity) \((item.unit ?? .unit).rawValue)")
                    .font(AislyTypography.rowMetadata)
                    .foregroundStyle(AislyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                if let actual = item.actualTotal {
                    currencyText(actual)
                        .font(AislyTypography.caption.weight(.semibold))
                        .foregroundStyle(AislyColor.textPrimary)
                }

                if let planned = item.plannedTotal {
                    (Text(verbatim: "Planned ") + currencyText(planned))
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                }
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AislyColor.success)
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
    }

    private var helpText: some View {
        Text(verbatim: "This is an immutable snapshot — only items purchased at Finish Purchase, with the values saved at that moment.")
            .font(AislyTypography.small)
            .foregroundStyle(AislyColor.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AislySpacing.xSmall)
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
                    prompt: Text(verbatim: "Search purchased items").foregroundColor(AislyColor.textTertiary)
                ) { EmptyView() }
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AislyColor.textPrimary)
                    .font(AislyTypography.body)
                    .accessibilityLabel(Text(verbatim: "Search purchased items"))
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

    // MARK: - … menu (custom panel — native Menu can't tint items like the kit)

    private var moreMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Tap-outside catcher.
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { closeMoreMenu() }

            VStack(alignment: .leading, spacing: 0) {
                // The kit's emphasized action — teal text + icon.
                moreMenuRow(title: "Repeat List", systemName: "arrow.2.squarepath", tint: AislyColor.primary) {
                    Task {
                        if await viewModel.repeatList() {
                            toastCenter.show("List repeated")
                        }
                    }
                }

                moreMenuRow(title: "Create Template", systemName: "plus.square.on.square") {
                    Task {
                        if await viewModel.createTemplate() {
                            toastCenter.show("Template created")
                        }
                    }
                }

                menuGroupSeparator

                moreMenuRow(title: "Delete History", systemName: "trash", tint: AislyColor.error) {
                    isConfirmingDelete = true
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

    // MARK: - Formatting

    private func metadata(for entry: PurchaseHistoryEntry) -> String {
        let finished = entry.finishedAt.formatted(
            .dateTime.day().month(.abbreviated).year().hour().minute()
        )
        return "Finished \(finished) · \(entry.purchasedItemCount) items purchased"
    }

    private func budgetTitle(for entry: PurchaseHistoryEntry) -> Text {
        if let budget = entry.budget {
            return Text(verbatim: "Budget ") + currencyText(budget)
        }

        return Text(verbatim: "No budget")
    }

    private func progressSummary(for entry: PurchaseHistoryEntry) -> String {
        // Prefer the source list's total (recorded at finish time); legacy
        // snapshots without it fall back to a plain purchased count.
        if let total = entry.totalItemCount {
            return "\(entry.purchasedItemCount) of \(total) purchased"
        }
        return "\(entry.purchasedItemCount) purchased"
    }

    private func deltaTone(for delta: Decimal?) -> AislyBudgetSummaryCard.DeltaTone {
        guard let delta else {
            return .neutral
        }

        return delta >= .zero ? .underBudget : .overBudget
    }

    private func budgetDeltaTitle(for delta: Decimal?) -> Text {
        guard let delta else {
            return Text(verbatim: "Awaiting prices")
        }

        let magnitude = currencyText(abs(delta))
        if delta >= .zero {
            return magnitude + Text(verbatim: " under budget")
        }

        return magnitude + Text(verbatim: " over budget")
    }

    private func planDeltaSubtitle(for delta: Decimal?) -> Text {
        guard let delta else {
            return Text(verbatim: "Immutable snapshot")
        }

        let magnitude = currencyText(abs(delta))
        if delta >= .zero {
            return Text(verbatim: "Plan delta: ") + magnitude + Text(verbatim: " under planned")
        }

        return Text(verbatim: "Plan delta: ") + magnitude + Text(verbatim: " over planned")
    }

    private func currencyText(_ value: Decimal) -> Text {
        Text(value, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "USD"
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: AislySpacing.small,
            leading: AislySpacing.large,
            bottom: AislySpacing.small,
            trailing: AislySpacing.large
        )
    }
}
