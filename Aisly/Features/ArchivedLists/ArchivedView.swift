import SwiftUI

struct ArchivedView: View {
    @StateObject private var viewModel: ArchivedViewModel

    init(viewModel: ArchivedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(AislyColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text(verbatim: "Archived"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadIfNeeded()
            }
            .alert(
                Text(verbatim: "Delete list?"),
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
                Text(verbatim: "“\(name)” will be permanently removed. This cannot be undone.")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AislyLoadingState(message: AppStrings.ArchivedLists.screenLoadingTitle)

        case .loaded(let rows) where rows.isEmpty:
            AislyEmptyState(
                icon: Image(systemName: "archivebox"),
                title: AppStrings.ArchivedLists.emptyTitle,
                description: AppStrings.ArchivedLists.emptyDescription
            )

        case .loaded(let rows):
            List {
                Section {
                    Text(verbatim: "Archived lists keep items, values and state. Unarchive anytime.")
                        .font(AislyTypography.body)
                        .foregroundStyle(AislyColor.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(
                            top: AislySpacing.small,
                            leading: AislySpacing.medium,
                            bottom: AislySpacing.small,
                            trailing: AislySpacing.medium
                        ))
                }

                Section {
                    ForEach(rows) { row in
                        archivedRow(row)
                    }
                }

                Section {
                    Text(verbatim: "Swipe left for Unarchive · Delete. Deleting is permanent — purchase history is kept separately.")
                        .font(AislyTypography.small)
                        .foregroundStyle(AislyColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AislyColor.backgroundPrimary)

        case .failed:
            AislyEmptyState(
                icon: Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AislyColor.error),
                title: AppStrings.ArchivedLists.screenFailureTitle,
                description: AppStrings.ArchivedLists.screenFailureDescription
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

    private func archivedRow(_ row: ArchivedViewModel.ArchivedRow) -> some View {
        NavigationLink(value: AppRoute.listDetail(row.id)) {
            AislyGroupedRow(
                title: row.name,
                subtitle: Text(verbatim: subtitle(for: row))
            ) {
                AislyCategoryIcon(systemName: row.iconName, color: AislyColor.archive)
            } trailing: {
                AislyBadge(Text(verbatim: "Archived"), tone: .archive, size: .small)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.requestDeletion(id: row.id)
            } label: {
                Label {
                    Text(verbatim: "Delete")
                } icon: {
                    Image(systemName: "trash")
                }
            }

            Button {
                Task { await viewModel.unarchiveList(id: row.id) }
            } label: {
                Label {
                    Text(verbatim: "Unarchive")
                } icon: {
                    Image(systemName: "tray.and.arrow.up")
                }
            }
            .tint(AislyColor.success)
        }
    }

    private func subtitle(for row: ArchivedViewModel.ArchivedRow) -> String {
        let itemsText = row.itemCount == 1 ? "1 item" : "\(row.itemCount) items"
        let dateText = row.updatedAt.formatted(date: .abbreviated, time: .omitted)
        return "\(itemsText) · Archived \(dateText)"
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
