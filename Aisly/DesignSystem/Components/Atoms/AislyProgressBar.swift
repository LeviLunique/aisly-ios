import SwiftUI

struct AislyProgressBar: View {
    enum Tone: CaseIterable {
        case primary
        case success
        case warning
        case error

        fileprivate var fillColor: Color {
            switch self {
            case .primary:
                return AislyColor.primary
            case .success:
                return AislyColor.success
            case .warning:
                return AislyColor.warning
            case .error:
                return AislyColor.error
            }
        }
    }

    private let value: Double
    private let maximum: Double
    private let tone: Tone
    private let progressLabel: Text?
    private let percentageLabel: Text?

    init(
        value: Double,
        maximum: Double = 100,
        tone: Tone = .primary,
        progressLabel: Text? = nil,
        percentageLabel: Text? = nil
    ) {
        self.value = value
        self.maximum = maximum
        self.tone = tone
        self.progressLabel = progressLabel
        self.percentageLabel = percentageLabel
    }

    private var percentage: Double {
        guard maximum > 0 else { return 0 }
        return min(max(value / maximum, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            if progressLabel != nil || percentageLabel != nil {
                HStack {
                    progressLabel?
                        .font(AislyTypography.small.weight(.medium))
                        .foregroundStyle(AislyColor.textSecondary)
                    Spacer()
                    percentageLabel?
                        .font(AislyTypography.small.weight(.semibold))
                        .foregroundStyle(tone.fillColor)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AislyColor.surfaceTertiary)

                    Capsule(style: .continuous)
                        .fill(tone.fillColor)
                        .frame(width: geometry.size.width * percentage)
                        .animation(AislyMotion.progress, value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}
