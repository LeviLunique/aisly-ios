import Foundation

struct AppTextKey: Hashable {
    let value: String
}

enum AppTextKeys {
    enum Common {
        static let cancelButtonTitle = AppTextKey(value: "common.action.cancel")
        static let deleteButtonTitle = AppTextKey(value: "common.action.delete")
        static let doneButtonTitle = AppTextKey(value: "common.action.done")
        static let optionalFieldValue = AppTextKey(value: "common.value.optional")
    }

    enum Navigation {
        static let homeTabAccessibilityLabel = AppTextKey(value: "navigation.tab.home.accessibility.label")
        static let categoriesTabAccessibilityLabel = AppTextKey(value: "navigation.tab.categories.accessibility.label")
        static let listTabAccessibilityLabel = AppTextKey(value: "navigation.tab.list.accessibility.label")
        static let cartTabAccessibilityLabel = AppTextKey(value: "navigation.tab.cart.accessibility.label")
        static let listTabEmptyTitle = AppTextKey(value: "navigation.list.empty.title")
        static let listTabEmptyDescription = AppTextKey(value: "navigation.list.empty.description")
        static let cartTabEmptyTitle = AppTextKey(value: "navigation.cart.empty.title")
        static let cartTabEmptyDescription = AppTextKey(value: "navigation.cart.empty.description")
    }

    enum Categories {
        static let navigationTitle = AppTextKey(value: "categories.screen.navigation.title")
        static let loadingTitle = AppTextKey(value: "categories.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "categories.empty.title")
        static let emptyDescription = AppTextKey(value: "categories.empty.description")
        static let availableSectionTitle = AppTextKey(value: "categories.available.section.title")
        static let addCategoryToolbarTitle = AppTextKey(value: "categories.toolbar.add.action")
        static let createCategorySheetTitle = AppTextKey(value: "categories.editor.create.title")
        static let editCategorySheetTitle = AppTextKey(value: "categories.editor.edit.title")
        static let categoryNameFieldTitle = AppTextKey(value: "categories.editor.name.field.title")
        static let categoryNameFieldPlaceholder = AppTextKey(value: "categories.editor.name.field.placeholder")
        static let colorSectionTitle = AppTextKey(value: "categories.editor.color.section.title")
        static let iconSectionTitle = AppTextKey(value: "categories.editor.icon.section.title")
        static let createCategoryConfirmButtonTitle = AppTextKey(value: "categories.editor.create.confirm.action")
        static let editCategoryConfirmButtonTitle = AppTextKey(value: "categories.editor.edit.confirm.action")
        static let failureTitle = AppTextKey(value: "categories.error.title")
        static let failureDescription = AppTextKey(value: "categories.error.description")
        static let retryButtonTitle = AppTextKey(value: "categories.error.retry.action")
        static let screenLoadingTitle = AppTextKey(value: "categories.screen.loading.state.title")
        static let screenFailureTitle = AppTextKey(value: "categories.screen.error.state.title")
        static let screenFailureDescription = AppTextKey(value: "categories.screen.error.state.description")
        static let deleteCategoryActionTitle = AppTextKey(value: "categories.delete.action")
        static let deleteCategoryConfirmationTitle = AppTextKey(value: "categories.delete.confirmation.title")
        static let deleteCategoryConfirmationMessage = AppTextKey(value: "categories.delete.confirmation.message")
    }

    enum ListsHub {
        static let navigationTitle = AppTextKey(value: "listsHub.screen.navigation.title")
        static let listsTabTitle = AppTextKey(value: "listsHub.tab.lists.title")
        static let templatesTabTitle = AppTextKey(value: "listsHub.tab.templates.title")
        static let itemsTabTitle = AppTextKey(value: "listsHub.tab.items.title")
        static let historyTabTitle = AppTextKey(value: "listsHub.tab.history.title")
        static let templatesPlaceholderTitle = AppTextKey(value: "listsHub.templates.placeholder.title")
        static let templatesPlaceholderDescription = AppTextKey(value: "listsHub.templates.placeholder.description")
        static let itemsPlaceholderTitle = AppTextKey(value: "listsHub.items.placeholder.title")
        static let itemsPlaceholderDescription = AppTextKey(value: "listsHub.items.placeholder.description")
        static let historyPlaceholderTitle = AppTextKey(value: "listsHub.history.placeholder.title")
        static let historyPlaceholderDescription = AppTextKey(value: "listsHub.history.placeholder.description")
    }

