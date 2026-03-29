import SwiftUI

enum AislyTypography {
    static let pageTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let screenTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let listHeader = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
    static let small = Font.system(size: 12, weight: .regular, design: .rounded)
    static let buttonLabel = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let fieldLabel = Font.system(size: 15, weight: .medium, design: .rounded)
    static let metricValue = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let metricLabel = Font.system(size: 14, weight: .regular, design: .rounded)

    static let sectionHeader = Font.system(.caption, design: .rounded).weight(.semibold)
    static let rowTitle = Font.system(.body, design: .rounded).weight(.semibold)
    static let rowMetadata = Font.system(.caption, design: .rounded)
    static let stateTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let stateBody = Font.system(.body, design: .rounded)
}
