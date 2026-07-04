import SwiftUI

/// Sheet for creating a new shopping list — either from scratch (name, budget,
/// color, icon) or by generating one from an existing template. Presented from
/// `HomeView` via `.sheet`.
struct NewListSheet: View {
    enum Tab: Hashable {
        case newList
        case templates
    }

    struct TemplateOption: Identifiable, Equatable {
        let id: UUID
        let name: String
        let iconName: String
        let colorHex: UInt32
        let itemCount: Int
        let plannedTotal: Decimal
    }

    @Binding private var selectedTab: Tab
    @Binding private var name: String
    @Binding private var budget: String
    @Binding private var iconName: String
    @Binding private var colorHex: UInt32

    private let availableColorHexes: [UInt32]
    private let availableIconNames: [String]
    private let templates: [TemplateOption]
    private let isConfirmDisabled: Bool
    private let onConfirm: () -> Void
    private let onUseTemplate: (UUID) -> Void
    private let onClose: () -> Void

    @FocusState private var isNameFocused: Bool

    private let swatchColumns = Array(repeating: GridItem(.flexible(), spacing: AislySpacing.medium), count: 6)

    init(
        selectedTab: Binding<Tab>,
        name: Binding<String>,
        budget: Binding<String>,
        iconName: Binding<String>,
        colorHex: Binding<UInt32>,
        availableColorHexes: [UInt32],
        availableIconNames: [String],
        templates: [TemplateOption],
        isConfirmDisabled: Bool,
        onConfirm: @escaping () -> Void,
        onUseTemplate: @escaping (UUID) -> Void,
        onClose: @escaping () -> Void
    ) {
        _selectedTab = selectedTab
        _name = name
        _budget = budget
        _iconName = iconName
        _colorHex = colorHex
        self.availableColorHexes = availableColorHexes
        self.availableIconNames = availableIconNames
        self.templates = templates
        self.isConfirmDisabled = isConfirmDisabled
        self.onConfirm = onConfirm
        self.onUseTemplate = onUseTemplate
        self.onClose = onClose
    }

    var body: some View {
        AislySheetContainer(
            title: Text(verbatim: "New Shopping List"),
            trailing: { headerButtons },
            content: {
                VStack(spacing: AislySpacing.xLarge) {
                    segmentedControl

                    switch selectedTab {
                    case .newList:
                        newListContent
                    case .templates:
                        templatesContent
                    }
                }
            }
        )
        .task {
            if selectedTab == .newList {
                isNameFocused = true
            }
        }
    }

    // MARK: - Header

    private var headerButtons: some View {
        HStack(spacing: AislySpacing.medium) {
            circleButton(systemImage: "xmark", tone: AislyColor.textSecondary, label: "Close") {
                onClose()
            }

            circleButton(
                systemImage: "checkmark",
                tone: canConfirm ? AislyColor.primary : AislyColor.textTertiary,
                label: "Create list",
                enabled: canConfirm
            ) {
                onConfirm()
            }
        }
    }

    private var canConfirm: Bool {
        selectedTab == .newList && isConfirmDisabled == false
    }