    enum Lists {
        static let activeSectionTitle = AppTextKey(value: "lists.section.active.title")
        static let archivedSectionTitle = AppTextKey(value: "lists.section.archived.title")
        static let emptyTitle = AppTextKey(value: "lists.empty.title")
        static let emptyDescription = AppTextKey(value: "lists.empty.description")
        static let createListToolbarTitle = AppTextKey(value: "lists.toolbar.createList.action")
        static let createListSheetTitle = AppTextKey(value: "lists.editor.create.title")
        static let createListConfirmButtonTitle = AppTextKey(value: "lists.editor.create.confirm.action")
        static let listNameFieldTitle = AppTextKey(value: "lists.editor.name.field.title")
        static let listNameFieldPlaceholder = AppTextKey(value: "lists.editor.name.field.placeholder")
        static let appearanceSectionTitle = AppTextKey(value: "lists.editor.appearance.section.title")
        static let iconSectionTitle = AppTextKey(value: "lists.editor.icon.section.title")
        static let colorSectionTitle = AppTextKey(value: "lists.editor.color.section.title")
        static let templateSectionTitle = AppTextKey(value: "lists.editor.template.section.title")
        static let templateNoneOptionTitle = AppTextKey(value: "lists.editor.template.none.title")
        static let templateSelectionHint = AppTextKey(value: "lists.editor.template.hint")
        static let archiveActionTitle = AppTextKey(value: "lists.list.archive.action")
        static let unarchiveActionTitle = AppTextKey(value: "lists.list.unarchive.action")
        static let deleteActionTitle = AppTextKey(value: "lists.list.delete.action")
        static let deleteConfirmationTitle = AppTextKey(value: "lists.delete.confirmation.title")
        static let deleteConfirmationMessage = AppTextKey(value: "lists.delete.confirmation.message")
        static let deleteConfirmationFieldTitle = AppTextKey(value: "lists.delete.confirmation.field.title")
        static let deleteConfirmationFieldPlaceholder = AppTextKey(value: "lists.delete.confirmation.field.placeholder")
        static let archivedDetailNavigationTitle = AppTextKey(value: "lists.archivedDetail.navigation.title")
        static let archivedDetailEmptyTitle = AppTextKey(value: "lists.archivedDetail.empty.title")
        static let archivedDetailEmptyDescription = AppTextKey(value: "lists.archivedDetail.empty.description")
        static let archivedDetailItemsSectionTitle = AppTextKey(value: "lists.archivedDetail.items.section.title")
        static let archivedDetailUnarchiveButtonTitle = AppTextKey(value: "lists.archivedDetail.unarchive.action")
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
        static let templatesSectionTitle = AppTextKey(value: "home.templates.section.title")
        static let archivedListsSectionTitle = AppTextKey(value: "home.lists.archived.section.title")
        static let listNameFieldTitle = AppTextKey(value: "home.editor.name.field.title")
        static let listNamePlaceholder = AppTextKey(value: "home.editor.name.field.placeholder")
        static let createListSheetTitle = AppTextKey(value: "home.editor.create.title")
        static let renameListSheetTitle = AppTextKey(value: "home.editor.rename.title")
        static let createListConfirmButtonTitle = AppTextKey(value: "home.editor.create.confirm.action")
        static let renameListConfirmButtonTitle = AppTextKey(value: "home.editor.rename.confirm.action")
        static let renameListActionTitle = AppTextKey(value: "home.list.rename.action")
        static let archiveListActionTitle = AppTextKey(value: "home.list.archive.action")
        static let saveTemplateActionTitle = AppTextKey(value: "home.list.saveTemplate.action")
        static let generateTemplateActionTitle = AppTextKey(value: "home.template.generate.action")
        static let templateNameFieldTitle = AppTextKey(value: "home.template.editor.name.field.title")
        static let templateNamePlaceholder = AppTextKey(value: "home.template.editor.name.field.placeholder")
        static let templateRecurrenceFieldTitle = AppTextKey(value: "home.template.editor.recurrence.field.title")
        static let saveTemplateSheetTitle = AppTextKey(value: "home.template.editor.title")
        static let saveTemplateConfirmButtonTitle = AppTextKey(value: "home.template.editor.confirm.action")
        static let repositoryBoundaryStatus = AppTextKey(value: "home.foundationStatus.repositoryBoundary.message")
        static let localPersistenceStatus = AppTextKey(value: "home.foundationStatus.localPersistence.message")
        static let failureTitle = AppTextKey(value: "home.error.title")
        static let failureDescription = AppTextKey(value: "home.error.description")
        static let retryButtonTitle = AppTextKey(value: "home.error.retry.action")

