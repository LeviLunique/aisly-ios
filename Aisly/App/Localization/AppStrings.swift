import Foundation

private extension AppTextKey {
    var localizationValue: String.LocalizationValue {
        String.LocalizationValue(value)
    }

    var localizedResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: value)
    }

    var localizedString: String {
        String(localized: localizationValue, bundle: .main)
    }

    func localizedString(locale: Locale) -> String {
        String(localized: localizationValue, bundle: .main, locale: locale)
    }
}

enum AppStrings {
    enum Common {
        static let cancelButtonTitle = AppTextKeys.Common.cancelButtonTitle.localizedResource
        static let deleteButtonTitle = AppTextKeys.Common.deleteButtonTitle.localizedResource
        static let doneButtonTitle = AppTextKeys.Common.doneButtonTitle.localizedResource
        static let optionalFieldValue = AppTextKeys.Common.optionalFieldValue.localizedResource
    }

    enum Navigation {
        static let homeTabAccessibilityLabel = AppTextKeys.Navigation.homeTabAccessibilityLabel.localizedResource
        static let categoriesTabAccessibilityLabel = AppTextKeys.Navigation.categoriesTabAccessibilityLabel.localizedResource
        static let listTabAccessibilityLabel = AppTextKeys.Navigation.listTabAccessibilityLabel.localizedResource
        static let cartTabAccessibilityLabel = AppTextKeys.Navigation.cartTabAccessibilityLabel.localizedResource
        static let listTabEmptyTitle = AppTextKeys.Navigation.listTabEmptyTitle.localizedResource
        static let listTabEmptyDescription = AppTextKeys.Navigation.listTabEmptyDescription.localizedResource
        static let cartTabEmptyTitle = AppTextKeys.Navigation.cartTabEmptyTitle.localizedResource
        static let cartTabEmptyDescription = AppTextKeys.Navigation.cartTabEmptyDescription.localizedResource
    }

    enum Categories {
        static let navigationTitle = AppTextKeys.Categories.navigationTitle.localizedResource
        static let loadingTitle = AppTextKeys.Categories.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.Categories.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Categories.emptyDescription.localizedResource
        static let availableSectionTitle = AppTextKeys.Categories.availableSectionTitle.localizedResource
        static let addCategoryToolbarTitle = AppTextKeys.Categories.addCategoryToolbarTitle.localizedResource
        static let createCategorySheetTitle = AppTextKeys.Categories.createCategorySheetTitle.localizedResource
        static let editCategorySheetTitle = AppTextKeys.Categories.editCategorySheetTitle.localizedResource
        static let categoryNameFieldTitle = AppTextKeys.Categories.categoryNameFieldTitle.localizedResource
        static let categoryNameFieldPlaceholder = AppTextKeys.Categories.categoryNameFieldPlaceholder.localizedResource
        static let colorSectionTitle = AppTextKeys.Categories.colorSectionTitle.localizedResource
        static let iconSectionTitle = AppTextKeys.Categories.iconSectionTitle.localizedResource
        static let createCategoryConfirmButtonTitle = AppTextKeys.Categories.createCategoryConfirmButtonTitle.localizedResource
        static let editCategoryConfirmButtonTitle = AppTextKeys.Categories.editCategoryConfirmButtonTitle.localizedResource
        static let failureTitle = AppTextKeys.Categories.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.Categories.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.Categories.retryButtonTitle.localizedResource
        static let screenLoadingTitle = AppTextKeys.Categories.screenLoadingTitle.localizedResource
        static let screenFailureTitle = AppTextKeys.Categories.screenFailureTitle.localizedResource
        static let screenFailureDescription = AppTextKeys.Categories.screenFailureDescription.localizedResource
        static let deleteCategoryActionTitle = AppTextKeys.Categories.deleteCategoryActionTitle.localizedResource
        static let deleteCategoryConfirmationTitle = AppTextKeys.Categories.deleteCategoryConfirmationTitle.localizedResource
        static let deleteCategoryConfirmationMessage = AppTextKeys.Categories.deleteCategoryConfirmationMessage.localizedResource
    }

