import SwiftUI

/// Sheet for editing a list's (or template's) metadata: hero icon preview, name,
/// budget (lists only), color grid and icon grid. Presented from Home or List
/// Detail via `.sheet`.
struct ListInfoSheet: View {
    @Binding private var name: String
    @Binding private var budget: String
    @Binding private var iconName: String
    @Binding private var colorHex: UInt32

    private let showsBudget: Bool
    private let title: String
    private let namePrompt: String
    private let availableColorHexes: [UInt32]
    private let availableIconNames: [String]
    private let isSaveDisabled: Bool
    private let onSave: () -> Void
    private let onClose: () -> Void

    @FocusState private var isNameFocused: Bool

    init(
        name: Binding<String>,
        budget: Binding<String>,
        iconName: Binding<String>,
        colorHex: Binding<UInt32>,
        showsBudget: Bool = true,
        title: String = "List Info",
        namePrompt: String = "List name",
        availableColorHexes: [UInt32],
        availableIconNames: [String],
        isSaveDisabled: Bool,
        onSave: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _name = name
        _budget = budget
        _iconName = iconName
        _colorHex = colorHex
        self.showsBudget = showsBudget
        self.title = title
        self.namePrompt = namePrompt
        self.availableColorHexes = availableColorHexes
        self.availableIconNames = availableIconNames
        self.isSaveDisabled = isSaveDisabled
        self.onSave = onSave
        self.onClose = onClose
    }

    private var listColor: Color {
        Color.aislyListHex(colorHex)
    }

    var body: some View {
        AislySheetContainer(
            title: Text(verbatim: title),
            trailing: {
                HStack(spacing: AislySpacing.large) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AislyColor.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onSave) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSaveDisabled ? AislyColor.textTertiary : AislyColor.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaveDisabled)
                }
            },
            content: {
                VStack(spacing: AislySpacing.xLarge) {
                    AislyCategoryIcon(systemName: iconName, color: listColor, size: .hero)

                    TextField(
                        text: $name,
                        prompt: Text(verbatim: namePrompt)
                            .foregroundColor(AislyColor.textTertiary)
                    ) {
                        Text(verbatim: namePrompt)
                    }
                    .font(AislyTypography.screenTitle)
                    .foregroundStyle(listColor)
                    .multilineTextAlignment(.center)
                    .focused($isNameFocused)
                    .submitLabel(.done)

                    if showsBudget {
                        AislyInputField(
                            text: $budget,
                            title: Text(verbatim: "Budget (optional)"),
                            prompt: Text(verbatim: "R$ 0"),
                            keyboardType: .decimalPad,
                            textInputAutocapitalization: .never
                        )
                    }

                    colorGrid
                    iconGrid
                }
            }
        )
    }

    private var colorGrid: some View {
        VStack(alignment: .leading, spacing: AislySpacing.medium) {
            AislySectionHeader(Text(verbatim: "Color"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: AislySpacing.medium)], spacing: AislySpacing.medium) {
                ForEach(availableColorHexes, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color.aislyListHex(hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(colorHex == hex ? AislyColor.textPrimary : Color.clear, lineWidth: 2)
                                    .padding(-3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: AislySpacing.medium) {
            AislySectionHeader(Text(verbatim: "Icon"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: AislySpacing.medium)], spacing: AislySpacing.medium) {
                ForEach(availableIconNames, id: \.self) { symbol in
                    Button {
                        iconName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(iconName == symbol ? AislyColor.primaryForeground : AislyColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(iconName == symbol ? listColor : AislyColor.surfaceSecondary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