        enum TemplateRecurrence {
            static let weekly = AppTextKey(value: "home.template.recurrence.weekly.title")
            static let biweekly = AppTextKey(value: "home.template.recurrence.biweekly.title")
            static let monthly = AppTextKey(value: "home.template.recurrence.monthly.title")
        }
    }

    enum Items {
        static let emptyTitle = AppTextKey(value: "items.empty.title")
        static let emptyDescription = AppTextKey(value: "items.empty.description")
        static let createItemToolbarTitle = AppTextKey(value: "items.toolbar.createItem.action")
        static let createItemSheetTitle = AppTextKey(value: "items.editor.create.title")
        static let editItemSheetTitle = AppTextKey(value: "items.editor.edit.title")
        static let createItemConfirmButtonTitle = AppTextKey(value: "items.editor.create.confirm.action")
        static let editItemConfirmButtonTitle = AppTextKey(value: "items.editor.edit.confirm.action")
        static let itemNameFieldTitle = AppTextKey(value: "items.editor.name.field.title")
        static let itemNameFieldPlaceholder = AppTextKey(value: "items.editor.name.field.placeholder")
        static let storeFieldTitle = AppTextKey(value: "items.editor.store.field.title")
        static let storeFieldPlaceholder = AppTextKey(value: "items.editor.store.field.placeholder")
        static let categoryFieldTitle = AppTextKey(value: "items.editor.category.field.title")
        static let plannedPriceFieldTitle = AppTextKey(value: "items.editor.plannedPrice.field.title")
        static let actualPriceFieldTitle = AppTextKey(value: "items.editor.actualPrice.field.title")
        static let searchPrompt = AppTextKey(value: "items.search.prompt")
        static let filterToolbarTitle = AppTextKey(value: "items.toolbar.filter.action")
        static let sortToolbarTitle = AppTextKey(value: "items.toolbar.sort.action")
        static let categoryFilterSheetTitle = AppTextKey(value: "items.filter.sheet.title")
        static let categoryFilterAllAction = AppTextKey(value: "items.filter.selectAll.action")
        static let categoryFilterNoneAction = AppTextKey(value: "items.filter.clear.action")
        static let categoryFilterAppliedSummary = AppTextKey(value: "items.filter.applied.summary")
        static let categoryFilterAllSummary = AppTextKey(value: "items.filter.all.summary")
        static let deleteActionTitle = AppTextKey(value: "items.item.delete.action")
        static let deleteConfirmationTitle = AppTextKey(value: "items.delete.confirmation.title")
        static let deleteConfirmationMessage = AppTextKey(value: "items.delete.confirmation.message")
        static let noResultsTitle = AppTextKey(value: "items.noResults.title")
        static let noResultsDescription = AppTextKey(value: "items.noResults.description")

        enum Sort {
            static let nameAscending = AppTextKey(value: "items.sort.name.asc.title")
            static let nameDescending = AppTextKey(value: "items.sort.name.desc.title")
            static let createdAtAscending = AppTextKey(value: "items.sort.createdAt.asc.title")
            static let createdAtDescending = AppTextKey(value: "items.sort.createdAt.desc.title")
            static let plannedPriceHighest = AppTextKey(value: "items.sort.plannedPrice.desc.title")
            static let plannedPriceLowest = AppTextKey(value: "items.sort.plannedPrice.asc.title")
            static let actualPriceHighest = AppTextKey(value: "items.sort.actualPrice.desc.title")
            static let actualPriceLowest = AppTextKey(value: "items.sort.actualPrice.asc.title")
        }
    }