    enum ListsHub {
        static let navigationTitle = AppTextKeys.ListsHub.navigationTitle.localizedResource
        static let listsTabTitle = AppTextKeys.ListsHub.listsTabTitle.localizedResource
        static let templatesTabTitle = AppTextKeys.ListsHub.templatesTabTitle.localizedResource
        static let itemsTabTitle = AppTextKeys.ListsHub.itemsTabTitle.localizedResource
        static let historyTabTitle = AppTextKeys.ListsHub.historyTabTitle.localizedResource
        static let templatesPlaceholderTitle = AppTextKeys.ListsHub.templatesPlaceholderTitle.localizedResource
        static let templatesPlaceholderDescription = AppTextKeys.ListsHub.templatesPlaceholderDescription.localizedResource
        static let itemsPlaceholderTitle = AppTextKeys.ListsHub.itemsPlaceholderTitle.localizedResource
        static let itemsPlaceholderDescription = AppTextKeys.ListsHub.itemsPlaceholderDescription.localizedResource
        static let historyPlaceholderTitle = AppTextKeys.ListsHub.historyPlaceholderTitle.localizedResource
        static let historyPlaceholderDescription = AppTextKeys.ListsHub.historyPlaceholderDescription.localizedResource
    }

    enum Lists {
        static let activeSectionTitle = AppTextKeys.Lists.activeSectionTitle.localizedResource
        static let archivedSectionTitle = AppTextKeys.Lists.archivedSectionTitle.localizedResource
        static let emptyTitle = AppTextKeys.Lists.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Lists.emptyDescription.localizedResource
        static let createListToolbarTitle = AppTextKeys.Lists.createListToolbarTitle.localizedResource
        static let createListSheetTitle = AppTextKeys.Lists.createListSheetTitle.localizedResource
        static let createListConfirmButtonTitle = AppTextKeys.Lists.createListConfirmButtonTitle.localizedResource
        static let listNameFieldTitle = AppTextKeys.Lists.listNameFieldTitle.localizedResource
        static let listNameFieldPlaceholder = AppTextKeys.Lists.listNameFieldPlaceholder.localizedResource
        static let appearanceSectionTitle = AppTextKeys.Lists.appearanceSectionTitle.localizedResource
        static let iconSectionTitle = AppTextKeys.Lists.iconSectionTitle.localizedResource
        static let colorSectionTitle = AppTextKeys.Lists.colorSectionTitle.localizedResource
        static let templateSectionTitle = AppTextKeys.Lists.templateSectionTitle.localizedResource
        static let templateNoneOptionTitle = AppTextKeys.Lists.templateNoneOptionTitle.localizedResource
        static let templateSelectionHint = AppTextKeys.Lists.templateSelectionHint.localizedResource
        static let archiveActionTitle = AppTextKeys.Lists.archiveActionTitle.localizedResource
        static let unarchiveActionTitle = AppTextKeys.Lists.unarchiveActionTitle.localizedResource
        static let deleteActionTitle = AppTextKeys.Lists.deleteActionTitle.localizedResource
        static let deleteConfirmationTitle = AppTextKeys.Lists.deleteConfirmationTitle.localizedResource
        static let deleteConfirmationMessage = AppTextKeys.Lists.deleteConfirmationMessage.localizedResource
        static let deleteConfirmationFieldTitle = AppTextKeys.Lists.deleteConfirmationFieldTitle.localizedResource
        static let deleteConfirmationFieldPlaceholder = AppTextKeys.Lists.deleteConfirmationFieldPlaceholder.localizedResource
        static let archivedDetailNavigationTitle = AppTextKeys.Lists.archivedDetailNavigationTitle.localizedResource
        static let archivedDetailEmptyTitle = AppTextKeys.Lists.archivedDetailEmptyTitle.localizedResource
        static let archivedDetailEmptyDescription = AppTextKeys.Lists.archivedDetailEmptyDescription.localizedResource
        static let archivedDetailItemsSectionTitle = AppTextKeys.Lists.archivedDetailItemsSectionTitle.localizedResource
        static let archivedDetailUnarchiveButtonTitle = AppTextKeys.Lists.archivedDetailUnarchiveButtonTitle.localizedResource
    }

