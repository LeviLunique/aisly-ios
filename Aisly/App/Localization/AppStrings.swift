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
    enum Home {
        static let navigationTitle = AppTextKeys.Home.navigationTitle.localizedResource
        static let loadingTitle = AppTextKeys.Home.loadingTitle.localizedResource
        static let emptyTitle = AppTextKeys.Home.emptyTitle.localizedResource
        static let emptyDescription = AppTextKeys.Home.emptyDescription.localizedResource
        static let localSummarySectionTitle = AppTextKeys.Home.localSummarySectionTitle.localizedResource
        static let foundationStatusSectionTitle = AppTextKeys.Home.foundationStatusSectionTitle.localizedResource
        static let activeListsLabel = AppTextKeys.Home.activeListsLabel.localizedResource
        static let archivedListsLabel = AppTextKeys.Home.archivedListsLabel.localizedResource
        static let repositoryBoundaryStatus = AppTextKeys.Home.repositoryBoundaryStatus.localizedResource
        static let localPersistenceStatus = AppTextKeys.Home.localPersistenceStatus.localizedResource
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