    private func circleButton(
        systemImage: String,
        tone: Color,
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tone)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AislyColor.surfaceSecondary))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .accessibilityLabel(Text(verbatim: label))
    }

    // MARK: - Segmented control (custom, matches the kit)

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segment(title: "New List", tab: .newList)
            segment(title: "Templates", tab: .templates)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private func segment(title: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(AislyMotion.quick) { selectedTab = tab }
            if tab == .newList { isNameFocused = true }
        } label: {
            Text(verbatim: title)
                .font(AislyTypography.body.weight(.semibold))
                .foregroundStyle(isSelected ? AislyColor.textPrimary : AislyColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: AislyCornerRadius.small, style: .continuous)
                        .fill(isSelected ? AislyColor.surfacePrimary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: AislyCornerRadius.small, style: .continuous)
                                .stroke(isSelected ? AislyColor.primary : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: isSelected ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - New List tab

    private var listColor: Color {
        Color.aislyListHex(colorHex)
    }

    private var newListContent: some View {
        VStack(spacing: AislySpacing.xLarge) {
            AislyCategoryIcon(systemName: iconName, color: listColor, size: .hero)
                .aislyShadow(AislyShadow.card)
                .padding(.top, AislySpacing.small)

            nameField

            VStack(alignment: .leading, spacing: AislySpacing.small) {
                Text(verbatim: "Budget (optional)")
                    .font(AislyTypography.fieldLabel)
                    .foregroundStyle(AislyColor.textSecondary)

                AislyInputField(
                    text: $budget,
                    prompt: Text(verbatim: "R$ 0,00"),
                    keyboardType: .decimalPad,
                    textInputAutocapitalization: .never
                ) {
                    Text(verbatim: "BRL")
                        .font(AislyTypography.caption)
                        .foregroundStyle(AislyColor.textTertiary)
                }
            }

            colorPicker
            iconPicker
        }
    }

    private var nameField: some View {
        TextField(
            text: $name,
            prompt: Text(verbatim: "List Name").foregroundColor(AislyColor.textTertiary)
        ) { EmptyView() }
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundStyle(name.isEmpty ? AislyColor.textTertiary : listColor)
            .multilineTextAlignment(.center)
            .focused($isNameFocused)
            .submitLabel(.done)
            .padding(.horizontal, AislySpacing.large)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.medium, style: .continuous)
                    .fill(AislyColor.surfaceSecondary)
            )
            .accessibilityLabel(Text(verbatim: "List name"))
    }

    private var colorPicker: some View {
        LazyVGrid(columns: swatchColumns, spacing: AislySpacing.large) {
            ForEach(availableColorHexes, id: \.self) { hex in
                Button {
                    withAnimation(AislyMotion.quick) { colorHex = hex }
                } label: {
                    Circle()
                        .fill(Color.aislyListHex(hex))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(AislyColor.textPrimary, lineWidth: 2)
                                .padding(-4)
                                .opacity(colorHex == hex ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "Color"))
                .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
            }
        }
        .padding(AislySpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    private var iconPicker: some View {
        LazyVGrid(columns: swatchColumns, spacing: AislySpacing.large) {
            ForEach(availableIconNames, id: \.self) { symbol in
                Button {
                    withAnimation(AislyMotion.quick) { iconName = symbol }
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AislyColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AislyColor.surfacePrimary))
                        .overlay(
                            Circle()
                                .strokeBorder(iconName == symbol ? AislyColor.primary : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "Icon"))
                .accessibilityAddTraits(iconName == symbol ? .isSelected : [])
            }
        }
        .padding(AislySpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                .fill(AislyColor.surfaceSecondary)
        )
    }

    // MARK: - Templates tab

    @ViewBuilder
    private var templatesContent: some View {
        if templates.isEmpty {
            VStack(spacing: AislySpacing.medium) {
                Image(systemName: "square.stack")
                    .font(.system(size: 32))
                    .foregroundStyle(AislyColor.textTertiary)

                Text(verbatim: "No templates yet")
                    .font(AislyTypography.rowTitle)
                    .foregroundStyle(AislyColor.textPrimary)

                Text(verbatim: "Save a list as a template to reuse it here.")
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AislySpacing.xxLarge)
        } else {
            VStack(spacing: AislySpacing.medium) {
                ForEach(templates) { template in
                    templateCard(template)
                }

                Text(verbatim: "Select a template to create a list.")
                    .font(AislyTypography.caption)
                    .foregroundStyle(AislyColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AislySpacing.small)
            }
        }
    }

    private func templateCard(_ template: TemplateOption) -> some View {
        Button {
            onUseTemplate(template.id)
        } label: {
            HStack(spacing: AislySpacing.medium) {
                AislyCategoryIcon(
                    systemName: template.iconName,
                    color: Color.aislyListHex(template.colorHex)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(AislyTypography.rowTitle)
                        .foregroundStyle(AislyColor.textPrimary)
                        .lineLimit(1)

                    Text(verbatim: "\(template.itemCount) items · Default planned \(currencyString(template.plannedTotal))")
                        .font(AislyTypography.rowMetadata)
                        .foregroundStyle(AislyColor.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(verbatim: "Use")
                    .font(AislyTypography.caption.weight(.semibold))
                    .foregroundStyle(AislyColor.primaryStrong)
                    .padding(.horizontal, AislySpacing.medium)
                    .padding(.vertical, AislySpacing.xSmall)
                    .background(Capsule(style: .continuous).fill(AislyColor.primaryLight))
            }
            .padding(AislySpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .fill(AislyColor.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AislyCornerRadius.large, style: .continuous)
                    .stroke(AislyColor.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Use template \(template.name)"))
    }

    private func currencyString(_ value: Decimal) -> String {
        value.formatted(.currency(code: Locale.autoupdatingCurrent.currency?.identifier ?? "USD"))
    }
}

extension Color {
    /// Builds a `Color` from a packed `0xRRGGBB` value for list/category swatches.
    static func aislyListHex(_ hex: UInt32) -> Color {
        Color(
            uiColor: UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        )
    }
}