    enum Home {
        static let navigationTitle = AppTextKeys.Home.navigationTitle.localizedResource
        static let loadingTitle = AppTextKeys.Home.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.Home.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Home.emptyDescription.localizedResource
        static let createFirstListButtonTitle = AppTextKeys.Home.createFirstListButtonTitle.localizedResource
        static let createListToolbarTitle = AppTextKeys.Home.createListToolbarTitle.localizedResource
        static let activeListsSectionTitle = AppTextKeys.Home.activeListsSectionTitle.localizedResource
        static let templatesSectionTitle = AppTextKeys.Home.templatesSectionTitle.localizedResource
        static let archivedListsSectionTitle = AppTextKeys.Home.archivedListsSectionTitle.localizedResource
        static let listNameFieldTitle = AppTextKeys.Home.listNameFieldTitle.localizedResource
        static let listNamePlaceholder = AppTextKeys.Home.listNamePlaceholder.localizedResource
        static let createListSheetTitle = AppTextKeys.Home.createListSheetTitle.localizedResource
        static let renameListSheetTitle = AppTextKeys.Home.renameListSheetTitle.localizedResource
        static let createListConfirmButtonTitle = AppTextKeys.Home.createListConfirmButtonTitle.localizedResource
        static let renameListConfirmButtonTitle = AppTextKeys.Home.renameListConfirmButtonTitle.localizedResource
        static let renameListActionTitle = AppTextKeys.Home.renameListActionTitle.localizedResource
        static let archiveListActionTitle = AppTextKeys.Home.archiveListActionTitle.localizedResource
        static let saveTemplateActionTitle = AppTextKeys.Home.saveTemplateActionTitle.localizedResource
        static let generateTemplateActionTitle = AppTextKeys.Home.generateTemplateActionTitle.localizedResource
        static let templateNameFieldTitle = AppTextKeys.Home.templateNameFieldTitle.localizedResource
        static let templateNamePlaceholder = AppTextKeys.Home.templateNamePlaceholder.localizedResource
        static let templateRecurrenceFieldTitle = AppTextKeys.Home.templateRecurrenceFieldTitle.localizedResource
        static let saveTemplateSheetTitle = AppTextKeys.Home.saveTemplateSheetTitle.localizedResource
        static let saveTemplateConfirmButtonTitle = AppTextKeys.Home.saveTemplateConfirmButtonTitle.localizedResource
        static let failureTitle = AppTextKeys.Home.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.Home.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.Home.retryButtonTitle.localizedResource

        static func templateRecurrenceTitle(for recurrence: ShoppingList.TemplateRecurrence) -> LocalizedStringResource {
            switch recurrence {
            case .weekly:
                return AppTextKeys.Home.TemplateRecurrence.weekly.localizedResource
            case .biweekly:
                return AppTextKeys.Home.TemplateRecurrence.biweekly.localizedResource
            case .monthly:
                return AppTextKeys.Home.TemplateRecurrence.monthly.localizedResource
            }
        }
    }

