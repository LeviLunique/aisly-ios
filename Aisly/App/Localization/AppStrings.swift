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
        static let optionalFieldValue = AppTextKeys.Common.optionalFieldValue.localizedResource
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

    enum ListDetail {
        static let loadingTitle = AppTextKeys.ListDetail.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ListDetail.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ListDetail.emptyDescription.localizedResource
        static let createFirstItemButtonTitle = AppTextKeys.ListDetail.createFirstItemButtonTitle.localizedResource
        static let addItemToolbarTitle = AppTextKeys.ListDetail.addItemToolbarTitle.localizedResource
        static let shoppingModeToolbarTitle = AppTextKeys.ListDetail.shoppingModeToolbarTitle.localizedResource
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
        static let plannedPriceFieldTitle = AppTextKeys.ListDetail.plannedPriceFieldTitle.localizedResource
        static let actualPriceFieldTitle = AppTextKeys.ListDetail.actualPriceFieldTitle.localizedResource
        static let addItemSheetTitle = AppTextKeys.ListDetail.addItemSheetTitle.localizedResource
        static let editItemSheetTitle = AppTextKeys.ListDetail.editItemSheetTitle.localizedResource
        static let addItemConfirmButtonTitle = AppTextKeys.ListDetail.addItemConfirmButtonTitle.localizedResource
        static let editItemConfirmButtonTitle = AppTextKeys.ListDetail.editItemConfirmButtonTitle.localizedResource
        static let failureTitle = AppTextKeys.ListDetail.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.ListDetail.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.ListDetail.retryButtonTitle.localizedResource

        static let awaitingActualPricesTitle = AppTextKeys.ListDetail.awaitingActualPricesTitle.localizedResource
        static let awaitingActualPricesDescription = AppTextKeys.ListDetail.awaitingActualPricesDescription.localizedResource

        static func budgetDeltaTitle(for delta: Decimal?) -> LocalizedStringResource {
            guard let delta else {
                return awaitingActualPricesTitle
            }

            if delta == .zero {
                return AppTextKeys.ListDetail.onBudgetTitle.localizedResource
            }

            return delta < .zero
                ? AppTextKeys.ListDetail.underBudgetTitle.localizedResource
                : AppTextKeys.ListDetail.overBudgetTitle.localizedResource
        }

        static func categoryTitle(for category: ShoppingItem.Category) -> LocalizedStringResource {
            categoryKey(for: category).localizedResource
        }

        private static func categoryKey(for category: ShoppingItem.Category) -> AppTextKey {
            switch category {
            case .produce:
                return AppTextKeys.ListDetail.Category.produce
            case .dairy:
                return AppTextKeys.ListDetail.Category.dairy
            case .protein:
                return AppTextKeys.ListDetail.Category.protein
            case .pantry:
                return AppTextKeys.ListDetail.Category.pantry
            case .household:
                return AppTextKeys.ListDetail.Category.household
            case .frozen:
                return AppTextKeys.ListDetail.Category.frozen
            case .other:
                return AppTextKeys.ListDetail.Category.other
            }
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
