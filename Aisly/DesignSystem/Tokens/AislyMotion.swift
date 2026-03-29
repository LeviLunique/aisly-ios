import SwiftUI

enum AislyMotion {
    static let quick = Animation.easeOut(duration: 0.18)
    static let standard = Animation.easeOut(duration: 0.3)
    static let emphasis = Animation.spring(response: 0.32, dampingFraction: 0.82)
    static let sheet = Animation.spring(response: 0.44, dampingFraction: 0.86)
    static let progress = Animation.easeOut(duration: 0.5)
    static let loading = Animation.linear(duration: 1).repeatForever(autoreverses: false)

    static let pressScale: CGFloat = 0.98

    static func staggerDelay(for index: Int, step: Double = 0.05) -> Double {
        Double(index) * step
    }
}