    enum Items {
        static let emptyTitle = AppTextKeys.Items.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Items.emptyDescription.localizedResource
        static let createItemToolbarTitle = AppTextKeys.Items.createItemToolbarTitle.localizedResource
        static let createItemSheetTitle = AppTextKeys.Items.createItemSheetTitle.localizedResource
        static let editItemSheetTitle = AppTextKeys.Items.editItemSheetTitle.localizedResource
        static let createItemConfirmButtonTitle = AppTextKeys.Items.createItemConfirmButtonTitle.localizedResource
        static let editItemConfirmButtonTitle = AppTextKeys.Items.editItemConfirmButtonTitle.localizedResource
        static let itemNameFieldTitle = AppTextKeys.Items.itemNameFieldTitle.localizedResource
        static let itemNameFieldPlaceholder = AppTextKeys.Items.itemNameFieldPlaceholder.localizedResource
        static let storeFieldTitle = AppTextKeys.Items.storeFieldTitle.localizedResource
        static let storeFieldPlaceholder = AppTextKeys.Items.storeFieldPlaceholder.localizedResource
        static let categoryFieldTitle = AppTextKeys.Items.categoryFieldTitle.localizedResource
        static let plannedPriceFieldTitle = AppTextKeys.Items.plannedPriceFieldTitle.localizedResource
        static let actualPriceFieldTitle = AppTextKeys.Items.actualPriceFieldTitle.localizedResource
        static let searchPrompt = AppTextKeys.Items.searchPrompt.localizedResource
        static let filterToolbarTitle = AppTextKeys.Items.filterToolbarTitle.localizedResource
        static let sortToolbarTitle = AppTextKeys.Items.sortToolbarTitle.localizedResource
        static let categoryFilterSheetTitle = AppTextKeys.Items.categoryFilterSheetTitle.localizedResource
        static let categoryFilterAllAction = AppTextKeys.Items.categoryFilterAllAction.localizedResource
        static let categoryFilterNoneAction = AppTextKeys.Items.categoryFilterNoneAction.localizedResource
        static let categoryFilterAppliedSummary = AppTextKeys.Items.categoryFilterAppliedSummary.localizedResource
        static let categoryFilterAllSummary = AppTextKeys.Items.categoryFilterAllSummary.localizedResource
        static let deleteActionTitle = AppTextKeys.Items.deleteActionTitle.localizedResource
        static let deleteConfirmationTitle = AppTextKeys.Items.deleteConfirmationTitle.localizedResource
        static let deleteConfirmationMessage = AppTextKeys.Items.deleteConfirmationMessage.localizedResource
        static let noResultsTitle = AppTextKeys.Items.noResultsTitle.localizedResource
        static let noResultsDescription = AppTextKeys.Items.noResultsDescription.localizedResource

        static func sortTitle(for option: ItemsSortOption) -> LocalizedStringResource {
            switch option {
            case .nameAscending:
                return AppTextKeys.Items.Sort.nameAscending.localizedResource
            case .nameDescending:
                return AppTextKeys.Items.Sort.nameDescending.localizedResource
            case .createdAtAscending:
                return AppTextKeys.Items.Sort.createdAtAscending.localizedResource
            case .createdAtDescending:
                return AppTextKeys.Items.Sort.createdAtDescending.localizedResource
            case .plannedPriceHighest:
                return AppTextKeys.Items.Sort.plannedPriceHighest.localizedResource
            case .plannedPriceLowest:
                return AppTextKeys.Items.Sort.plannedPriceLowest.localizedResource
            case .actualPriceHighest:
                return AppTextKeys.Items.Sort.actualPriceHighest.localizedResource
            case .actualPriceLowest:
                return AppTextKeys.Items.Sort.actualPriceLowest.localizedResource
            }
        }
    }

    enum Templates {
        static let emptyTitle = AppTextKeys.Templates.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Templates.emptyDescription.localizedResource
        static let availableSectionTitle = AppTextKeys.Templates.availableSectionTitle.localizedResource
        static let createTemplateToolbarTitle = AppTextKeys.Templates.createTemplateToolbarTitle.localizedResource
        static let createTemplateSheetTitle = AppTextKeys.Templates.createTemplateSheetTitle.localizedResource
        static let createTemplateConfirmButtonTitle = AppTextKeys.Templates.createTemplateConfirmButtonTitle.localizedResource
        static let templateNameFieldTitle = AppTextKeys.Templates.templateNameFieldTitle.localizedResource
        static let templateNameFieldPlaceholder = AppTextKeys.Templates.templateNameFieldPlaceholder.localizedResource
        static let iconSectionTitle = AppTextKeys.Templates.iconSectionTitle.localizedResource
        static let colorSectionTitle = AppTextKeys.Templates.colorSectionTitle.localizedResource
        static let recurrenceSectionTitle = AppTextKeys.Templates.recurrenceSectionTitle.localizedResource
        static let deleteActionTitle = AppTextKeys.Templates.deleteActionTitle.localizedResource
        static let deleteConfirmationTitle = AppTextKeys.Templates.deleteConfirmationTitle.localizedResource
        static let deleteConfirmationMessage = AppTextKeys.Templates.deleteConfirmationMessage.localizedResource
        static let deleteConfirmationFieldTitle = AppTextKeys.Templates.deleteConfirmationFieldTitle.localizedResource
        static let deleteConfirmationFieldPlaceholder = AppTextKeys.Templates.deleteConfirmationFieldPlaceholder.localizedResource
        static let screenLoadingTitle = AppTextKeys.Templates.screenLoadingTitle.localizedResource
        static let screenFailureTitle = AppTextKeys.Templates.screenFailureTitle.localizedResource
        static let screenFailureDescription = AppTextKeys.Templates.screenFailureDescription.localizedResource
        static let activeEmptyTitle = AppTextKeys.Templates.activeEmptyTitle.localizedResource
        static let activeEmptyDescription = AppTextKeys.Templates.activeEmptyDescription.localizedResource
        static let archivedEmptyTitle = AppTextKeys.Templates.archivedEmptyTitle.localizedResource
        static let archivedEmptyDescription = AppTextKeys.Templates.archivedEmptyDescription.localizedResource
    }

