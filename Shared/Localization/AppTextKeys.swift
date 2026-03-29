import Foundation

struct AppTextKey: Hashable {
    let value: String
}

enum AppTextKeys {
    enum Common {
        static let cancelButtonTitle = AppTextKey(value: "common.action.cancel")
    }

    enum Home {
        static let navigationTitle = AppTextKey(value: "home.screen.navigation.title")
        static let loadingTitle = AppTextKey(value: "home.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "home.empty.title")
        static let emptyDescription = AppTextKey(value: "home.empty.description")
        static let createFirstListButtonTitle = AppTextKey(value: "home.empty.createFirstList.action")
        static let createListToolbarTitle = AppTextKey(value: "home.toolbar.createList.action")
        static let localSummarySectionTitle = AppTextKey(value: "home.summary.section.title")
        static let activeListsSectionTitle = AppTextKey(value: "home.lists.active.section.title")
        static let archivedListsSectionTitle = AppTextKey(value: "home.lists.archived.section.title")
        static let listNameFieldTitle = AppTextKey(value: "home.editor.name.field.title")
        static let listNamePlaceholder = AppTextKey(value: "home.editor.name.field.placeholder")
        static let createListSheetTitle = AppTextKey(value: "home.editor.create.title")
        static let renameListSheetTitle = AppTextKey(value: "home.editor.rename.title")
        static let createListConfirmButtonTitle = AppTextKey(value: "home.editor.create.confirm.action")
        static let renameListConfirmButtonTitle = AppTextKey(value: "home.editor.rename.confirm.action")
        static let renameListActionTitle = AppTextKey(value: "home.list.rename.action")
        static let archiveListActionTitle = AppTextKey(value: "home.list.archive.action")
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
