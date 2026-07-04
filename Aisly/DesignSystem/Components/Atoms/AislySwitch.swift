import SwiftUI

struct AislySwitch: View {
    @Binding private var isOn: Bool
    private let label: Text?
    private let isDisabled: Bool

    init(
        isOn: Binding<Bool>,
        label: Text? = nil,
        isDisabled: Bool = false
    ) {
        _isOn = isOn
        self.label = label
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button {
            guard isDisabled == false else { return }
            withAnimation(AislyMotion.emphasis) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: AislySpacing.medium) {
                if let label {
                    label
                        .font(AislyTypography.fieldLabel)
                        .foregroundStyle(AislyColor.textPrimary)
                }

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(isOn ? AislyColor.success : AislyColor.surfaceTertiary)
                        .frame(width: 51, height: 31)

                    Circle()
                        .fill(AislyColor.surfacePrimary)
                        .frame(width: 27, height: 27)
                        .padding(2)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
                }
            }
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