    enum ItemDatabase {
        static let screenLoadingTitle = AppTextKeys.ItemDatabase.screenLoadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ItemDatabase.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ItemDatabase.emptyDescription.localizedResource
        static let noResultsTitle = AppTextKeys.ItemDatabase.noResultsTitle.localizedResource
        static let noResultsDescription = AppTextKeys.ItemDatabase.noResultsDescription.localizedResource
        static let screenFailureTitle = AppTextKeys.ItemDatabase.screenFailureTitle.localizedResource
        static let screenFailureDescription = AppTextKeys.ItemDatabase.screenFailureDescription.localizedResource
    }

    enum ArchivedLists {
        static let screenLoadingTitle = AppTextKeys.ArchivedLists.screenLoadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ArchivedLists.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ArchivedLists.emptyDescription.localizedResource
        static let screenFailureTitle = AppTextKeys.ArchivedLists.screenFailureTitle.localizedResource
        static let screenFailureDescription = AppTextKeys.ArchivedLists.screenFailureDescription.localizedResource
    }

    enum ListDetail {
        static let loadingTitle = AppTextKeys.ListDetail.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ListDetail.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ListDetail.emptyDescription.localizedResource
        static let createFirstItemButtonTitle = AppTextKeys.ListDetail.createFirstItemButtonTitle.localizedResource
        static let addItemToolbarTitle = AppTextKeys.ListDetail.addItemToolbarTitle.localizedResource
        static let shoppingModeToolbarTitle = AppTextKeys.ListDetail.shoppingModeToolbarTitle.localizedResource
        static let filterToolbarTitle = AppTextKeys.ListDetail.filterToolbarTitle.localizedResource
        static let sortToolbarTitle = AppTextKeys.ListDetail.sortToolbarTitle.localizedResource
        static let manageCategoriesToolbarTitle = AppTextKeys.ListDetail.manageCategoriesToolbarTitle.localizedResource
        static let budgetSummaryTitle = AppTextKeys.ListDetail.budgetSummaryTitle.localizedResource
        static let plannedTotalTitle = AppTextKeys.ListDetail.plannedTotalTitle.localizedResource
        static let actualTotalTitle = AppTextKeys.ListDetail.actualTotalTitle.localizedResource
        static let itemsSectionTitle = AppTextKeys.ListDetail.itemsSectionTitle.localizedResource
        static let itemNameFieldTitle = AppTextKeys.ListDetail.itemNameFieldTitle.localizedResource
        static let itemNamePlaceholder = AppTextKeys.ListDetail.itemNamePlaceholder.localizedResource
        static let storeFieldTitle = AppTextKeys.ListDetail.storeFieldTitle.localizedResource
        static let storeFieldPlaceholder = AppTextKeys.ListDetail.storeFieldPlaceholder.localizedResource
        static let quickEntrySectionTitle = AppTextKeys.ListDetail.quickEntrySectionTitle.localizedResource
        static let storeSuggestionsSectionTitle = AppTextKeys.ListDetail.storeSuggestionsSectionTitle.localizedResource
        static let priceMemorySectionTitle = AppTextKeys.ListDetail.priceMemorySectionTitle.localizedResource
        static let lastActualPriceMemoryTitle = AppTextKeys.ListDetail.PriceMemory.lastActualPriceTitle.localizedResource
        static let lastPlannedPriceMemoryTitle = AppTextKeys.ListDetail.PriceMemory.lastPlannedPriceTitle.localizedResource
        static let quantityFieldTitle = AppTextKeys.ListDetail.quantityFieldTitle.localizedResource
        static let categoryFieldTitle = AppTextKeys.ListDetail.categoryFieldTitle.localizedResource
        static let newCategoryFieldTitle = AppTextKeys.ListDetail.newCategoryFieldTitle.localizedResource
        static let newCategoryFieldPlaceholder = AppTextKeys.ListDetail.newCategoryFieldPlaceholder.localizedResource
        static let plannedPriceFieldTitle = AppTextKeys.ListDetail.plannedPriceFieldTitle.localizedResource
        static let actualPriceFieldTitle = AppTextKeys.ListDetail.actualPriceFieldTitle.localizedResource
        static let addItemSheetTitle = AppTextKeys.ListDetail.addItemSheetTitle.localizedResource
        static let editItemSheetTitle = AppTextKeys.ListDetail.editItemSheetTitle.localizedResource
        static let addItemConfirmButtonTitle = AppTextKeys.ListDetail.addItemConfirmButtonTitle.localizedResource
        static let editItemConfirmButtonTitle = AppTextKeys.ListDetail.editItemConfirmButtonTitle.localizedResource
        static let allCategoriesFilterTitle = AppTextKeys.ListDetail.allCategoriesFilterTitle.localizedResource
        static let categoryManagerSheetTitle = AppTextKeys.ListDetail.categoryManagerSheetTitle.localizedResource
        static let addCategorySectionTitle = AppTextKeys.ListDetail.addCategorySectionTitle.localizedResource
        static let existingCategoriesSectionTitle = AppTextKeys.ListDetail.existingCategoriesSectionTitle.localizedResource
        static let renameCategorySectionTitle = AppTextKeys.ListDetail.renameCategorySectionTitle.localizedResource
        static let categoryNameFieldTitle = AppTextKeys.ListDetail.categoryNameFieldTitle.localizedResource
        static let categoryNameFieldPlaceholder = AppTextKeys.ListDetail.categoryNameFieldPlaceholder.localizedResource
        static let addCategoryButtonTitle = AppTextKeys.ListDetail.addCategoryButtonTitle.localizedResource
        static let renameCategoryButtonTitle = AppTextKeys.ListDetail.renameCategoryButtonTitle.localizedResource
        static let failureTitle = AppTextKeys.ListDetail.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.ListDetail.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.ListDetail.retryButtonTitle.localizedResource
        static let sendToTemplateActionTitle = AppTextKeys.ListDetail.sendToTemplateActionTitle.localizedResource

