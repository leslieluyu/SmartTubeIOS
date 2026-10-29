import SmartTubeIOSCore
import SwiftUI

#if os(tvOS)

/// Large Recommended feature row for the tvOS home screen: a wide hero
/// thumbnail plus title/channel/description, matching the YouTube Apple TV
/// featured area above the remaining shelves.
struct TVOSHomeHeroView: View {
    let video: Video
    let onSelect: (Video) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button {
            onSelect(video)
        } label: {
            HStack(alignment: .top, spacing: 28) {
                thumbnail
                    .frame(maxWidth: 720)
                metadata
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .focusEffectDisabled()
        }
        .buttonStyle(.borderless)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1)
        .shadow(color: isFocused ? .white.opacity(0.55) : .clear, radius: 18)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .accessibilityIdentifier("video.card.\(video.id)")
        .accessibilityLabel(video.title)
        .accessibilityValue("hero")
        .background(
            Color.clear
                .accessibilityIdentifier("home.hero")
                .allowsHitTesting(false)
        )
    }

    private var thumbnail: some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                AsyncImage(url: video.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(Color.secondary.opacity(0.25))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottomTrailing) {
                let dur = video.formattedDuration
                if !dur.isEmpty {
                    Text(dur)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.white)
                        .padding(10)
                }
            }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(video.title)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Text(video.channelTitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            let views = video.formattedViewCount
            if !views.isEmpty {
                Text(views)
                    .font(.headline)
                    .foregroundStyle(.tertiary)
            }
            if let description = video.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
        }
        .foregroundStyle(.primary)
    }
}

#endif
