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
            VStack(alignment: .leading, spacing: 10) {
                // 16:9 Thumbnail with Duration Badge
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: video.bestThumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(YouTubeTheme.surface)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(YouTubeTheme.border)
                            )
                    }
                    .cornerRadius(10)

                    // Video Duration Badge
                    if !video.formattedDuration.isEmpty {
                        Text(video.formattedDuration)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(4)
                            .padding(8)
                    }
                }

                // Video Info Row
                HStack(alignment: .top, spacing: 12) {
                    // Circular Channel Avatar
                    channelAvatar
                        .frame(width: 38, height: 38)

                    // Title & Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(YouTubeTheme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 4) {
                            Text(video.author)
                                .font(.system(size: 12))
                                .foregroundColor(YouTubeTheme.textSecondary)
                                .lineLimit(1)

                            if !video.formattedViews.isEmpty {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(YouTubeTheme.textSecondary)

                                Text(video.formattedViews)
                                    .font(.system(size: 12))
                                    .foregroundColor(YouTubeTheme.textSecondary)
                            }

                            if let published = video.publishedText, !published.isEmpty {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(YouTubeTheme.textSecondary)

                                Text(published)
                                    .font(.system(size: 12))
                                    .foregroundColor(YouTubeTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Three dots context menu
                    Menu {
                        Button(action: {
                            favorites.toggleFavorite(video: video)
                        }) {
                            Label(
                                favorites.isFavorite(video: video) ? "Remove from Library" : "Save to Library",
                                systemImage: favorites.isFavorite(video: video) ? "bookmark.fill" : "bookmark"
                            )
                        }

                        Button(action: {
                            shareVideo()
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(action: {
                            UIPasteboard.general.string = "https://youtu.be/\(video.videoId)"
                        }) {
                            Label("Copy link", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(YouTubeTheme.textSecondary)
                            .rotationEffect(.degrees(90))
                            .padding(.top, 4)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var channelAvatar: some View {
        let initial = video.author.prefix(1).uppercased()
        let colors: [Color] = [.red, .blue, .purple, .orange, .green, .teal]
        let colorIndex = abs(video.author.hashValue) % colors.count

        return ZStack {
            Circle()
                .fill(colors[colorIndex].opacity(0.85))

            Text(initial)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func shareVideo() {
        guard let url = URL(string: "https://youtu.be/\(video.videoId)") else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            rootVC.present(activityVC, animated: true)
        }
    }
}
