import SwiftUI

/// Account creation sheet. Validates locally (password length and match)
/// before hitting the auth server; on success the session store flips to
/// signedIn and the auth gate swaps to the app content.
struct RegisterView: View {
    @ObservedObject private var sessionStore: AuthSessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    private static let minimumPasswordLength = 8
    private static let passwordSpecialCharacters = "@$!%*#?&"

    init(sessionStore: AuthSessionStore) {
        self.sessionStore = sessionStore
    }

    private var isPasswordStrong: Bool {
        guard password.count >= Self.minimumPasswordLength else { return false }

        let hasLetter = password.contains { $0.isLetter }
        let hasDigit = password.contains { $0.isNumber }
        let specials = Set(Self.passwordSpecialCharacters)
        let hasSpecial = password.contains { specials.contains($0) }

        return hasLetter && hasDigit && hasSpecial
    }

    private var localValidationMessage: String? {
        if password.isEmpty == false, isPasswordStrong == false {
            return "Password must be at least 8 characters and include a letter, a number, and a special character (@$!%*#?&)."
        }

        if confirmPassword.isEmpty == false, password != confirmPassword {
            return "Passwords do not match."
        }

        return nil
    }

    private var isCreateDisabled: Bool {
        isSubmitting
            || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || isPasswordStrong == false
            || password != confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AislySpacing.xxxLarge) {
                header

                VStack(spacing: AislySpacing.large) {
                    AislyInputField(
                        text: $displayName,
                        title: Text(verbatim: "Name"),
                        prompt: Text(verbatim: "How should we call you?"),
                        textInputAutocapitalization: .words
                    )
                    .accessibilityLabel(Text(verbatim: "Name"))

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
                        prompt: Text(verbatim: "8+ chars, letter, number, special")
                    )
                    .accessibilityLabel(Text(verbatim: "Password"))

                    AuthSecureField(
                        text: $confirmPassword,
                        title: Text(verbatim: "Confirm password"),
                        prompt: Text(verbatim: "Repeat your password")
                    )
                    .accessibilityLabel(Text(verbatim: "Confirm password"))

                    if let message = errorMessage ?? localValidationMessage {
                        Text(verbatim: message)
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
    }

    private var header: some View {
        VStack(spacing: AislySpacing.large) {
            AislyLogo(size: .medium)

            Text(verbatim: "Create your account")
                .font(AislyTypography.screenTitle)
                .foregroundStyle(AislyColor.textPrimary)

            Text(verbatim: "Your lists will be synced to your account.")
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
                    Text(verbatim: "Create Account")
                }
            }
            .buttonStyle(AislyButtonStyle(variant: .primary, size: .large, isFullWidth: true))
            .disabled(isCreateDisabled)
            .accessibilityLabel(Text(verbatim: "Create Account"))

            Button {
                dismiss()
            } label: {
                Text(verbatim: "Back to sign in")
            }
            .buttonStyle(AislyButtonStyle(variant: .ghost, size: .medium, isFullWidth: true))
            .accessibilityLabel(Text(verbatim: "Back to sign in"))
        }
    }

    private func submit() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                try await sessionStore.register(
                    email: trimmedEmail,
                    password: password,
                    displayName: trimmedName
                )
                dismiss()
            } catch {
                errorMessage = AuthErrorMessage.friendlyText(for: error)
            }

            isSubmitting = false
        }
    }
}
