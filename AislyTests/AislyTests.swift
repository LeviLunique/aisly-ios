import XCTest
@testable import Aisly

final class AislyTests: XCTestCase {
    func testAislySpacingMatchesReferenceScale() {
        XCTAssertEqual(AislySpacing.xSmall, 4)
        XCTAssertEqual(AislySpacing.small, 8)
        XCTAssertEqual(AislySpacing.medium, 12)
        XCTAssertEqual(AislySpacing.large, 16)
        XCTAssertEqual(AislySpacing.xLarge, 20)
        XCTAssertEqual(AislySpacing.xxLarge, 24)
        XCTAssertEqual(AislySpacing.xxxLarge, 32)
        XCTAssertEqual(AislySpacing.giant, 40)
    }

    func testAislyCornerRadiusScaleSupportsNativeCardSurfaces() {
        XCTAssertLessThan(AislyCornerRadius.xSmall, AislyCornerRadius.small)
        XCTAssertLessThan(AislyCornerRadius.small, AislyCornerRadius.medium)
        XCTAssertLessThan(AislyCornerRadius.small, AislyCornerRadius.standard)
        XCTAssertLessThan(AislyCornerRadius.standard, AislyCornerRadius.medium)
        XCTAssertLessThan(AislyCornerRadius.medium, AislyCornerRadius.large)
        XCTAssertLessThan(AislyCornerRadius.large, AislyCornerRadius.xLarge)
        XCTAssertLessThan(AislyCornerRadius.xLarge, AislyCornerRadius.xxLarge)
        XCTAssertGreaterThan(AislyCornerRadius.full, AislyCornerRadius.xxLarge)
    }

    func testAislyMotionMatchesReferenceInteractionPosture() {
        XCTAssertEqual(AislyMotion.pressScale, 0.98, accuracy: 0.0001)
    }

    func testExpandedDesignSystemVariantsRemainAvailable() {
        XCTAssertEqual(Set(AislyButtonStyle.Variant.allCases), Set([.primary, .secondary, .success, .destructive, .ghost]))
        XCTAssertEqual(Set(AislyButtonStyle.Size.allCases), Set([.small, .medium, .large]))
        XCTAssertEqual(Set(AislyBadge.Tone.allCases), Set([.neutral, .primary, .success, .warning, .error, .archive]))
        XCTAssertEqual(Set(AislyBadge.Size.allCases), Set([.small, .medium]))
        XCTAssertEqual(Set(AislyProgressBar.Tone.allCases), Set([.primary, .success, .warning, .error]))
        XCTAssertEqual(Set(AislyBudgetSummaryCard.DeltaTone.allCases), Set([.neutral, .underBudget, .overBudget]))
    }

    func testExpandedDesignSystemComponentFilesExist() {
        let expectedFiles = [
            "Aisly/DesignSystem/Components/AislyButtonStyle.swift",
            "Aisly/DesignSystem/Components/AislyBadge.swift",
            "Aisly/DesignSystem/Components/AislyInputField.swift",
            "Aisly/DesignSystem/Components/AislyCheckbox.swift",
            "Aisly/DesignSystem/Components/AislySwitch.swift",
            "Aisly/DesignSystem/Components/AislyProgressBar.swift",
            "Aisly/DesignSystem/Components/AislyStateViews.swift",
            "Aisly/DesignSystem/Components/AislySheetContainer.swift",
            "Aisly/DesignSystem/Components/AislyPageHeader.swift",
            "Aisly/DesignSystem/Components/AislyBudgetSummaryCard.swift",
            "Aisly/DesignSystem/Components/AislyItemRow.swift",
            "Aisly/DesignSystem/Components/AislyListSummaryCard.swift",
            "Aisly/DesignSystem/Tokens/AislyMotion.swift",
            "Aisly/AppleSurfaces/OpenListsIntent.swift",
            "Aisly/AppleSurfaces/OpenShoppingModeIntent.swift",
            "Shared/AppleSurfaces/AppRoute.swift",
            "Shared/AppleSurfaces/AppleSurfaceListStore.swift",
            "Shared/AppleSurfaces/AppleSurfaceRouteRequestStore.swift",
            "Shared/AppleSurfaces/ShoppingListAppEntity.swift",
            "AislyWidgets/ActiveListWidget.swift",
            "AislyWidgets/AislyWidgetsBundle.swift"
        ]

        for relativePath in expectedFiles {
            XCTAssertTrue(FileManager.default.fileExists(atPath: appFileURL(relativePath).path), relativePath)
        }
    }

    func testAislyLogoSizeScaleMatchesReferenceDimensions() {
        XCTAssertEqual(AislyLogo.Size.small.dimension, 40)
        XCTAssertEqual(AislyLogo.Size.medium.dimension, 64)
        XCTAssertEqual(AislyLogo.Size.large.dimension, 96)
        XCTAssertEqual(AislyLogo.Size.xLarge.dimension, 128)
        XCTAssertEqual(AislyMark.Size.small.dimension, 24)
        XCTAssertEqual(AislyMark.Size.medium.dimension, 32)
        XCTAssertEqual(AislyMark.Size.large.dimension, 48)
    }

    func testAislyLogoSupportsAllSharedVariants() {
        XCTAssertEqual(
            Set(AislyLogo.Variant.allCases),
            Set([.default, .monochrome, .light, .dark])
        )
    }

    func testLocalizationCatalogExistsWithEnglishAndBrazilianPortugueseTranslations() throws {
        let catalog = try makeLocalizationCatalog()
        let expectedLocales = Set(["en", "pt-BR"])

        XCTAssertEqual(Set(catalog.locales), expectedLocales)

        for entry in catalog.strings.values {
            XCTAssertEqual(Set(entry.localizations.keys), expectedLocales)
        }
    }

