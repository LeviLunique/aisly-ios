import SwiftUI

struct AislyEmptyState<Icon: View, ActionContent: View>: View {
    private let icon: Icon
    private let title: LocalizedStringResource
    private let description: LocalizedStringResource?
    private let actionContent: ActionContent

    init(
        icon: Icon,
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        @ViewBuilder actionContent: () -> ActionContent
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionContent = actionContent()
    }

    var body: some View {
        VStack(spacing: AislySpacing.xxLarge) {
            ZStack {
                Circle()
                    .fill(AislyColor.surfaceSecondary)
                    .frame(width: 80, height: 80)

                icon
                    .foregroundStyle(AislyColor.textTertiary)
            }

            VStack(spacing: AislySpacing.small) {
                Text(title)
                    .font(AislyTypography.stateTitle)
                    .foregroundStyle(AislyColor.textPrimary)

                if let description {
                    Text(description)
                        .font(AislyTypography.stateBody)
                        .foregroundStyle(AislyColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            actionContent
        }
        .frame(maxWidth: 320)
        .padding(AislySpacing.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

extension AislyEmptyState where ActionContent == EmptyView {
    init(
        icon: Icon,
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil
    ) {
        self.init(
            icon: icon,
            title: title,
            description: description,
            actionContent: { EmptyView() }
        )
    }
}

struct AislyLoadingState: View {
    private let message: LocalizedStringResource
    @State private var rotation: Double = 0

    init(message: LocalizedStringResource) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: AislySpacing.large) {
            Circle()
                .trim(from: 0.1, to: 0.85)
                .stroke(
                    AngularGradient(
                        colors: [AislyColor.primary, AislyColor.primaryLight],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .task {
                    withAnimation(AislyMotion.loading) {
                        rotation = 360
                    }
                }

            Text(message)
                .font(AislyTypography.stateBody)
                .foregroundStyle(AislyColor.textSecondary)
        }
        .padding(AislySpacing.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AislyToast: View {
    enum Tone {
        case info
        case success
        case error

        fileprivate var backgroundColor: Color {
            switch self {
            case .info:
                return AislyColor.surfacePrimary
            case .success:
                return AislyColor.success
            case .error:
                return AislyColor.error
            }
        }

        fileprivate var foregroundColor: Color {
            switch self {
            case .info:
                return AislyColor.textPrimary
            case .success, .error:
                return Color.white
            }
        }

        fileprivate var borderColor: Color {
            switch self {
            case .info:
                return AislyColor.borderSubtle
            case .success, .error:
                return .clear
            }
        }
    }

    private let message: Text
    private let tone: Tone
    private let dismissAction: (() -> Void)?

    init(
        message: Text,
        tone: Tone = .info,
        dismissAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.tone = tone
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: AislySpacing.medium) {
            message
                .font(AislyTypography.caption.weight(.medium))
                .foregroundStyle(tone.foregroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tone.foregroundColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AislySpacing.large)
        .padding(.vertical, AislySpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(tone.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .stroke(tone.borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
    }
}

// MARK: - Toast presentation

/// App-wide presenter for transient success/info feedback. Host it once at the
/// navigation root with `.aislyToastHost(_:)` so toasts outlive screen pops and
/// sheet dismissals, and inject it via `.environmentObject` for screens to call.
@MainActor
final class AislyToastCenter: ObservableObject {
    struct Entry: Equatable {
        let message: String
        let tone: AislyToast.Tone
    }

    @Published private(set) var entry: Entry?

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, tone: AislyToast.Tone = .success) {
        dismissTask?.cancel()
        entry = Entry(message: message, tone: tone)
        // Transient UI never reaches VoiceOver unless announced explicitly.
        AccessibilityNotification.Announcement(message).post()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard Task.isCancelled == false else { return }
            self?.hide()
        }
    }

    func hide() {
        dismissTask?.cancel()
        dismissTask = nil
        entry = nil
    }
}

extension View {
    /// Hosts the shared toast overlay above all content. Apply once, at the root.
    func aislyToastHost(_ center: AislyToastCenter) -> some View {
        modifier(AislyToastHostModifier(center: center))
    }
}

private struct AislyToastHostModifier: ViewModifier {
    @ObservedObject var center: AislyToastCenter

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let entry = center.entry {
                    AislyToast(
                        message: Text(verbatim: entry.message),
                        tone: entry.tone,
                        dismissAction: { center.hide() }
                    )
                    .padding(.horizontal, AislySpacing.xLarge)
                    .padding(.bottom, AislySpacing.xLarge)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(AislyMotion.emphasis, value: center.entry)
    }
}
