import SwiftUI

#if os(tvOS)

/// Placeholder page for YouTube TV destinations this app cannot fetch yet
/// (Podcasts, Movies). Listed in the rail so the map matches YouTube; the
/// body is an empty state rather than a fake feed.
struct TVOSUnavailableDestinationView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: AppSymbol.tvPlay)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title)
            Text("Not available in this app yet")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("tv.unavailable.\(title)")
    }
}

#endif
