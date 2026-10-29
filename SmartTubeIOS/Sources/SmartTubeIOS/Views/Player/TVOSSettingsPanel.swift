import SwiftUI

#if os(tvOS)

/// Compact title for the right-side settings / quality / speed / captions drawer.
struct TVOSSettingsPanelHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: TVOSPlayerChromeMetrics.settingsTitleFontSize, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TVOSPlayerChromeMetrics.settingsRowHorizontalPadding)
            .padding(.top, TVOSPlayerChromeMetrics.settingsTitleTopPadding)
            .padding(.bottom, TVOSPlayerChromeMetrics.settingsTitleBottomPadding)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Dense focused row. Disables the default tvOS white platter so Options / quality
/// / speed / captions / audio / sleep share one tight list, not oversized pills.
struct TVOSSettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TVOSSettingsRowButtonLabel(configuration: configuration)
    }

    private struct TVOSSettingsRowButtonLabel: View {
        @Environment(\.isFocused) private var isFocused
        let configuration: ButtonStyle.Configuration

        var body: some View {
            configuration.label
                .font(.system(size: TVOSPlayerChromeMetrics.settingsRowFontSize, weight: .medium))
                .padding(.horizontal, TVOSPlayerChromeMetrics.settingsRowHorizontalPadding)
                .padding(.vertical, TVOSPlayerChromeMetrics.settingsRowVerticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: TVOSPlayerChromeMetrics.settingsRowCornerRadius)
                        .fill(
                            isFocused
                                ? Color.white.opacity(TVOSPlayerChromeMetrics.settingsRowFocusOpacity)
                                : Color.clear)
                )
                .opacity(configuration.isPressed ? 0.72 : 1)
                .focusEffectDisabled()
        }
    }
}

#endif

extension View {
    /// iOS keeps the default plain row padding. tvOS uses the dense drawer style.
    @ViewBuilder
    func playerSettingsRowButtonStyle() -> some View {
        #if os(tvOS)
        self
            .buttonStyle(TVOSSettingsRowButtonStyle())
            .focusEffectDisabled()
        #else
        self.buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    func playerSettingsRowLabelInsets() -> some View {
        #if os(tvOS)
        self
        #else
        self
            .padding(.horizontal)
            .padding(.vertical, 12)
        #endif
    }

    /// More-menu labels keep iOS `.padding()`; tvOS padding lives on the row style.
    @ViewBuilder
    func playerSettingsMenuRowPadding() -> some View {
        #if os(tvOS)
        self
        #else
        self.padding()
        #endif
    }
}