    enum Templates {
        static let emptyTitle = AppTextKey(value: "templates.empty.title")
        static let emptyDescription = AppTextKey(value: "templates.empty.description")
        static let availableSectionTitle = AppTextKey(value: "templates.section.available.title")
        static let createTemplateToolbarTitle = AppTextKey(value: "templates.toolbar.createTemplate.action")
        static let createTemplateSheetTitle = AppTextKey(value: "templates.editor.create.title")
        static let createTemplateConfirmButtonTitle = AppTextKey(value: "templates.editor.create.confirm.action")
        static let templateNameFieldTitle = AppTextKey(value: "templates.editor.name.field.title")
        static let templateNameFieldPlaceholder = AppTextKey(value: "templates.editor.name.field.placeholder")
        static let iconSectionTitle = AppTextKey(value: "templates.editor.icon.section.title")
        static let colorSectionTitle = AppTextKey(value: "templates.editor.color.section.title")
        static let recurrenceSectionTitle = AppTextKey(value: "templates.editor.recurrence.section.title")
        static let deleteActionTitle = AppTextKey(value: "templates.template.delete.action")
        static let deleteConfirmationTitle = AppTextKey(value: "templates.delete.confirmation.title")
        static let deleteConfirmationMessage = AppTextKey(value: "templates.delete.confirmation.message")
        static let deleteConfirmationFieldTitle = AppTextKey(value: "templates.delete.confirmation.field.title")
        static let deleteConfirmationFieldPlaceholder = AppTextKey(value: "templates.delete.confirmation.field.placeholder")
        static let screenLoadingTitle = AppTextKey(value: "templates.screen.loading.state.title")
        static let screenFailureTitle = AppTextKey(value: "templates.screen.error.state.title")
        static let screenFailureDescription = AppTextKey(value: "templates.screen.error.state.description")
        static let activeEmptyTitle = AppTextKey(value: "templates.screen.empty.active.title")
        static let activeEmptyDescription = AppTextKey(value: "templates.screen.empty.active.description")
        static let archivedEmptyTitle = AppTextKey(value: "templates.screen.empty.archived.title")
        static let archivedEmptyDescription = AppTextKey(value: "templates.screen.empty.archived.description")
    }

    enum ItemDatabase {
        static let screenLoadingTitle = AppTextKey(value: "itemDatabase.screen.loading.state.title")
        static let emptyTitle = AppTextKey(value: "itemDatabase.screen.empty.title")
        static let emptyDescription = AppTextKey(value: "itemDatabase.screen.empty.description")
        static let noResultsTitle = AppTextKey(value: "itemDatabase.screen.noResults.title")
        static let noResultsDescription = AppTextKey(value: "itemDatabase.screen.noResults.description")
        static let screenFailureTitle = AppTextKey(value: "itemDatabase.screen.error.state.title")
        static let screenFailureDescription = AppTextKey(value: "itemDatabase.screen.error.state.description")
    }

    enum ArchivedLists {
        static let screenLoadingTitle = AppTextKey(value: "archivedLists.screen.loading.state.title")
        static let emptyTitle = AppTextKey(value: "archivedLists.screen.empty.title")
        static let emptyDescription = AppTextKey(value: "archivedLists.screen.empty.description")
        static let screenFailureTitle = AppTextKey(value: "archivedLists.screen.error.state.title")
        static let screenFailureDescription = AppTextKey(value: "archivedLists.screen.error.state.description")
    }