        static let awaitingActualPricesTitle = AppTextKeys.ListDetail.awaitingActualPricesTitle.localizedResource
        static let awaitingActualPricesDescription = AppTextKeys.ListDetail.awaitingActualPricesDescription.localizedResource

        static func budgetDeltaTitle(for delta: Decimal?) -> LocalizedStringResource {
            guard let delta else {
                return awaitingActualPricesTitle
            }

            if delta == .zero {
                return AppTextKeys.ListDetail.onBudgetTitle.localizedResource
            }

            return delta > .zero
                ? AppTextKeys.ListDetail.underBudgetTitle.localizedResource
                : AppTextKeys.ListDetail.overBudgetTitle.localizedResource
        }

        static func categoryTitle(for category: ShoppingItem.Category) -> LocalizedStringResource {
            if let categoryKey = categoryKey(for: category) {
                return categoryKey.localizedResource
            }

            return LocalizedStringResource(stringLiteral: category.rawValue)
        }

        static func categoryName(
            for category: ShoppingItem.Category,
            locale: Locale = .autoupdatingCurrent
        ) -> String {
            if let categoryKey = categoryKey(for: category) {
                return categoryKey.localizedString(locale: locale)
            }

            return category.rawValue
        }

        static func sortTitle(for sortOption: ShoppingItem.SortOption) -> LocalizedStringResource {
            switch sortOption {
            case .category:
                return AppTextKeys.ListDetail.Sort.category.localizedResource
            case .name:
                return AppTextKeys.ListDetail.Sort.name.localizedResource
            case .plannedPrice:
                return AppTextKeys.ListDetail.Sort.plannedPrice.localizedResource
            case .actualPrice:
                return AppTextKeys.ListDetail.Sort.actualPrice.localizedResource
            }
        }

