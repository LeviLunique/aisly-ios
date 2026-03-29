import XCTest

final class AislyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenUsesEnglishWhenAppLanguageIsEnglish() throws {
        let app = makeApp(language: "en", locale: "en_US")
        let expectedTitle = try localizedString(
            forKey: AppTextKeys.Home.navigationTitle,
            locale: "en"
        )
        let expectedCreateButton = try localizedString(
            forKey: AppTextKeys.Home.createFirstListButtonTitle,
            locale: "en"
        )

        app.launch()

        XCTAssertTrue(app.staticTexts[expectedTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[expectedCreateButton].waitForExistence(timeout: 5))
    }

    func testHomeScreenUsesBrazilianPortugueseWhenAppLanguageIsBrazilianPortuguese() throws {
        let app = makeApp(language: "pt-BR", locale: "pt_BR")
        let expectedTitle = try localizedString(
            forKey: AppTextKeys.Home.navigationTitle,
            locale: "pt-BR"
        )
        let expectedCreateButton = try localizedString(
            forKey: AppTextKeys.Home.createFirstListButtonTitle,
            locale: "pt-BR"
        )

        app.launch()

        XCTAssertTrue(app.staticTexts[expectedTitle].waitForExistence(timeout: 5))
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