    func testLegacyLocalizedStringsFilesAreRemoved() {
        let legacyEnglishURL = appFileURL("Aisly/en.lproj/Localizable.strings")
        let legacyBrazilianPortugueseURL = appFileURL("Aisly/pt-BR.lproj/Localizable.strings")

        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyEnglishURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyBrazilianPortugueseURL.path))
    }

    func testAppSourceDoesNotContainLocalizedUIStringLiterals() throws {
        let sourceFileURLs = try FileManager.default.contentsOfDirectory(
            at: appFileURL("Aisly"),
            includingPropertiesForKeys: nil
        )
        let swiftFileURLs = sourceFileURLs.recursiveSwiftFiles()
        let forbiddenPatterns = [
            #"\bText\(\s*"[^"]+""#,
            #"\bButton\(\s*"[^"]+""#,
            #"\bLabel\(\s*"[^"]+""#,
            #"\bProgressView\(\s*"[^"]+""#,
            #"\.navigationTitle\(\s*"[^"]+""#
        ]

        let violations = try swiftFileURLs.flatMap { fileURL -> [String] in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let allowedPatterns = fileURL.lastPathComponent == "AppleSurfaceRouteRequestStore.swift"
                ? Set([#"UserDefaults"#])
                : []

            return forbiddenPatterns.compactMap { pattern in
                guard allowedPatterns.contains(pattern) == false else {
                    return nil
                }

                return contents.range(of: pattern, options: .regularExpression).map { _ in
                    "\(fileURL.lastPathComponent): \(pattern)"
                }
            }
        }

        XCTAssertEqual(violations, [])
    }

    func testLocalizedStringResourcesRemainCentralizedInAppStrings() throws {
        let sourceFileURLs = try FileManager.default.contentsOfDirectory(
            at: appFileURL("Aisly"),
            includingPropertiesForKeys: nil
        )
        let swiftFileURLs = sourceFileURLs.recursiveSwiftFiles().filter {
            $0.lastPathComponent != "AppStrings.swift"
        }

        let violations = try swiftFileURLs.flatMap { fileURL -> [String] in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            return contents.range(
                of: #"LocalizedStringResource\("#,
                options: .regularExpression
            ).map { _ in
                ["\(fileURL.lastPathComponent): LocalizedStringResource("]
            } ?? []
        }

        XCTAssertEqual(violations, [])
    }

    func testLocalizationKeysRemainCentralizedInSharedRegistry() throws {
        let sourceFileURLs = try (
            FileManager.default.contentsOfDirectory(
                at: appFileURL("Aisly"),
                includingPropertiesForKeys: nil
            ) +
            FileManager.default.contentsOfDirectory(
                at: appFileURL("AislyUITests"),
                includingPropertiesForKeys: nil
            )
        )
        let swiftFileURLs = sourceFileURLs.recursiveSwiftFiles().filter {
            $0.lastPathComponent != "AppTextKeys.swift"
        }
        let localizationKeyPattern = #""[a-z0-9]+(?:\.[A-Za-z0-9-]+){2,}""#
        let allowedMetadataFiles = Set([
            "OpenListsIntent.swift",
            "OpenShoppingModeIntent.swift",
            "ShoppingListAppEntity.swift"
        ])

        let violations = try swiftFileURLs.flatMap { fileURL -> [String] in
            guard allowedMetadataFiles.contains(fileURL.lastPathComponent) == false else {
                return []
            }

            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            return contents.range(
                of: localizationKeyPattern,
                options: .regularExpression
            ).map { _ in
                ["\(fileURL.lastPathComponent): raw localization key literal"]
            } ?? []
        }

        XCTAssertEqual(violations, [])
    }

    func testPreviewSourceDoesNotContainRenderedFixtureStringLiterals() throws {
        let sourceFileURLs = try FileManager.default.contentsOfDirectory(
            at: appFileURL("Aisly"),
            includingPropertiesForKeys: nil
        )
        let previewFileURLs = try sourceFileURLs.recursiveSwiftFiles().filter { fileURL in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            return contents.contains("#Preview") || contents.contains("PreviewProvider")
        }
        let forbiddenPatterns = [
            #"\bname:\s*"[^"]+""#
        ]

        let violations = try previewFileURLs.flatMap { fileURL -> [String] in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            return forbiddenPatterns.compactMap { pattern in
                contents.range(of: pattern, options: .regularExpression).map { _ in
                    "\(fileURL.lastPathComponent): \(pattern)"
                }
            }
        }

        XCTAssertEqual(violations, [])
    }

    func testPreviewSourceUsesCentralizedRenderedMockStringBoundaries() throws {
        let sourceFileURLs = try FileManager.default.contentsOfDirectory(
            at: appFileURL("Aisly"),
            includingPropertiesForKeys: nil
        )
        let previewFileURLs = try sourceFileURLs.recursiveSwiftFiles().filter { fileURL in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            return contents.contains("#Preview") || contents.contains("PreviewProvider")
        }

        let violations = try previewFileURLs.flatMap { fileURL -> [String] in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            var fileViolations: [String] = []

            if
                contents.contains("name:"),
                contents.contains("AppStrings.Mock") == false
            {
                fileViolations.append("\(fileURL.lastPathComponent): preview fixture names should use AppStrings.Mock")
            }

            return fileViolations
        }

        XCTAssertEqual(violations, [])
    }

    func testHomeViewUsesSharedDesignSystemComponents() throws {
        let homeViewContents = try String(
            contentsOf: appFileURL("Aisly/Features/Home/HomeView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(homeViewContents.contains("AislySectionHeader"))
        XCTAssertTrue(homeViewContents.contains("AislyListRowCard"))
        XCTAssertTrue(homeViewContents.contains("AislyPrimaryButtonStyle"))
        XCTAssertTrue(homeViewContents.contains("AislyColor.primary"))
        XCTAssertTrue(homeViewContents.contains("AislyMark"))
        XCTAssertTrue(homeViewContents.contains("AislyLoadingState"))
        XCTAssertTrue(homeViewContents.contains("AislyEmptyState"))
    }

    func testListDetailViewUsesSharedDesignSystemComponents() throws {
        let detailViewContents = try String(
            contentsOf: appFileURL("Aisly/Features/ListDetail/ListDetailView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(detailViewContents.contains("AislyLoadingState"))
        XCTAssertTrue(detailViewContents.contains("AislyEmptyState"))
        XCTAssertTrue(detailViewContents.contains("AislyItemRow"))
        XCTAssertTrue(detailViewContents.contains("AislyBadge"))
        XCTAssertTrue(detailViewContents.contains("AislyInputField"))
        XCTAssertTrue(detailViewContents.contains("AislyBudgetSummaryCard"))
        XCTAssertTrue(detailViewContents.contains("AislyPrimaryButtonStyle"))
    }

    func testShoppingModeViewUsesSharedDesignSystemComponents() throws {
        let shoppingModeContents = try String(
            contentsOf: appFileURL("Aisly/Features/ShoppingMode/ShoppingModeView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(shoppingModeContents.contains("AislyLoadingState"))
        XCTAssertTrue(shoppingModeContents.contains("AislyEmptyState"))
        XCTAssertTrue(shoppingModeContents.contains("AislySurfaceCard"))
        XCTAssertTrue(shoppingModeContents.contains("AislyCheckbox"))
        XCTAssertTrue(shoppingModeContents.contains("AislyBadge"))
        XCTAssertTrue(shoppingModeContents.contains("AislyBudgetSummaryCard"))
        XCTAssertTrue(shoppingModeContents.contains("AislyProgressBar"))
        XCTAssertTrue(shoppingModeContents.contains("AislyInputField"))
    }

    func testAppTextKeysExistInLocalizationCatalog() throws {
        let catalog = try makeLocalizationCatalog()
        let appTextKeysContents = try String(
            contentsOf: appFileURL("Shared/Localization/AppTextKeys.swift"),
            encoding: .utf8
        )
        let keys = try appTextKeys(in: appTextKeysContents)

        XCTAssertFalse(keys.isEmpty)
        XCTAssertEqual(Set(keys).subtracting(catalog.strings.keys), [])
    }

    func testInfoPlistDeclaresEnglishAndBrazilianPortugueseLocalizations() throws {
        let infoPlistURL = appFileURL("Aisly/Info.plist")
        let infoPlist = try XCTUnwrap(NSDictionary(contentsOf: infoPlistURL) as? [String: Any])
        let localizations = try XCTUnwrap(infoPlist["CFBundleLocalizations"] as? [String])

        XCTAssertEqual(Set(localizations), Set(["en", "pt-BR"]))
    }

    func testInfoPlistDeclaresAislyURLScheme() throws {
        let infoPlistURL = appFileURL("Aisly/Info.plist")
        let infoPlist = try XCTUnwrap(NSDictionary(contentsOf: infoPlistURL) as? [String: Any])
        let urlTypes = try XCTUnwrap(infoPlist["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = urlTypes
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }

        XCTAssertTrue(schemes.contains("aisly"))
    }

    func testCurrentAppSourceDoesNotUseUnexpectedStorageFrameworks() throws {
        let sourceFileURLs = try FileManager.default.contentsOfDirectory(
            at: appFileURL("Aisly"),
            includingPropertiesForKeys: nil
        )
        let swiftFileURLs = sourceFileURLs.recursiveSwiftFiles()
        let forbiddenPatterns = [
            #"UserDefaults"#,
            #"@AppStorage"#,
            #"SecItem"#,
            #"Keychain"#,
            #"ModelContainer"#,
            #"@Query"#,
            #"NSPersistentContainer"#,
            #"Realm"#
        ]

        let violations = try swiftFileURLs.flatMap { fileURL -> [String] in
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            return forbiddenPatterns.compactMap { pattern in
                contents.range(of: pattern, options: .regularExpression).map { _ in
                    "\(fileURL.lastPathComponent): \(pattern)"
                }
            }
        }

        XCTAssertEqual(violations, [])
    }

    func testAppStoragePathsUseApplicationSupportForShoppingLists() {
        let expectedBaseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let expectedURL = expectedBaseURL
            .appendingPathComponent("Aisly", isDirectory: true)
            .appendingPathComponent("shopping-lists.json", isDirectory: false)

        XCTAssertEqual(AppStoragePaths.shoppingListsFileURL(), expectedURL)
    }

    func testAppStoragePathsUseSharedContainerWhenProvided() {
        let sharedContainerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SharedContainer", isDirectory: true)
        let expectedURL = sharedContainerURL
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("Aisly", isDirectory: true)
            .appendingPathComponent("shopping-lists.json", isDirectory: false)

        XCTAssertEqual(
            AppStoragePaths.shoppingListsFileURL(sharedContainerURL: sharedContainerURL),
            expectedURL
        )
    }

    func testAppRouteParsesListDetailURL() throws {
        let listID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let route = try XCTUnwrap(AppRoute(url: URL(string: "aisly://list?listID=\(listID.uuidString)")!))

        XCTAssertEqual(route, .listDetail(listID))
    }

    func testAppRouteParsesShoppingModeURL() throws {
        let listID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let route = try XCTUnwrap(AppRoute(url: URL(string: "aisly://shopping-mode?listID=\(listID.uuidString)")!))

        XCTAssertEqual(route, .shoppingMode(listID))
    }

    func testAppRouteBuildsShoppingModeURL() {
        let listID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

        XCTAssertEqual(
            AppRoute.shoppingMode(listID).url.absoluteString,
            "aisly://shopping-mode?listID=\(listID.uuidString)"
        )
    }

    func testAppleSurfaceRouteRequestStoreSavesAndConsumesPendingRoute() throws {
        let userDefaults = try makeUserDefaultsSuite(testName: #function)
        let route = AppRoute.shoppingMode(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)

        AppleSurfaceRouteRequestStore.savePendingRoute(route, userDefaults: userDefaults)

        XCTAssertEqual(
            AppleSurfaceRouteRequestStore.consumePendingRoute(userDefaults: userDefaults),
            route
        )
        XCTAssertNil(AppleSurfaceRouteRequestStore.consumePendingRoute(userDefaults: userDefaults))
    }

    func testLocalRepositoryReturnsEmptyListsWhenStorageIsMissing() async throws {
        let repository = makeRepository(testName: #function)

        let lists = try await repository.fetchLists()

        XCTAssertEqual(lists, [])
    }

    func testLocalRepositoryPersistsListsAcrossRepositoryInstances() async throws {
        let fileURL = try makeTemporaryFileURL(testName: #function)
        let store = ShoppingListFileStore(fileURL: fileURL)
        let repository = LocalShoppingListRepository(store: store)
        let expectedLists = [makeShoppingList(name: "Weekly Groceries")]

        try await repository.saveLists(expectedLists)

        let reloadedRepository = LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))
        let persistedLists = try await reloadedRepository.fetchLists()

        XCTAssertEqual(persistedLists, expectedLists)
    }

    func testLocalRepositoryPreservesArchiveFlagAndTimestamps() async throws {
        let repository = makeRepository(testName: #function)
        let lists = [
            makeShoppingList(
                name: "Weekly Groceries",
                createdAt: Date(timeIntervalSince1970: 100),
                updatedAt: Date(timeIntervalSince1970: 150),
                isArchived: false
            ),
            makeShoppingList(
                name: "Holiday Shopping",
                createdAt: Date(timeIntervalSince1970: 200),
                updatedAt: Date(timeIntervalSince1970: 250),
                isArchived: true
            )
        ]

        try await repository.saveLists(lists)

        let persistedLists = try await repository.fetchLists()

        XCTAssertEqual(persistedLists, lists)
    }

    func testLocalRepositoryThrowsWhenPersistedDataIsMalformed() async throws {
        let fileURL = try makeTemporaryFileURL(testName: #function)
        let repository = LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))

        try Data("not valid json".utf8).write(to: fileURL, options: .atomic)

        do {
            _ = try await repository.fetchLists()
            XCTFail("Expected malformed persistence to throw")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLocalRepositoryLoadsStageTwoPersistenceWithoutItems() async throws {
        let fileURL = try makeTemporaryFileURL(testName: #function)
        let repository = LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))
        let legacyPayload = """
        [
          {
            "createdAt" : "1970-01-01T00:16:40Z",
            "id" : "11111111-2222-3333-4444-555555555555",
            "isArchived" : false,
            "name" : "Weekly Groceries",
            "updatedAt" : "1970-01-01T00:33:20Z"
          }
        ]
        """

        try Data(legacyPayload.utf8).write(to: fileURL, options: .atomic)

        let lists = try await repository.fetchLists()

        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.name, "Weekly Groceries")
        XCTAssertEqual(lists.first?.items, [])
    }

    func testLocalRepositoryLoadsStageThreePersistenceWithoutBudgetFields() async throws {
        let fileURL = try makeTemporaryFileURL(testName: #function)
        let repository = LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))
        let legacyPayload = """
        [
          {
            "createdAt" : "1970-01-01T00:16:40Z",
            "id" : "11111111-2222-3333-4444-555555555555",
            "isArchived" : false,
            "items" : [
              {
                "category" : "dairy",
                "createdAt" : "1970-01-01T00:16:40Z",
                "id" : "99999999-8888-7777-6666-555555555555",
                "name" : "Milk",
                "quantity" : 2,
                "sortOrder" : 0,
                "updatedAt" : "1970-01-01T00:33:20Z"
              }
            ],
            "name" : "Weekly Groceries",
            "updatedAt" : "1970-01-01T00:33:20Z"
          }
        ]
        """

        try Data(legacyPayload.utf8).write(to: fileURL, options: .atomic)

        let lists = try await repository.fetchLists()

        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.items.count, 1)
        XCTAssertNil(lists.first?.items.first?.plannedPrice)
        XCTAssertNil(lists.first?.items.first?.actualPrice)
    }

    func testLocalRepositoryLoadsStageFivePersistenceWithoutTemplateFields() async throws {
        let fileURL = try makeTemporaryFileURL(testName: #function)
        let repository = LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))
        let legacyPayload = """
        [
          {
            "createdAt" : "1970-01-01T00:16:40Z",
            "id" : "11111111-2222-3333-4444-555555555555",
            "isArchived" : false,
            "items" : [
              {
                "actualPrice" : 4.75,
                "category" : "dairy",
                "createdAt" : "1970-01-01T00:16:40Z",
                "id" : "99999999-8888-7777-6666-555555555555",
                "name" : "Milk",
                "plannedPrice" : 4.50,
                "quantity" : 2,
                "sortOrder" : 0,
                "updatedAt" : "1970-01-01T00:33:20Z"
              }
            ],
            "name" : "Weekly Groceries",
            "updatedAt" : "1970-01-01T00:33:20Z"
          }
        ]
        """

        try Data(legacyPayload.utf8).write(to: fileURL, options: .atomic)

        let lists = try await repository.fetchLists()

        XCTAssertEqual(lists.count, 1)
        XCTAssertNil(lists.first?.templateConfiguration)
        XCTAssertEqual(lists.first?.items.first?.actualPrice, 4.75)
        XCTAssertNil(lists.first?.items.first?.storeName)
    }

    @MainActor
    func testHomeViewModelStartsIdle() {
        let viewModel = HomeViewModel(repository: StubShoppingListRepository(result: .success([])))

        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testHomeViewModelLoadsActiveAndArchivedListsSortedByUpdatedDate() async {
        let activeID = UUID()
        let archivedID = UUID()
        let olderActiveID = UUID()
        let lists = [
            makeShoppingList(
                id: olderActiveID,
                name: "Bakery",
                updatedAt: Date(timeIntervalSince1970: 100),
                isArchived: false
            ),
            makeShoppingList(
                id: archivedID,
                name: "Holiday Shopping",
                updatedAt: Date(timeIntervalSince1970: 300),
                isArchived: true
            ),
            makeShoppingList(
                id: activeID,
                name: "Weekly Groceries",
                updatedAt: Date(timeIntervalSince1970: 500),
                isArchived: false
            )
        ]
        let viewModel = HomeViewModel(repository: StubShoppingListRepository(result: .success(lists)))

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state,
            .loaded(
                .init(
                    activeLists: [
                        .init(
                            id: activeID,
                            name: "Weekly Groceries",
                            updatedAt: Date(timeIntervalSince1970: 500)
                        ),
                        .init(
                            id: olderActiveID,
                            name: "Bakery",
                            updatedAt: Date(timeIntervalSince1970: 100)
                        )
                    ],
                    archivedLists: [
                        .init(
                            id: archivedID,
                            name: "Holiday Shopping",
                            updatedAt: Date(timeIntervalSince1970: 300)
                        )
                    ]
                )
            )
        )
    }

    @MainActor
    func testHomeViewModelExposesFailureStateWhenRepositoryFails() async {
        let viewModel = HomeViewModel(repository: StubShoppingListRepository(result: .failure(StubError.loadFailed)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    @MainActor
    func testHomeViewModelLoadIfNeededFetchesOnlyOnceAfterSuccessfulLoad() async {
        let repository = CountingShoppingListRepository(lists: [makeShoppingList(name: "Weekly Groceries")])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        let fetchCallCount = await repository.recordedFetchCallCount()

        XCTAssertEqual(fetchCallCount, 1)
    }

    @MainActor
    func testHomeViewModelPresentCreateListStartsEmptyDraft() {
        let viewModel = HomeViewModel(repository: StubShoppingListRepository(result: .success([])))

        viewModel.presentCreateList()

        XCTAssertEqual(viewModel.editorMode, .create)
        XCTAssertEqual(viewModel.draftName, "")
        XCTAssertTrue(viewModel.isDraftSubmissionDisabled)
    }

    @MainActor
    func testHomeViewModelPresentRenameListPrefillsDraftName() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Weekly Groceries")]
        )
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()
        viewModel.presentRenameList(id: listID)

        XCTAssertEqual(viewModel.editorMode, .rename(listID))
        XCTAssertEqual(viewModel.draftName, "Weekly Groceries")
        XCTAssertTrue(viewModel.isDraftSubmissionDisabled)
    }

    @MainActor
    func testHomeViewModelSaveDraftCreatesListAndUpdatesState() async {
        let createdAt = Date(timeIntervalSince1970: 700)
        let createdID = UUID()
        let repository = InMemoryShoppingListRepository(lists: [])
        let viewModel = HomeViewModel(
            repository: repository,
            now: { createdAt },
            makeUUID: { createdID }
        )

        await viewModel.load()
        viewModel.presentCreateList()
        viewModel.updateDraftName("  Weekend Market  ")
        await viewModel.saveDraft()

        let persistedLists = await repository.persistedLists()

        XCTAssertEqual(
            persistedLists,
            [
                ShoppingList(
                    id: createdID,
                    name: "Weekend Market",
                    createdAt: createdAt,
                    updatedAt: createdAt,
                    isArchived: false
                )
            ]
        )
        XCTAssertEqual(
            viewModel.state,
            .loaded(
                .init(
                    activeLists: [
                        .init(
                            id: createdID,
                            name: "Weekend Market",
                            updatedAt: createdAt
                        )
                    ],
                    archivedLists: []
                )
            )
        )
        XCTAssertNil(viewModel.editorMode)
        XCTAssertEqual(viewModel.draftName, "")
    }

    @MainActor
    func testHomeViewModelSaveDraftRenamesListAndUpdatesTimestamp() async {
        let listID = UUID()
        let initialList = makeShoppingList(
            id: listID,
            name: "Weekly Groceries",
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let renamedAt = Date(timeIntervalSince1970: 900)
        let repository = InMemoryShoppingListRepository(lists: [initialList])
        let viewModel = HomeViewModel(
            repository: repository,
            now: { renamedAt }
        )

        await viewModel.load()
        viewModel.presentRenameList(id: listID)
        viewModel.updateDraftName("Weekend Groceries")
        await viewModel.saveDraft()

        let persistedLists = await repository.persistedLists()

        XCTAssertEqual(
            persistedLists,
            [
                ShoppingList(
                    id: listID,
                    name: "Weekend Groceries",
                    createdAt: initialList.createdAt,
                    updatedAt: renamedAt,
                    isArchived: false
                )
            ]
        )
    }

    @MainActor
    func testHomeViewModelArchiveListMovesItIntoArchivedSection() async {
        let listID = UUID()
        let archivedAt = Date(timeIntervalSince1970: 1_200)
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Party Supplies")]
        )
        let viewModel = HomeViewModel(
            repository: repository,
            now: { archivedAt }
        )

        await viewModel.load()
        await viewModel.archiveList(id: listID)

        let persistedLists = await repository.persistedLists()

        XCTAssertEqual(persistedLists.first?.isArchived, true)
        XCTAssertEqual(persistedLists.first?.updatedAt, archivedAt)
        XCTAssertEqual(
            viewModel.state,
            .loaded(
                .init(
                    activeLists: [],
                    archivedLists: [
                        .init(
                            id: listID,
                            name: "Party Supplies",
                            updatedAt: archivedAt
                        )
                    ]
                )
            )
        )
    }

    @MainActor
    func testHomeViewModelLoadSeparatesTemplatesFromActiveAndArchivedLists() async {
        let activeID = UUID()
        let templateID = UUID()
        let archivedID = UUID()
        let viewModel = HomeViewModel(
            repository: StubShoppingListRepository(
                result: .success(
                    [
                        makeShoppingList(id: activeID, name: "Weekly Groceries"),
                        makeShoppingList(
                            id: templateID,
                            name: "Weekly Template",
                            templateConfiguration: .init(recurrence: .weekly)
                        ),
                        makeShoppingList(id: archivedID, name: "Archived List", isArchived: true)
                    ]
                )
            )
        )

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state,
            .loaded(
                .init(
                    activeLists: [
                        .init(id: activeID, name: "Weekly Groceries", updatedAt: Date(timeIntervalSince1970: 2_000))
                    ],
                    templateLists: [
                        .init(
                            id: templateID,
                            name: "Weekly Template",
                            updatedAt: Date(timeIntervalSince1970: 2_000),
                            templateRecurrence: .weekly
                        )
                    ],
                    archivedLists: [
                        .init(id: archivedID, name: "Archived List", updatedAt: Date(timeIntervalSince1970: 2_000))
                    ]
                )
            )
        )
    }

    @MainActor
    func testHomeViewModelPresentCreateTemplatePrefillsDraftFromSourceList() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Weekly Groceries")]
        )
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()
        viewModel.presentCreateTemplate(fromListID: listID)

        XCTAssertEqual(viewModel.templateEditorState, .init(sourceListID: listID))
        XCTAssertEqual(viewModel.templateDraftName, "Weekly Groceries")
        XCTAssertEqual(viewModel.templateDraftRecurrence, .weekly)
        XCTAssertFalse(viewModel.isTemplateDraftSubmissionDisabled)
    }

    @MainActor
    func testHomeViewModelSaveTemplateDraftCreatesTemplateCopyWithResetActualPrices() async throws {
        let sourceListID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: sourceListID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let savedAt = Date(timeIntervalSince1970: 3_000)
        let viewModel = HomeViewModel(
            repository: repository,
            now: { savedAt }
        )

        await viewModel.load()
        viewModel.presentCreateTemplate(fromListID: sourceListID)
        viewModel.updateTemplateDraftName("Weekly Reset")
        viewModel.updateTemplateDraftRecurrence(.biweekly)
        await viewModel.saveTemplateDraft()

        let persistedLists = await repository.persistedLists()
        let templateList = try XCTUnwrap(persistedLists.first(where: \.isTemplate))

        XCTAssertEqual(templateList.name, "Weekly Reset")
        XCTAssertEqual(templateList.templateRecurrence, .biweekly)
        XCTAssertFalse(templateList.isArchived)
        XCTAssertEqual(templateList.updatedAt, savedAt)
        XCTAssertEqual(templateList.items.count, 1)
        XCTAssertEqual(templateList.items.first?.storeName, "Fresh Mart")
        XCTAssertEqual(templateList.items.first?.plannedPrice, 4.5)
        XCTAssertNil(templateList.items.first?.actualPrice)
    }

    @MainActor
    func testHomeViewModelGenerateListFromTemplateCreatesActiveResetCopy() async throws {
        let templateID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: templateID,
                    name: "Weekly Template",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            plannedPrice: 4.5,
                            actualPrice: nil,
                            sortOrder: 0
                        )
                    ],
                    templateConfiguration: .init(recurrence: .weekly)
                )
            ]
        )
        let generatedAt = Date(timeIntervalSince1970: 4_000)
        let viewModel = HomeViewModel(
            repository: repository,
            now: { generatedAt }
        )

        await viewModel.load()
        await viewModel.generateList(fromTemplateID: templateID)

        let persistedLists = await repository.persistedLists()
        let generatedList = try XCTUnwrap(
            persistedLists.first(where: { $0.id != templateID && $0.isTemplate == false })
        )

        XCTAssertEqual(generatedList.name, "Weekly Template")
        XCTAssertNil(generatedList.templateConfiguration)
        XCTAssertFalse(generatedList.isArchived)
        XCTAssertEqual(generatedList.updatedAt, generatedAt)
        XCTAssertEqual(generatedList.items.count, 1)
        XCTAssertNil(generatedList.items.first?.storeName)
        XCTAssertEqual(generatedList.items.first?.plannedPrice, 4.5)
        XCTAssertNil(generatedList.items.first?.actualPrice)
    }

    @MainActor
    func testHomeViewModelSaveDraftIgnoresBlankNames() async {
        let repository = InMemoryShoppingListRepository(lists: [])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()
        viewModel.presentCreateList()
        viewModel.updateDraftName("   ")
        await viewModel.saveDraft()
        let persistedLists = await repository.persistedLists()

        XCTAssertEqual(persistedLists, [])
        XCTAssertEqual(
            viewModel.state,
            .loaded(.init(activeLists: [], archivedLists: []))
        )
        XCTAssertEqual(viewModel.editorMode, .create)
    }

    @MainActor
    func testListDetailViewModelLoadsItemsSortedByOrder() async {
        let listID = UUID()
        let itemOneID = UUID()
        let itemTwoID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemTwoID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            sortOrder: 1
                        ),
                        makeShoppingItem(
                            id: itemOneID,
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state,
            .loaded(
                .init(
                    listID: listID,
                    listName: "Weekly Groceries",
                    plannedTotal: .zero,
                    actualTotal: .zero,
                    budgetDelta: nil,
                    actualPricedItemCount: 0,
                    items: [
                        .init(
                            id: itemOneID,
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            storeName: nil,
                            plannedTotal: nil,
                            actualTotal: nil,
                            isCompleted: false,
                            updatedAt: Date(timeIntervalSince1970: 2_000)
                        ),
                        .init(
                            id: itemTwoID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            storeName: nil,
                            plannedTotal: nil,
                            actualTotal: nil,
                            isCompleted: false,
                            updatedAt: Date(timeIntervalSince1970: 2_000)
                        )
                    ]
                )
            )
        )
    }

    @MainActor
    func testListDetailViewModelPresentCreateItemStartsWithDefaultDraft() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Weekly Groceries")]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentCreateItem()

        XCTAssertEqual(viewModel.editorMode, .create)
        XCTAssertEqual(viewModel.draftName, "")
        XCTAssertEqual(viewModel.draftQuantity, 1)
        XCTAssertEqual(viewModel.draftCategory, .produce)
        XCTAssertEqual(viewModel.draftStoreName, "")
        XCTAssertEqual(viewModel.draftPlannedPrice, "")
        XCTAssertEqual(viewModel.draftActualPrice, "")
        XCTAssertEqual(viewModel.quickEntrySuggestions, [])
        XCTAssertEqual(viewModel.storeSuggestions, [])
        XCTAssertNil(viewModel.priceMemorySuggestion)
        XCTAssertTrue(viewModel.isDraftSubmissionDisabled)
    }

    @MainActor
    func testListDetailViewModelPresentCreateItemExposesQuickEntrySuggestionsFromHistory() async {
        let listID = UUID()
        let olderMilkDate = Date(timeIntervalSince1970: 1_500)
        let newerMilkDate = Date(timeIntervalSince1970: 1_900)
        let applesDate = Date(timeIntervalSince1970: 1_800)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.75,
                            sortOrder: 0,
                            updatedAt: newerMilkDate
                        ),
                        makeShoppingItem(
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            plannedPrice: 0.8,
                            sortOrder: 1,
                            updatedAt: applesDate
                        )
                    ]
                ),
                makeShoppingList(
                    name: "Bakery",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            plannedPrice: 4.5,
                            sortOrder: 0,
                            updatedAt: olderMilkDate
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentCreateItem()

        XCTAssertEqual(
            viewModel.quickEntrySuggestions,
            [
                .init(
                    id: "milk",
                    name: "Milk",
                    quantity: 1,
                    category: .dairy,
                    storeName: "Fresh Mart",
                    plannedPrice: 4.75,
                    usageCount: 2,
                    lastUsedAt: newerMilkDate
                ),
                .init(
                    id: "apples",
                    name: "Apples",
                    quantity: 6,
                    category: .produce,
                    storeName: nil,
                    plannedPrice: 0.8,
                    usageCount: 1,
                    lastUsedAt: applesDate
                )
            ]
        )
    }

    @MainActor
    func testListDetailViewModelQuickEntrySuggestionsFilterByDraftName() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            plannedPrice: 4.75,
                            sortOrder: 0
                        ),
                        makeShoppingItem(
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            plannedPrice: 0.8,
                            sortOrder: 1
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("app")

        XCTAssertEqual(viewModel.quickEntrySuggestions.map(\.name), ["Apples"])
    }

    @MainActor
    func testListDetailViewModelApplyQuickEntrySuggestionPrefillsDraftAndClearsActualPrice() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.applyQuickEntrySuggestion(id: "milk")

        XCTAssertEqual(viewModel.draftName, "Milk")
        XCTAssertEqual(viewModel.draftQuantity, 2)
        XCTAssertEqual(viewModel.draftCategory, .dairy)
        XCTAssertEqual(viewModel.draftStoreName, "Fresh Mart")
        XCTAssertEqual(viewModel.draftPlannedPrice, "4.5")
        XCTAssertEqual(viewModel.draftActualPrice, "")
    }

    @MainActor
    func testListDetailViewModelStoreSuggestionsFilterByDraftStoreName() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.75,
                            sortOrder: 0
                        ),
                        makeShoppingItem(
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            storeName: "City Market",
                            plannedPrice: 0.8,
                            sortOrder: 1
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftStoreName("fresh")

        XCTAssertEqual(viewModel.storeSuggestions.map(\.name), ["Fresh Mart"])
    }

    @MainActor
    func testListDetailViewModelPriceMemoryUsesLastActualPriceForMatchingStore() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0,
                            updatedAt: Date(timeIntervalSince1970: 1_900)
                        ),
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.25,
                            actualPrice: nil,
                            sortOrder: 1,
                            updatedAt: Date(timeIntervalSince1970: 1_800)
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("Milk")
        viewModel.updateDraftStoreName("Fresh Mart")

        XCTAssertEqual(
            viewModel.priceMemorySuggestion,
            .init(
                storeName: "Fresh Mart",
                price: 4.75,
                kind: .actual,
                lastUsedAt: Date(timeIntervalSince1970: 1_900)
            )
        )
    }

    @MainActor
    func testListDetailViewModelApplyPriceMemorySuggestionPrefillsPlannedPrice() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(id: listID, name: "Weekly Groceries"),
                makeShoppingList(
                    name: "Party Supplies",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("Milk")
        viewModel.updateDraftStoreName("Fresh Mart")
        viewModel.applyPriceMemorySuggestion()

        XCTAssertEqual(viewModel.draftPlannedPrice, "4.75")
    }

    @MainActor
    func testListDetailViewModelPresentEditItemPrefillsDraft() async {
        let listID = UUID()
        let itemID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentEditItem(id: itemID)

        XCTAssertEqual(viewModel.editorMode, .edit(itemID))
        XCTAssertEqual(viewModel.draftName, "Milk")
        XCTAssertEqual(viewModel.draftQuantity, 2)
        XCTAssertEqual(viewModel.draftCategory, .dairy)
        XCTAssertEqual(viewModel.draftStoreName, "Fresh Mart")
        XCTAssertEqual(viewModel.draftPlannedPrice, "4.5")
        XCTAssertEqual(viewModel.draftActualPrice, "4.75")
        XCTAssertEqual(viewModel.quickEntrySuggestions, [])
    }

    @MainActor
    func testListDetailViewModelSaveDraftAddsItemToList() async {
        let listID = UUID()
        let itemID = UUID()
        let timestamp = Date(timeIntervalSince1970: 3_000)
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Weekly Groceries")]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp },
            makeUUID: { itemID },
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("  Apples  ")
        viewModel.updateDraftQuantity(3)
        viewModel.updateDraftCategory(.produce)
        viewModel.updateDraftStoreName("Fresh Mart")
        viewModel.updateDraftPlannedPrice("1.25")
        viewModel.updateDraftActualPrice("1.40")
        await viewModel.saveDraft()

        let persistedLists = await repository.persistedLists()
        XCTAssertEqual(persistedLists.first?.items.count, 1)
        XCTAssertEqual(
            persistedLists.first?.items.first,
            ShoppingItem(
                id: itemID,
                name: "Apples",
                quantity: 3,
                category: .produce,
                storeName: "Fresh Mart",
                plannedPrice: 1.25,
                actualPrice: 1.40,
                isCompleted: false,
                createdAt: timestamp,
                updatedAt: timestamp,
                sortOrder: 0
            )
        )
    }

    @MainActor
    func testListDetailViewModelSaveDraftEditsExistingItem() async {
        let listID = UUID()
        let itemID = UUID()
        let timestamp = Date(timeIntervalSince1970: 4_000)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            storeName: "Fresh Mart",
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp },
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentEditItem(id: itemID)
        viewModel.updateDraftName("Greek Yogurt")
        viewModel.updateDraftQuantity(3)
        viewModel.updateDraftCategory(.dairy)
        viewModel.updateDraftStoreName("City Market")
        viewModel.updateDraftPlannedPrice("5.25")
        viewModel.updateDraftActualPrice("5.50")
        await viewModel.saveDraft()

        let persistedLists = await repository.persistedLists()
        XCTAssertEqual(persistedLists.first?.items.first?.name, "Greek Yogurt")
        XCTAssertEqual(persistedLists.first?.items.first?.quantity, 3)
        XCTAssertEqual(persistedLists.first?.items.first?.storeName, "City Market")
        XCTAssertEqual(persistedLists.first?.items.first?.plannedPrice, 5.25)
        XCTAssertEqual(persistedLists.first?.items.first?.actualPrice, 5.50)
        XCTAssertEqual(persistedLists.first?.items.first?.updatedAt, timestamp)
    }

    @MainActor
    func testListDetailViewModelBudgetSnapshotIncludesPlannedAndActualTotals() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        ),
                        makeShoppingItem(
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            plannedPrice: 0.8,
                            actualPrice: nil,
                            sortOrder: 1
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()

        guard case .loaded(let snapshot) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(snapshot.plannedTotal, 13.8)
        XCTAssertEqual(snapshot.actualTotal, 9.5)
        XCTAssertEqual(snapshot.budgetDelta, -4.3)
        XCTAssertEqual(snapshot.actualPricedItemCount, 1)
    }

    @MainActor
    func testListDetailViewModelInvalidPriceDraftDisablesSubmission() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [makeShoppingList(id: listID, name: "Weekly Groceries")]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("Apples")
        viewModel.updateDraftPlannedPrice("abc")

        XCTAssertTrue(viewModel.isDraftSubmissionDisabled)
    }

    @MainActor
    func testListDetailViewModelDeleteItemRemovesItFromList() async {
        let listID = UUID()
        let itemID = UUID()
        let timestamp = Date(timeIntervalSince1970: 5_000)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp }
        )

        await viewModel.load()
        await viewModel.deleteItem(id: itemID)

        let persistedLists = await repository.persistedLists()
        XCTAssertEqual(persistedLists.first?.items, [])
        XCTAssertEqual(persistedLists.first?.updatedAt, timestamp)
    }

    @MainActor
    func testListDetailViewModelMoveItemsPersistsUpdatedOrder() async {
        let listID = UUID()
        let firstID = UUID()
        let secondID = UUID()
        let timestamp = Date(timeIntervalSince1970: 6_000)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: firstID,
                            name: "Apples",
                            quantity: 2,
                            category: .produce,
                            sortOrder: 0
                        ),
                        makeShoppingItem(
                            id: secondID,
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            sortOrder: 1
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp }
        )

        await viewModel.load()
        await viewModel.moveItems(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        let persistedItems = await repository.persistedLists().first?.items ?? []
        XCTAssertEqual(persistedItems.map(\.id), [secondID, firstID])
        XCTAssertEqual(persistedItems.map(\.sortOrder), [0, 1])
        XCTAssertEqual(persistedItems.map(\.updatedAt), [timestamp, timestamp])
    }

    func testStoredShoppingItemDecodesMissingCompletionStateAsFalse() throws {
        let data = Data(
            """
            {
              "id" : "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
              "name" : "Milk",
              "quantity" : 2,
              "category" : "dairy",
              "storeName" : "Fresh Mart",
              "plannedPrice" : 4.50,
              "actualPrice" : 4.75,
              "createdAt" : "2025-01-01T12:00:00Z",
              "updatedAt" : "2025-01-01T12:00:00Z",
              "sortOrder" : 0
            }
            """.utf8
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let storedItem = try decoder.decode(StoredShoppingItem.self, from: data)

        XCTAssertFalse(storedItem.model.isCompleted)
    }

    @MainActor
    func testShoppingModeViewModelLoadsRemainingAndCompletedItems() async {
        let listID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            isCompleted: true,
                            sortOrder: 0
                        ),
                        makeShoppingItem(
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            plannedPrice: 0.8,
                            isCompleted: false,
                            sortOrder: 1
                        )
                    ]
                )
            ]
        )
        let viewModel = ShoppingModeViewModel(listID: listID, repository: repository)

        await viewModel.load()

        guard case .loaded(let snapshot) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(snapshot.itemCount, 2)
        XCTAssertEqual(snapshot.completedItemCount, 1)
        XCTAssertEqual(snapshot.remainingItems.map(\.name), ["Apples"])
        XCTAssertEqual(snapshot.completedItems.map(\.name), ["Milk"])
        XCTAssertEqual(snapshot.actualPricedItemCount, 1)
    }

    @MainActor
    func testShoppingModeViewModelToggleCompletionPersistsItemState() async {
        let listID = UUID()
        let itemID = UUID()
        let timestamp = Date(timeIntervalSince1970: 7_000)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            isCompleted: false,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ShoppingModeViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp }
        )

        await viewModel.load()
        await viewModel.toggleCompletion(id: itemID)

        let persistedItem = await repository.persistedLists().first?.items.first
        XCTAssertEqual(persistedItem?.isCompleted, true)
        XCTAssertEqual(persistedItem?.updatedAt, timestamp)
    }

    @MainActor
    func testShoppingModeViewModelPresentActualPriceEditorPrefillsDraft() async {
        let listID = UUID()
        let itemID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 1,
                            category: .dairy,
                            plannedPrice: 4.5,
                            actualPrice: 4.75,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ShoppingModeViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentActualPriceEditor(id: itemID)

        XCTAssertEqual(viewModel.priceEditorState, .actualPrice(itemID))
        XCTAssertEqual(viewModel.currentEditingItemName, "Milk")
        XCTAssertEqual(viewModel.draftActualPrice, "4.75")
        XCTAssertEqual(viewModel.plannedPriceSuggestion, 4.5)
    }

    @MainActor
    func testShoppingModeViewModelApplyPlannedPriceSuggestionPrefillsDraft() async {
        let listID = UUID()
        let itemID = UUID()
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Apples",
                            quantity: 2,
                            category: .produce,
                            plannedPrice: 1.25,
                            actualPrice: nil,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ShoppingModeViewModel(
            listID: listID,
            repository: repository,
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentActualPriceEditor(id: itemID)
        viewModel.applyPlannedPriceSuggestion()

        XCTAssertEqual(viewModel.draftActualPrice, "1.25")
    }

    @MainActor
    func testShoppingModeViewModelSaveActualPriceDraftPersistsItemPrice() async {
        let listID = UUID()
        let itemID = UUID()
        let timestamp = Date(timeIntervalSince1970: 8_000)
        let repository = InMemoryShoppingListRepository(
            lists: [
                makeShoppingList(
                    id: listID,
                    name: "Weekly Groceries",
                    items: [
                        makeShoppingItem(
                            id: itemID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
                            plannedPrice: 4.5,
                            actualPrice: nil,
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ShoppingModeViewModel(
            listID: listID,
            repository: repository,
            now: { timestamp },
            locale: Locale(identifier: "en_US_POSIX")
        )

        await viewModel.load()
        viewModel.presentActualPriceEditor(id: itemID)
        viewModel.updateDraftActualPrice("4.80")
        await viewModel.saveActualPriceDraft()

        let persistedItem = await repository.persistedLists().first?.items.first
        XCTAssertEqual(persistedItem?.actualPrice, 4.8)
        XCTAssertEqual(persistedItem?.updatedAt, timestamp)
        XCTAssertNil(viewModel.priceEditorState)
    }

    private func makeRepository(testName: String) -> LocalShoppingListRepository {
        let fileURL = try! makeTemporaryFileURL(testName: testName)
        return LocalShoppingListRepository(store: ShoppingListFileStore(fileURL: fileURL))
    }

    private func appFileURL(_ relativePath: String) -> URL {
        repositoryRootURL().appendingPathComponent(relativePath)
    }

    private func repositoryRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func makeLocalizationCatalog() throws -> LocalizationCatalog {
        let data = try Data(contentsOf: appFileURL("Aisly/Localizable.xcstrings"))
        return try JSONDecoder().decode(LocalizationCatalog.self, from: data)
    }

    private func appTextKeys(in contents: String) throws -> [String] {
        let expression = try NSRegularExpression(
            pattern: #"AppTextKey\(value: "([^"]+)"\)"#
        )
        let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)

        return expression.matches(in: contents, range: range).compactMap { match in
            guard
                let keyRange = Range(match.range(at: 1), in: contents)
            else {
                return nil
            }

            return String(contents[keyRange])
        }
    }

    private func makeTemporaryFileURL(testName: String) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AislyTests-\(testName)-\(UUID().uuidString)", isDirectory: true)

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL.appendingPathComponent("shopping-lists.json")
    }

    private func makeUserDefaultsSuite(testName: String) throws -> UserDefaults {
        let suiteName = "AislyTests.\(testName).\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        return userDefaults
    }

    private func makeShoppingList(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000),
        isArchived: Bool = false,
        items: [ShoppingItem] = [],
        templateConfiguration: ShoppingList.TemplateConfiguration? = nil
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items,
            templateConfiguration: templateConfiguration
        )
    }

    private func makeShoppingItem(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        storeName: String? = nil,
        plannedPrice: Decimal? = nil,
        actualPrice: Decimal? = nil,
        isCompleted: Bool = false,
        sortOrder: Int,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000)
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder
        )
    }
}

