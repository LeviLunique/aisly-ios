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
        static let archivedListsSectionTitle = AppTextKeys.Home.archivedListsSectionTitle.localizedResource
        static let listNameFieldTitle = AppTextKeys.Home.listNameFieldTitle.localizedResource
        static let listNamePlaceholder = AppTextKeys.Home.listNamePlaceholder.localizedResource
        static let createListSheetTitle = AppTextKeys.Home.createListSheetTitle.localizedResource
        static let renameListSheetTitle = AppTextKeys.Home.renameListSheetTitle.localizedResource
        static let createListConfirmButtonTitle = AppTextKeys.Home.createListConfirmButtonTitle.localizedResource
        static let renameListConfirmButtonTitle = AppTextKeys.Home.renameListConfirmButtonTitle.localizedResource
        static let renameListActionTitle = AppTextKeys.Home.renameListActionTitle.localizedResource
        static let archiveListActionTitle = AppTextKeys.Home.archiveListActionTitle.localizedResource
        static let failureTitle = AppTextKeys.Home.failureTitle.localizedResource
        static let failureDescription = AppTextKeys.Home.failureDescription.localizedResource
        static let retryButtonTitle = AppTextKeys.Home.retryButtonTitle.localizedResource
    }

    enum ListDetail {
        static let loadingTitle = AppTextKeys.ListDetail.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.ListDetail.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.ListDetail.emptyDescription.localizedResource
        static let createFirstItemButtonTitle = AppTextKeys.ListDetail.createFirstItemButtonTitle.localizedResource
        static let addItemToolbarTitle = AppTextKeys.ListDetail.addItemToolbarTitle.localizedResource
        static let budgetSummaryTitle = AppTextKeys.ListDetail.budgetSummaryTitle.localizedResource
        static let plannedTotalTitle = AppTextKeys.ListDetail.plannedTotalTitle.localizedResource
        static let actualTotalTitle = AppTextKeys.ListDetail.actualTotalTitle.localizedResource
        static let itemsSectionTitle = AppTextKeys.ListDetail.itemsSectionTitle.localizedResource
        static let itemNameFieldTitle = AppTextKeys.ListDetail.itemNameFieldTitle.localizedResource
        static let itemNamePlaceholder = AppTextKeys.ListDetail.itemNamePlaceholder.localizedResource
        static let quickEntrySectionTitle = AppTextKeys.ListDetail.quickEntrySectionTitle.localizedResource
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
    }
}
