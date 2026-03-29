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
            "Aisly/DesignSystem/Tokens/AislyMotion.swift"
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

            return forbiddenPatterns.compactMap { pattern in
                contents.range(of: pattern, options: .regularExpression).map { _ in
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

        let violations = try swiftFileURLs.flatMap { fileURL -> [String] in
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
        XCTAssertTrue(detailViewContents.contains("AislyPrimaryButtonStyle"))
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
                    items: [
                        .init(
                            id: itemOneID,
                            name: "Apples",
                            quantity: 6,
                            category: .produce,
                            updatedAt: Date(timeIntervalSince1970: 2_000)
                        ),
                        .init(
                            id: itemTwoID,
                            name: "Milk",
                            quantity: 2,
                            category: .dairy,
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
        XCTAssertTrue(viewModel.isDraftSubmissionDisabled)
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
                            sortOrder: 0
                        )
                    ]
                )
            ]
        )
        let viewModel = ListDetailViewModel(listID: listID, repository: repository)

        await viewModel.load()
        viewModel.presentEditItem(id: itemID)

        XCTAssertEqual(viewModel.editorMode, .edit(itemID))
        XCTAssertEqual(viewModel.draftName, "Milk")
        XCTAssertEqual(viewModel.draftQuantity, 2)
        XCTAssertEqual(viewModel.draftCategory, .dairy)
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
            makeUUID: { itemID }
        )

        await viewModel.load()
        viewModel.presentCreateItem()
        viewModel.updateDraftName("  Apples  ")
        viewModel.updateDraftQuantity(3)
        viewModel.updateDraftCategory(.produce)
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
        viewModel.presentEditItem(id: itemID)
        viewModel.updateDraftName("Greek Yogurt")
        viewModel.updateDraftQuantity(3)
        viewModel.updateDraftCategory(.dairy)
        await viewModel.saveDraft()

        let persistedLists = await repository.persistedLists()
        XCTAssertEqual(persistedLists.first?.items.first?.name, "Greek Yogurt")
        XCTAssertEqual(persistedLists.first?.items.first?.quantity, 3)
        XCTAssertEqual(persistedLists.first?.items.first?.updatedAt, timestamp)
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

    private func makeShoppingList(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000),
        isArchived: Bool = false,
        items: [ShoppingItem] = []
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items
        )
    }

    private func makeShoppingItem(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        sortOrder: Int,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000)
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
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