private struct StubShoppingListRepository: ShoppingListRepository {
    let result: Result<[ShoppingList], Error>

    func fetchLists() async throws -> [ShoppingList] {
        try result.get()
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}

private actor CountingShoppingListRepository: ShoppingListRepository {
    private(set) var fetchCallCount = 0

    let lists: [ShoppingList]

    init(lists: [ShoppingList]) {
        self.lists = lists
    }

    func fetchLists() async throws -> [ShoppingList] {
        fetchCallCount += 1
        return lists
    }

    func recordedFetchCallCount() -> Int {
        fetchCallCount
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
    }
}

private actor InMemoryShoppingListRepository: ShoppingListRepository {
    private var lists: [ShoppingList]

    init(lists: [ShoppingList]) {
        self.lists = lists
    }

    func fetchLists() async throws -> [ShoppingList] {
        lists
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
        self.lists = lists
    }

    func persistedLists() -> [ShoppingList] {
        lists
    }
}

private enum StubError: Error {
    case loadFailed
}

private struct LocalizationCatalog: Decodable {
    let sourceLanguage: String
    let strings: [String: LocalizationCatalogEntry]

    var locales: [String] {
        guard let firstEntry = strings.values.first else {
            return [sourceLanguage]
        }

        return Array(firstEntry.localizations.keys).sorted()
    }
}

private struct LocalizationCatalogEntry: Decodable {
    let localizations: [String: LocalizationCatalogLocalization]
}

private struct LocalizationCatalogLocalization: Decodable {
    let stringUnit: LocalizationCatalogStringUnit?
}

private struct LocalizationCatalogStringUnit: Decodable {
    let state: String
    let value: String
}

private extension Array where Element == URL {
    func recursiveSwiftFiles() -> [URL] {
        flatMap { url -> [URL] in
            var isDirectory: ObjCBool = false

            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                return [URL]()
            }

            if isDirectory.boolValue {
                let childURLs: [URL] = (try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil
                )) ?? []
                return childURLs.recursiveSwiftFiles()
            }

            return url.pathExtension == "swift" ? [url] : [URL]()
        }
    }
}
