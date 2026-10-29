import SmartTubeIOSCore
import SwiftUI

#if os(tvOS)

/// YouTube-style left navigation rail for Apple TV.
/// Collapsed: a stack of icons. Expanded (when the rail has focus): labeled
/// destinations. Left from home content focuses the rail; Right returns focus
/// to the page. Existing 4K player focus is unaffected — this is browse chrome.
///
/// Sized via `TVOSSidebarMetrics` so 12 destinations fit 1920×1080 without
/// overlapping; extra height becomes spacing between rows.
struct TVOSSidebarView: View {
    @Binding var selection: TVOSSidebarDestination
    @FocusState private var focusedItem: TVOSSidebarDestination?
    @Namespace private var railNamespace
    @Environment(\.colorScheme) private var colorScheme

    private var isExpanded: Bool { focusedItem != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(TVOSSidebarDestination.primaryItems) { item in
                railButton(item)
                Spacer(minLength: TVOSSidebarMetrics.minRowSpacing)
            }
            railButton(.settings)
        }
        .padding(.vertical, TVOSSidebarMetrics.railVerticalPadding)
        .padding(
            .horizontal,
            isExpanded
                ? TVOSSidebarMetrics.railHorizontalPaddingExpanded
                : TVOSSidebarMetrics.railHorizontalPaddingCollapsed
        )
        .frame(
            width: isExpanded ? TVOSSidebarMetrics.expandedWidth : TVOSSidebarMetrics.collapsedWidth,
            alignment: .leading
        )
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
        .focusSection()
        .focusScope(railNamespace)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tv.sidebar")
    }

    private func railButton(_ item: TVOSSidebarDestination) -> some View {
        let isSelected = selection == item
        let isFocused = focusedItem == item
        return Button {
            selection = item
        } label: {
            HStack(spacing: TVOSSidebarMetrics.iconLabelSpacing) {
                Image(systemName: item.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: TVOSSidebarMetrics.iconSize,
                        height: TVOSSidebarMetrics.iconSize
                    )
                if isExpanded {
                    Text(item.title)
                        .font(.system(size: TVOSSidebarMetrics.labelFontSize, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
            }
            .frame(height: TVOSSidebarMetrics.rowContentHeight, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(
                (isSelected || isFocused)
                    ? Color(white: colorScheme == .dark ? 0 : 1)
                    : Color.primary
            )
            .padding(.horizontal, TVOSSidebarMetrics.rowHorizontalPadding)
            .padding(.vertical, TVOSSidebarMetrics.rowVerticalPadding)
            .background(
                (isSelected || isFocused) ? Color.primary : Color.clear,
                in: RoundedRectangle(cornerRadius: TVOSSidebarMetrics.cornerRadius)
            )
        }
        .buttonStyle(TVOSRailButtonStyle())
        .focusEffectDisabled()
        .focused($focusedItem, equals: item)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

/// Avoids the default tvOS button chrome, which adds a large focus lift that
/// made rail icons overlap on 1080p.
private struct TVOSRailButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

#endif