    enum ListDetail {
        static let loadingTitle = AppTextKey(value: "listDetail.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "listDetail.empty.title")
        static let emptyDescription = AppTextKey(value: "listDetail.empty.description")
        static let createFirstItemButtonTitle = AppTextKey(value: "listDetail.empty.createFirstItem.action")
        static let addItemToolbarTitle = AppTextKey(value: "listDetail.toolbar.addItem.action")
        static let shoppingModeToolbarTitle = AppTextKey(value: "listDetail.toolbar.shoppingMode.action")
        static let filterToolbarTitle = AppTextKey(value: "listDetail.toolbar.filter.action")
        static let sortToolbarTitle = AppTextKey(value: "listDetail.toolbar.sort.action")
        static let manageCategoriesToolbarTitle = AppTextKey(value: "listDetail.toolbar.manageCategories.action")
        static let budgetSummaryTitle = AppTextKey(value: "listDetail.budget.summary.title")
        static let plannedTotalTitle = AppTextKey(value: "listDetail.budget.plannedTotal.title")
        static let actualTotalTitle = AppTextKey(value: "listDetail.budget.actualTotal.title")
        static let awaitingActualPricesTitle = AppTextKey(value: "listDetail.budget.awaitingActualPrices.title")
        static let awaitingActualPricesDescription = AppTextKey(value: "listDetail.budget.awaitingActualPrices.description")
        static let underBudgetTitle = AppTextKey(value: "listDetail.budget.underBudget.title")
        static let overBudgetTitle = AppTextKey(value: "listDetail.budget.overBudget.title")
        static let onBudgetTitle = AppTextKey(value: "listDetail.budget.onBudget.title")
        static let itemsSectionTitle = AppTextKey(value: "listDetail.items.section.title")
        static let itemNameFieldTitle = AppTextKey(value: "listDetail.editor.name.field.title")
        static let itemNamePlaceholder = AppTextKey(value: "listDetail.editor.name.field.placeholder")
        static let storeFieldTitle = AppTextKey(value: "listDetail.editor.store.field.title")
        static let storeFieldPlaceholder = AppTextKey(value: "listDetail.editor.store.field.placeholder")
        static let quickEntrySectionTitle = AppTextKey(value: "listDetail.editor.quickEntry.section.title")
        static let storeSuggestionsSectionTitle = AppTextKey(value: "listDetail.editor.storeSuggestions.section.title")
        static let priceMemorySectionTitle = AppTextKey(value: "listDetail.editor.priceMemory.section.title")
        static let quantityFieldTitle = AppTextKey(value: "listDetail.editor.quantity.field.title")
        static let categoryFieldTitle = AppTextKey(value: "listDetail.editor.category.field.title")
        static let newCategoryFieldTitle = AppTextKey(value: "listDetail.editor.newCategory.field.title")
        static let newCategoryFieldPlaceholder = AppTextKey(value: "listDetail.editor.newCategory.field.placeholder")
        static let plannedPriceFieldTitle = AppTextKey(value: "listDetail.editor.plannedPrice.field.title")
        static let actualPriceFieldTitle = AppTextKey(value: "listDetail.editor.actualPrice.field.title")
        static let addItemSheetTitle = AppTextKey(value: "listDetail.editor.create.title")
        static let editItemSheetTitle = AppTextKey(value: "listDetail.editor.edit.title")
        static let addItemConfirmButtonTitle = AppTextKey(value: "listDetail.editor.create.confirm.action")
        static let editItemConfirmButtonTitle = AppTextKey(value: "listDetail.editor.edit.confirm.action")
        static let allCategoriesFilterTitle = AppTextKey(value: "listDetail.filter.allCategories.title")
        static let categoryManagerSheetTitle = AppTextKey(value: "listDetail.categoryManager.title")
        static let addCategorySectionTitle = AppTextKey(value: "listDetail.categoryManager.add.section.title")
        static let existingCategoriesSectionTitle = AppTextKey(value: "listDetail.categoryManager.existing.section.title")
        static let renameCategorySectionTitle = AppTextKey(value: "listDetail.categoryManager.rename.section.title")
        static let categoryNameFieldTitle = AppTextKey(value: "listDetail.categoryManager.name.field.title")
        static let categoryNameFieldPlaceholder = AppTextKey(value: "listDetail.categoryManager.name.field.placeholder")
        static let addCategoryButtonTitle = AppTextKey(value: "listDetail.categoryManager.add.action")
        static let renameCategoryButtonTitle = AppTextKey(value: "listDetail.categoryManager.rename.action")
        static let failureTitle = AppTextKey(value: "listDetail.error.title")
        static let failureDescription = AppTextKey(value: "listDetail.error.description")
        static let retryButtonTitle = AppTextKey(value: "listDetail.error.retry.action")
        static let sendToTemplateActionTitle = AppTextKey(value: "listDetail.item.sendToTemplate.action")

        enum Sort {
            static let category = AppTextKey(value: "listDetail.sort.category.title")
            static let name = AppTextKey(value: "listDetail.sort.name.title")
            static let plannedPrice = AppTextKey(value: "listDetail.sort.plannedPrice.title")
            static let actualPrice = AppTextKey(value: "listDetail.sort.actualPrice.title")
        }

        enum Category {
            static let produce = AppTextKey(value: "listDetail.category.produce.label")
            static let dairy = AppTextKey(value: "listDetail.category.dairy.label")
            static let protein = AppTextKey(value: "listDetail.category.protein.label")
            static let pantry = AppTextKey(value: "listDetail.category.pantry.label")
            static let household = AppTextKey(value: "listDetail.category.household.label")
            static let frozen = AppTextKey(value: "listDetail.category.frozen.label")
            static let other = AppTextKey(value: "listDetail.category.other.label")
        }

        enum PriceMemory {
            static let lastActualPriceTitle = AppTextKey(value: "listDetail.priceMemory.lastActual.title")
            static let lastPlannedPriceTitle = AppTextKey(value: "listDetail.priceMemory.lastPlanned.title")
        }
    }

