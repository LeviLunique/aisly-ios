import SwiftUI

/// Sign-in screen for remote mode. Offers registration (as a sheet) and a
/// tertiary escape hatch that disables the remote flag and continues with
/// local storage only.
struct LoginView: View {
    @ObservedObject private var sessionStore: AuthSessionStore
    private let onContinueOffline: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isPresentingRegister = false

    init(
        sessionStore: AuthSessionStore,
        onContinueOffline: @escaping () -> Void
    ) {
        self.sessionStore = sessionStore
        self.onContinueOffline = onContinueOffline
    }

    private var isSignInDisabled: Bool {
        isSubmitting
            || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AislySpacing.xxxLarge) {
                header

                VStack(spacing: AislySpacing.large) {
                    AislyInputField(
                        text: $email,
                        title: Text(verbatim: "Email"),
                        prompt: Text(verbatim: "you@example.com"),
                        keyboardType: .emailAddress,
                        textInputAutocapitalization: .never
                    )
                    .autocorrectionDisabled()
                    .accessibilityLabel(Text(verbatim: "Email"))

                    AuthSecureField(
                        text: $password,
                        title: Text(verbatim: "Password"),
                        prompt: Text(verbatim: "Your password")
                    )
                    .accessibilityLabel(Text(verbatim: "Password"))

                    if let errorMessage {
                        Text(verbatim: errorMessage)
                            .font(AislyTypography.small)
                            .foregroundStyle(AislyColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                actions
            }
            .padding(.horizontal, AislySpacing.xxLarge)
            .padding(.bottom, AislySpacing.giant)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(AislyColor.backgroundPrimary.ignoresSafeArea())
        .sheet(isPresented: $isPresentingRegister) {
            RegisterView(sessionStore: sessionStore)
        }
    }

    private var header: some View {
        VStack(spacing: AislySpacing.large) {
            AislyLogo(size: .large)

            Text(verbatim: "Welcome to Aisly")
                .font(AislyTypography.screenTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(verbatim: "Sign in to sync your shopping lists across devices.")
                .font(AislyTypography.body)
                .foregroundStyle(AislyColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AislySpacing.giant)
    }

    private var actions: some View {
        VStack(spacing: AislySpacing.medium) {
            Button {
                submit()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .tint(AislyColor.primaryForeground)
                } else {
                    Text(verbatim: "Sign In")
                }
            }
            .buttonStyle(AislyButtonStyle(variant: .primary, size: .large, isFullWidth: true))
            .disabled(isSignInDisabled)
            .accessibilityLabel(Text(verbatim: "Sign In"))

            Button {
                errorMessage = nil
                isPresentingRegister = true
            } label: {
                Text(verbatim: "Create account")
            }
            .buttonStyle(AislyButtonStyle(variant: .ghost, size: .medium, isFullWidth: true))
            .accessibilityLabel(Text(verbatim: "Create account"))

            Button {
                AislyRemoteConfig.setEnabled(false)
                onContinueOffline()
            } label: {
                Text(verbatim: "Continue offline")
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
                    .underline()
            }
            .padding(.top, AislySpacing.small)
            .accessibilityLabel(Text(verbatim: "Continue offline"))
        }
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                try await sessionStore.login(email: trimmedEmail, password: password)
            } catch {
                errorMessage = AuthErrorMessage.friendlyText(for: error)
            }

            isSubmitting = false
        }
    }
}

/// Secure text field styled to match `AislyInputField`.
struct AuthSecureField: View {
    @Binding private var text: String
    private let title: Text?
    private let prompt: Text?

    init(
        text: Binding<String>,
        title: Text? = nil,
        prompt: Text? = nil
    ) {
        _text = text
        self.title = title
        self.prompt = prompt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            if let title {
                title
                    .font(AislyTypography.fieldLabel)
                    .foregroundStyle(AislyColor.textSecondary)
            }

            SecureField(text: $text, prompt: prompt) {
                EmptyView()
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(AislyColor.textPrimary)
            .font(AislyTypography.body)
            .padding(.horizontal, AislySpacing.large)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
        }
    }
}

/// Maps transport errors to short, user-friendly copy.
enum AuthErrorMessage {
    static func friendlyText(for error: Error) -> String {
        switch error {
        case AislyAPIError.unauthorized:
            return "Invalid email or password."
        case AislyAPIError.server(_, let message):
            return message ?? "Something went wrong. Please try again."
        case AislyAPIError.network:
            return "Could not reach the server. Check your connection and try again."
        case AislyAPIError.decoding:
            return "Unexpected response from the server. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
