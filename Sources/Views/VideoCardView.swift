import SwiftUI

public struct VideoCardView: View {
    public let video: Video
    public let onSelect: (Video) -> Void

    @ObservedObject private var favorites = FavoritesManager.shared

    public init(video: Video, onSelect: @escaping (Video) -> Void) {
        self.video = video
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: { onSelect(video) }) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail with Duration badge
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: video.bestThumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "video.slash")
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(10)

                    if !video.formattedDuration.isEmpty {
                        Text(video.formattedDuration)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }

                // Metadata
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            Text(video.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if !video.formattedViews.isEmpty {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(video.formattedViews)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Quick Favorite Toggle
                    Button(action: {
                        favorites.toggleFavorite(video: video)
                    }) {
                        Image(systemName: favorites.isFavorite(video: video) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(favorites.isFavorite(video: video) ? .red : .secondary)
                            .padding(4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
