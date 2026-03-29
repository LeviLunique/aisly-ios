import SwiftUI

struct AppContainer {
    let shoppingListRepository: any ShoppingListRepository

    init(shoppingListRepository: (any ShoppingListRepository)? = nil) {
        self.shoppingListRepository = shoppingListRepository ?? LocalShoppingListRepository(
            store: ShoppingListFileStore(fileURL: AppStoragePaths.shoppingListsFileURL())
        )
    }

    @MainActor
    func makeHomeView() -> some View {
        HomeView(viewModel: HomeViewModel(repository: shoppingListRepository))
    }
}
