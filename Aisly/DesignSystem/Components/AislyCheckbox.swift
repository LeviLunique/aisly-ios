import SwiftUI

struct AislyCheckbox: View {
    @Binding private var isChecked: Bool
    private let isDisabled: Bool

    init(
        isChecked: Binding<Bool>,
        isDisabled: Bool = false
    ) {
        _isChecked = isChecked
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button {
            guard isDisabled == false else { return }
            withAnimation(AislyMotion.quick) {
                isChecked.toggle()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: AislyCornerRadius.xSmall, style: .continuous)
                    .fill(isChecked ? AislyColor.primary : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AislyCornerRadius.xSmall, style: .continuous)
                            .stroke(isChecked ? AislyColor.primary : AislyColor.borderEmphasis, lineWidth: 2)
                    )

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .scaleEffect(isChecked ? 1 : 0.6)
                    .opacity(isChecked ? 1 : 0)
                    .animation(AislyMotion.quick, value: isChecked)
            }
            .frame(width: 24, height: 24)
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
