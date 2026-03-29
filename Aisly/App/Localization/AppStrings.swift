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

    enum Mock {
        enum ShoppingList {
            static func weeklyGroceriesName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingList.weeklyGroceriesName.localizedString(locale: locale)
            }

            static func partySuppliesName(locale: Locale = .autoupdatingCurrent) -> String {
                AppTextKeys.Mock.ShoppingList.partySuppliesName.localizedString(locale: locale)
            }
        }
    }
}
