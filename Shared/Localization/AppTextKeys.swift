import Foundation

struct AppTextKey: Hashable {
    let value: String
}

enum AppTextKeys {
    enum Common {
        static let cancelButtonTitle = AppTextKey(value: "common.action.cancel")
        static let deleteButtonTitle = AppTextKey(value: "common.action.delete")
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

    enum ListDetail {
        static let loadingTitle = AppTextKey(value: "listDetail.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "listDetail.empty.title")
        static let emptyDescription = AppTextKey(value: "listDetail.empty.description")
        static let createFirstItemButtonTitle = AppTextKey(value: "listDetail.empty.createFirstItem.action")
        static let addItemToolbarTitle = AppTextKey(value: "listDetail.toolbar.addItem.action")
        static let itemsSectionTitle = AppTextKey(value: "listDetail.items.section.title")
        static let itemNameFieldTitle = AppTextKey(value: "listDetail.editor.name.field.title")
        static let itemNamePlaceholder = AppTextKey(value: "listDetail.editor.name.field.placeholder")
        static let quantityFieldTitle = AppTextKey(value: "listDetail.editor.quantity.field.title")
        static let categoryFieldTitle = AppTextKey(value: "listDetail.editor.category.field.title")
        static let addItemSheetTitle = AppTextKey(value: "listDetail.editor.create.title")
        static let editItemSheetTitle = AppTextKey(value: "listDetail.editor.edit.title")
        static let addItemConfirmButtonTitle = AppTextKey(value: "listDetail.editor.create.confirm.action")
        static let editItemConfirmButtonTitle = AppTextKey(value: "listDetail.editor.edit.confirm.action")
        static let failureTitle = AppTextKey(value: "listDetail.error.title")
        static let failureDescription = AppTextKey(value: "listDetail.error.description")
        static let retryButtonTitle = AppTextKey(value: "listDetail.error.retry.action")

        enum Category {
            static let produce = AppTextKey(value: "listDetail.category.produce.label")
            static let dairy = AppTextKey(value: "listDetail.category.dairy.label")
            static let protein = AppTextKey(value: "listDetail.category.protein.label")
            static let pantry = AppTextKey(value: "listDetail.category.pantry.label")
            static let household = AppTextKey(value: "listDetail.category.household.label")
            static let frozen = AppTextKey(value: "listDetail.category.frozen.label")
            static let other = AppTextKey(value: "listDetail.category.other.label")
        }
    }

    enum Mock {
        enum ShoppingList {
            static let weeklyGroceriesName = AppTextKey(value: "mock.shoppingList.weeklyGroceries.name")
            static let partySuppliesName = AppTextKey(value: "mock.shoppingList.partySupplies.name")
        }

        enum ShoppingItem {
            static let milkName = AppTextKey(value: "mock.shoppingItem.milk.name")
            static let applesName = AppTextKey(value: "mock.shoppingItem.apples.name")
        }
    }
}