        private static func categoryKey(for category: ShoppingItem.Category) -> AppTextKey? {
            if category.matches(.produce) {
                return AppTextKeys.ListDetail.Category.produce
            }

            if category.matches(.dairy) {
                return AppTextKeys.ListDetail.Category.dairy
            }

            if category.matches(.protein) {
                return AppTextKeys.ListDetail.Category.protein
            }

            if category.matches(.pantry) {
                return AppTextKeys.ListDetail.Category.pantry
            }

            if category.matches(.household) {
                return AppTextKeys.ListDetail.Category.household
            }

            if category.matches(.frozen) {
                return AppTextKeys.ListDetail.Category.frozen
            }

            if category.matches(.other) {
                return AppTextKeys.ListDetail.Category.other
            }

            return nil
        }
    }

    enum ShoppingMode {
        static let navigationTitle = AppTextKeys.ShoppingMode.navigationTitle.localizedResource
        static let loadingTitle = AppTextKeys.ShoppingMode.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ShoppingMode.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ShoppingMode.emptyDescription.localizedResource
        static let progressTitle = AppTextKeys.ShoppingMode.progressTitle.localizedResource
        static let remainingItemsSectionTitle = AppTextKeys.ShoppingMode.remainingItemsSectionTitle.localizedResource
        static let completedItemsSectionTitle = AppTextKeys.ShoppingMode.completedItemsSectionTitle.localizedResource
        static let actualPriceSheetTitle = AppTextKeys.ShoppingMode.actualPriceSheetTitle.localizedResource
        static let actualPriceFieldTitle = AppTextKeys.ShoppingMode.actualPriceFieldTitle.localizedResource
        static let usePlannedPriceButtonTitle = AppTextKeys.ShoppingMode.usePlannedPriceButtonTitle.localizedResource
        static let saveActualPriceButtonTitle = AppTextKeys.ShoppingMode.saveActualPriceButtonTitle.localizedResource
        static let failureTitle = AppTextKeys.ShoppingMode.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.ShoppingMode.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.ShoppingMode.retryButtonTitle.localizedResource
    }

    enum AppleSurface {
        static let listEntityTypeTitle = AppTextKeys.AppleSurface.listEntityTypeTitle.localizedResource
        static let listParameterTitle = AppTextKeys.AppleSurface.listParameterTitle.localizedResource
        static let openListsIntentTitle = AppTextKeys.AppleSurface.openListsIntentTitle.localizedResource
        static let openListsIntentDescription = AppTextKeys.AppleSurface.openListsIntentDescription.localizedResource
        static let openShoppingModeIntentTitle = AppTextKeys.AppleSurface.openShoppingModeIntentTitle.localizedResource
        static let openShoppingModeIntentDescription = AppTextKeys.AppleSurface.openShoppingModeIntentDescription.localizedResource
        static let widgetConfigurationTitle = AppTextKeys.AppleSurface.widgetConfigurationTitle.localizedResource
        static let widgetConfigurationDescription = AppTextKeys.AppleSurface.widgetConfigurationDescription.localizedResource
        static let activeListWidgetTitle = AppTextKeys.AppleSurface.activeListWidgetTitle.localizedString
        static let activeListWidgetDescription = AppTextKeys.AppleSurface.activeListWidgetDescription.localizedString
        static let emptyWidgetTitle = AppTextKeys.AppleSurface.widgetEmptyTitle.localizedResource
        static let emptyWidgetDescription = AppTextKeys.AppleSurface.widgetEmptyDescription.localizedResource
    }

    enum Mock {
        enum ShoppingList {
            static func weeklyGroceriesName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingList.weeklyGroceriesName.localizedString(locale: locale)
            }

            static func partySuppliesName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingList.partySuppliesName.localizedString(locale: locale)
            }
        }

        enum ShoppingItem {
            static func milkName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingItem.milkName.localizedString(locale: locale)
            }

            static func applesName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingItem.applesName.localizedString(locale: locale)
            }
        }

        enum Store {
            static func freshMartName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.Store.freshMartName.localizedString(locale: locale)
            }

            static func cityMarketName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.Store.cityMarketName.localizedString(locale: locale)
            }
        }
    }
}
