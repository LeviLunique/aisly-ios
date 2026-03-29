import Foundation

struct AppTextKey: Hashable {
    let value: String
}

enum AppTextKeys {
    enum Home {
        static let navigationTitle = AppTextKey(value: "home.screen.navigation.title")
        static let loadingTitle = AppTextKey(value: "home.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "home.empty.title")
        static let emptyDescription = AppTextKey(value: "home.empty.description")
        static let localSummarySectionTitle = AppTextKey(value: "home.summary.section.title")
        static let foundationStatusSectionTitle = AppTextKey(value: "home.foundationStatus.section.title")
        static let activeListsLabel = AppTextKey(value: "home.summary.activeLists.label")
        static let archivedListsLabel = AppTextKey(value: "home.summary.archivedLists.label")
        static let repositoryBoundaryStatus = AppTextKey(value: "home.foundationStatus.repositoryBoundary.message")
        static let localPersistenceStatus = AppTextKey(value: "home.foundationStatus.localPersistence.message")
        static let failureTitle = AppTextKey(value: "home.error.title")
        static let failureDescription = AppTextKey(value: "home.error.description")
        static let retryButtonTitle = AppTextKey(value: "home.error.retry.action")
    }

    enum Mock {
        enum ShoppingList {
            static let weeklyGroceriesName = AppTextKey(value: "mock.shoppingList.weeklyGroceries.name")
            static let partySuppliesName = AppTextKey(value: "mock.shoppingList.partySupplies.name")
        }
    }
}
