import XCTest
@testable import Aisly

final class AislyTests: XCTestCase {
    private func repositoryFile(_ relativePath: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
    }

    private func fileContents(_ relativePath: String) throws -> String {
        try String(contentsOf: repositoryFile(relativePath), encoding: .utf8)
    }

    func testProjectConfigurationDefinesApplicationTarget() throws {
        let projectConfiguration = try fileContents("project.yml")

        XCTAssertTrue(projectConfiguration.contains("  Aisly:\n    type: application"))
    }

    func testProjectConfigurationDefinesUnitTestTarget() throws {
        let projectConfiguration = try fileContents("project.yml")

        XCTAssertTrue(projectConfiguration.contains("  AislyTests:\n    type: bundle.unit-test"))
    }

    func testProjectConfigurationDefinesUITestTarget() throws {
        let projectConfiguration = try fileContents("project.yml")

        XCTAssertTrue(projectConfiguration.contains("  AislyUITests:\n    type: bundle.ui-testing"))
    }

    func testSharedSchemeIncludesUnitTests() throws {
        let sharedScheme = try fileContents("Aisly.xcodeproj/xcshareddata/xcschemes/Aisly.xcscheme")

        XCTAssertTrue(sharedScheme.contains("BlueprintName = \"AislyTests\""))
    }

    func testSharedSchemeIncludesUITests() throws {
        let sharedScheme = try fileContents("Aisly.xcodeproj/xcshareddata/xcschemes/Aisly.xcscheme")

        XCTAssertTrue(sharedScheme.contains("BlueprintName = \"AislyUITests\""))
    }
}
