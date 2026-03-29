import SwiftUI

struct AislyInputField<Accessory: View>: View {
    @Binding private var text: String
    private let title: Text?
    private let prompt: Text?
    private let error: Text?
    private let keyboardType: UIKeyboardType
    private let textInputAutocapitalization: TextInputAutocapitalization?
    private let accessory: Accessory

    init(
        text: Binding<String>,
        title: Text? = nil,
        prompt: Text? = nil,
        error: Text? = nil,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization? = .sentences,
        @ViewBuilder accessory: () -> Accessory
    ) {
        _text = text
        self.title = title
        self.prompt = prompt
        self.error = error
        self.keyboardType = keyboardType
        self.textInputAutocapitalization = textInputAutocapitalization
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            if let title {
                title
                    .font(AislyTypography.fieldLabel)
                    .foregroundStyle(AislyColor.textSecondary)
            }

            HStack(spacing: AislySpacing.small) {
                TextField(text: $text, prompt: prompt) {
                    EmptyView()
                }
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .foregroundStyle(AislyColor.textPrimary)
                .font(AislyTypography.body)

                accessory
            }
            .padding(.horizontal, AislySpacing.large)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .stroke(error == nil ? AislyColor.borderSubtle : AislyColor.error, lineWidth: 1)
            )

            if let error {
                error
                    .font(AislyTypography.small)
                    .foregroundStyle(AislyColor.error)
            }
        }
    }
}

extension AislyInputField where Accessory == EmptyView {
    init(
        text: Binding<String>,
        title: Text? = nil,
        prompt: Text? = nil,
        error: Text? = nil,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization? = .sentences
    ) {
        self.init(
            text: text,
            title: title,
            prompt: prompt,
            error: error,
            keyboardType: keyboardType,
            textInputAutocapitalization: textInputAutocapitalization,
            accessory: { EmptyView() }
        )
    }
}

struct AislyTextArea: View {
    @Binding private var text: String
    private let title: Text?
    private let prompt: Text?
    private let error: Text?
    private let minHeight: CGFloat

    init(
        text: Binding<String>,
        title: Text? = nil,
        prompt: Text? = nil,
        error: Text? = nil,
        minHeight: CGFloat = 120
    ) {
        _text = text
        self.title = title
        self.prompt = prompt
        self.error = error
        self.minHeight = minHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AislySpacing.small) {
            if let title {
                title
                    .font(AislyTypography.fieldLabel)
                    .foregroundStyle(AislyColor.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)

                if text.isEmpty, let prompt {
                    prompt
                        .font(AislyTypography.body)
                        .foregroundStyle(AislyColor.textTertiary)
                        .padding(.horizontal, AislySpacing.large)
                        .padding(.vertical, AislySpacing.medium)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .font(AislyTypography.body)
                    .foregroundStyle(AislyColor.textPrimary)
                    .padding(.horizontal, AislySpacing.medium)
                    .padding(.vertical, AislySpacing.small)
                    .background(Color.clear)
            }
            .frame(minHeight: minHeight)
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.standard, style: .continuous)
                    .stroke(error == nil ? AislyColor.borderSubtle : AislyColor.error, lineWidth: 1)
            )

            if let error {
                error
                    .font(AislyTypography.small)
                    .foregroundStyle(AislyColor.error)
            }
        }
    }
}
