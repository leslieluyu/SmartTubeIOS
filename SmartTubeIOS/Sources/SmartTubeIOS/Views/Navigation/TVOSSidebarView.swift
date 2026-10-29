import SmartTubeIOSCore
import SwiftUI

#if os(tvOS)

/// YouTube-style left navigation rail for Apple TV.
/// Collapsed: a stack of icons. Expanded (when the rail has focus): labeled
/// destinations. Left from home content focuses the rail; Right returns focus
/// to the page. Existing 4K player focus is unaffected — this is browse chrome.
struct TVOSSidebarView: View {
    @Binding var selection: TVOSSidebarDestination
    @FocusState private var focusedItem: TVOSSidebarDestination?
    @Namespace private var railNamespace
    @Environment(\.colorScheme) private var colorScheme

    private var isExpanded: Bool { focusedItem != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(TVOSSidebarDestination.primaryItems) { item in
                railButton(item)
            }
            Spacer(minLength: 0)
            railButton(.settings)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, isExpanded ? 16 : 10)
        .frame(width: isExpanded ? 300 : 88, alignment: .leading)
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
            HStack(spacing: 16) {
                Image(systemName: item.symbolName)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                if isExpanded {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(
                (isSelected || isFocused)
                    ? Color(white: colorScheme == .dark ? 0 : 1)
                    : Color.primary
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                (isSelected || isFocused) ? Color.primary : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .focusEffectDisabled()
        }
        .buttonStyle(.borderless)
        .focused($focusedItem, equals: item)
        .scaleEffect(isFocused ? 1.06 : 1)
        .animation(.easeInOut(duration: 0.12), value: focusedItem)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

#endif
