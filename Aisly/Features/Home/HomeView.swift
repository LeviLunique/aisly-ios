import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(AppStrings.Home.navigationTitle))
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView {
                Text(AppStrings.Home.loadingTitle)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let snapshot) where snapshot.activeCount == 0:
            ContentUnavailableView {
                Label {
                    Text(AppStrings.Home.emptyTitle)
                } icon: {
                    Image(systemName: "cart")
                }
            } description: {
                Text(AppStrings.Home.emptyDescription)
            } actions: {
                if snapshot.archivedCount > 0 {
                    archivedListsCount(snapshot.archivedCount)
                }
            }

        case .loaded(let snapshot):
            List {
                Section {
                    localizedCountRow(
                        label: AppStrings.Home.activeListsLabel,
                        count: snapshot.activeCount
                    )
                    localizedCountRow(
                        label: AppStrings.Home.archivedListsLabel,
                        count: snapshot.archivedCount
                    )
                } header: {
                    Text(AppStrings.Home.localSummarySectionTitle)
                }

                Section {
                    Text(AppStrings.Home.repositoryBoundaryStatus)
                    Text(AppStrings.Home.localPersistenceStatus)
                } header: {
                    Text(AppStrings.Home.foundationStatusSectionTitle)
                }
            }
            .listStyle(.insetGrouped)

        case .failed:
            ContentUnavailableView {
                Label {
                    Text(AppStrings.Home.failureTitle)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } description: {
                Text(AppStrings.Home.failureDescription)
            } actions: {
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Text(AppStrings.Home.retryButtonTitle)
                }
            }
        }
    }

    private func archivedListsCount(_ count: Int) -> some View {
        localizedCountRow(label: AppStrings.Home.archivedListsLabel, count: count)
    }

    private func localizedCountRow(
        label: LocalizedStringResource,
        count: Int
    ) -> some View {
        LabeledContent {
            Text(count, format: .number)
        } label: {
            Text(label)
        }
    }
}

#Preview("Empty State") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])))
}

#Preview("Estado Vazio") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(lists: [])))
        .environment(\.locale, Locale(identifier: "pt_BR"))
}

#Preview("Loaded State") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
        lists: makePreviewShoppingLists(locale: Locale(identifier: "en"))
    )))
}

#Preview("Estado Carregado") {
    HomeView(viewModel: HomeViewModel(repository: PreviewShoppingListRepository(
        lists: makePreviewShoppingLists(locale: Locale(identifier: "pt_BR"))
    )))
    .environment(\.locale, Locale(identifier: "pt_BR"))
}

private func makePreviewShoppingLists(locale: Locale) -> [ShoppingList] {
    [
        ShoppingList(
            id: UUID(),
            name: AppStrings.Mock.ShoppingList.weeklyGroceriesName(locale: locale),
            createdAt: .now,
            updatedAt: .now,
            isArchived: false
        ),
        ShoppingList(
            id: UUID(),
            name: AppStrings.Mock.ShoppingList.partySuppliesName(locale: locale),
            createdAt: .now,
            updatedAt: .now,
            isArchived: true
        )
    ]
}

private struct PreviewShoppingListRepository: ShoppingListRepository {
    let lists: [ShoppingList]

    func fetchLists() async throws -> [ShoppingList] {
        lists
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}