    enum ShoppingMode {
        static let navigationTitle = AppTextKey(value: "shoppingMode.screen.navigation.title")
        static let loadingTitle = AppTextKey(value: "shoppingMode.screen.loading.title")
        static let emptyTitle = AppTextKey(value: "shoppingMode.empty.title")
        static let emptyDescription = AppTextKey(value: "shoppingMode.empty.description")
        static let progressTitle = AppTextKey(value: "shoppingMode.progress.title")
        static let remainingItemsSectionTitle = AppTextKey(value: "shoppingMode.items.remaining.section.title")
        static let completedItemsSectionTitle = AppTextKey(value: "shoppingMode.items.completed.section.title")
        static let actualPriceSheetTitle = AppTextKey(value: "shoppingMode.priceEditor.title")
        static let actualPriceFieldTitle = AppTextKey(value: "shoppingMode.priceEditor.actualPrice.field.title")
        static let usePlannedPriceButtonTitle = AppTextKey(value: "shoppingMode.priceEditor.usePlannedPrice.action")
        static let saveActualPriceButtonTitle = AppTextKey(value: "shoppingMode.priceEditor.save.action")
        static let failureTitle = AppTextKey(value: "shoppingMode.error.title")
        static let failureDescription = AppTextKey(value: "shoppingMode.error.description")
        static let retryButtonTitle = AppTextKey(value: "shoppingMode.error.retry.action")
    }

    enum AppleSurface {
        static let listEntityTypeTitle = AppTextKey(value: "appleSurface.listEntity.type.title")
        static let listParameterTitle = AppTextKey(value: "appleSurface.list.parameter.title")
        static let openListsIntentTitle = AppTextKey(value: "appleSurface.intent.openLists.title")
        static let openListsIntentDescription = AppTextKey(value: "appleSurface.intent.openLists.description")
        static let openShoppingModeIntentTitle = AppTextKey(value: "appleSurface.intent.openShoppingMode.title")
        static let openShoppingModeIntentDescription = AppTextKey(value: "appleSurface.intent.openShoppingMode.description")
        static let widgetConfigurationTitle = AppTextKey(value: "appleSurface.widget.configuration.title")
        static let widgetConfigurationDescription = AppTextKey(value: "appleSurface.widget.configuration.description")
        static let activeListWidgetTitle = AppTextKey(value: "appleSurface.widget.activeList.title")
        static let activeListWidgetDescription = AppTextKey(value: "appleSurface.widget.activeList.description")
        static let widgetEmptyTitle = AppTextKey(value: "appleSurface.widget.empty.title")
        static let widgetEmptyDescription = AppTextKey(value: "appleSurface.widget.empty.description")
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

        enum Store {
            static let freshMartName = AppTextKey(value: "mock.store.freshMart.name")
            static let cityMarketName = AppTextKey(value: "mock.store.cityMarket.name")
        }
    }
}
