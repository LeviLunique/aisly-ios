import XCTest

final class AislyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenUsesEnglishWhenAppLanguageIsEnglish() throws {
        let app = makeApp(language: "en", locale: "en_US")
        // The redesigned Home has no on-screen title (a floating search/menu pill
        // replaces it, per the design kit). Localization is verified through the
        // create-list button's localized accessibility label instead.
        let expectedCreateButton = try localizedString(
            forKey: AppTextKeys.Home.createListToolbarTitle,
            locale: "en"
        )

        app.launch()

        XCTAssertTrue(app.buttons[expectedCreateButton].waitForExistence(timeout: 5))
    }

    func testHomeScreenUsesBrazilianPortugueseWhenAppLanguageIsBrazilianPortuguese() throws {
        let app = makeApp(language: "pt-BR", locale: "pt_BR")
        // The redesigned Home has no on-screen title (a floating search/menu pill
        // replaces it, per the design kit). Localization is verified through the
        // create-list button's localized accessibility label instead.
        let expectedCreateButton = try localizedString(
            forKey: AppTextKeys.Home.createListToolbarTitle,
            locale: "pt-BR"
        )

        app.launch()

        XCTAssertTrue(app.buttons[expectedCreateButton].waitForExistence(timeout: 5))
    }

    private func makeApp(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        return app
    }

    private func localizedString(forKey key: AppTextKey, locale: String) throws -> String {
        let data = try Data(contentsOf: repositoryRootURL().appendingPathComponent("Aisly/Localizable.xcstrings"))
        let catalog = try JSONDecoder().decode(LocalizationCatalog.self, from: data)
        let entry = try XCTUnwrap(catalog.strings[key.value])
        let localization = try XCTUnwrap(entry.localizations[locale])
        let stringUnit = try XCTUnwrap(localization.stringUnit)

        return stringUnit.value
    }

    private func repositoryRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct LocalizationCatalog: Decodable {
    let strings: [String: LocalizationCatalogEntry]
}

private struct LocalizationCatalogEntry: Decodable {
    let localizations: [String: LocalizationCatalogLocalization]
}

private struct LocalizationCatalogLocalization: Decodable {
    let stringUnit: LocalizationCatalogStringUnit?
}

private struct LocalizationCatalogStringUnit: Decodable {
    let value: String
}
