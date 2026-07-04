import SwiftUI

struct AppContainer {
    let shoppingListRepository: any ShoppingListRepository
    let shoppingCategoryRepository: any ShoppingCategoryRepository
    let shoppingItemCatalogRepository: any ShoppingItemCatalogRepository
    let purchaseHistoryRepository: any PurchaseHistoryRepository

    init(
        shoppingListRepository: (any ShoppingListRepository)? = nil,
        shoppingCategoryRepository: (any ShoppingCategoryRepository)? = nil,
        shoppingItemCatalogRepository: (any ShoppingItemCatalogRepository)? = nil,
        purchaseHistoryRepository: (any PurchaseHistoryRepository)? = nil
    ) {
        self.shoppingListRepository = shoppingListRepository ?? LocalShoppingListRepository(
            store: ShoppingListFileStore(fileURL: AppStoragePaths.shoppingListsFileURL())
        )
        self.shoppingCategoryRepository = shoppingCategoryRepository ?? LocalShoppingCategoryRepository(
            store: ShoppingCategoryFileStore(fileURL: AppStoragePaths.shoppingCategoriesFileURL())
        )
        self.shoppingItemCatalogRepository = shoppingItemCatalogRepository ?? LocalShoppingItemCatalogRepository(
            store: ShoppingItemCatalogFileStore(fileURL: AppStoragePaths.shoppingItemCatalogFileURL())
        )
        self.purchaseHistoryRepository = purchaseHistoryRepository ?? LocalPurchaseHistoryRepository(
            store: PurchaseHistoryFileStore(fileURL: AppStoragePaths.purchaseHistoryFileURL())
        )
    }

    @MainActor
    func makeRootView() -> some View {
        HomeView(
            viewModel: HomeViewModel(repository: shoppingListRepository),
            makeDestination: { route in destination(for: route) }
        )
    }

    // MARK: - Central route resolver

    /// Builds the destination view for any pushed `AppRoute`. Registered once at
    /// the Home NavigationStack root, so every `NavigationLink(value:)` anywhere
    /// in the app resolves through here.
    @MainActor
    func destination(for route: AppRoute) -> AnyView {
        switch route {
        case .home:
            return AnyView(EmptyView())

        case .listDetail(let listID):
            return AnyView(ListDetailView(viewModel: makeListDetailViewModel(listID), mode: .list))

        case .templateDetail(let listID):
            return AnyView(ListDetailView(viewModel: makeListDetailViewModel(listID), mode: .template))

        case .categories:
            return AnyView(
                CategoriesView(
                    viewModel: CategoriesViewModel(
                        categoryRepository: shoppingCategoryRepository,
                        listRepository: shoppingListRepository
                    )
                )
            )

        case .templates:
            return AnyView(
                TemplatesView(viewModel: TemplatesViewModel(repository: shoppingListRepository))
            )

        case .itemDatabase:
            return AnyView(
                ItemDatabaseView(
                    viewModel: ItemDatabaseViewModel(
                        catalogRepository: shoppingItemCatalogRepository,
                        listRepository: shoppingListRepository,
                        categoryRepository: shoppingCategoryRepository
                    )
                )
            )

        case .history:
            return AnyView(
                HistoryView(
                    viewModel: HistoryViewModel(
                        historyRepository: purchaseHistoryRepository,
                        listRepository: shoppingListRepository
                    )
                )
            )

        case .historyDetail(let entryID):
            return AnyView(
                HistoryDetailView(
                    viewModel: HistoryDetailViewModel(
                        entryID: entryID,
                        historyRepository: purchaseHistoryRepository,
                        listRepository: shoppingListRepository,
                        categoryRepository: shoppingCategoryRepository
                    )
                )
            )

        case .archivedLists:
            return AnyView(
                ArchivedView(viewModel: ArchivedViewModel(repository: shoppingListRepository))
            )
        }
    }

    @MainActor
    private func makeListDetailViewModel(_ listID: UUID) -> ListDetailViewModel {
        ListDetailViewModel(
            listID: listID,
            repository: shoppingListRepository,
            categoryRepository: shoppingCategoryRepository,
            catalogRepository: shoppingItemCatalogRepository,
            historyRepository: purchaseHistoryRepository
        )
    }
}
