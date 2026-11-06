import SwiftUI

public struct VideoActionButtonsView: View {
    public let video: Video
    public let videoDetail: VideoDetail?
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var isLiked: Bool = false
    @State private var isDisliked: Bool = false

    public init(video: Video, videoDetail: VideoDetail?) {
        self.video = video
        self.videoDetail = videoDetail
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Like / Dislike Combined Pill
                HStack(spacing: 0) {
                    Button(action: {
                        isLiked.toggle()
                        if isLiked { isDisliked = false }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 14))
                                .foregroundColor(isLiked ? YouTubeTheme.red : YouTubeTheme.textPrimary)
                            Text(videoDetail?.formattedLikes ?? "Like")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(YouTubeTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }

                    Rectangle()
                        .fill(YouTubeTheme.border)
                        .frame(width: 1, height: 18)

                    Button(action: {
                        isDisliked.toggle()
                        if isDisliked { isLiked = false }
                    }) {
                        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14))
                            .foregroundColor(isDisliked ? YouTubeTheme.red : YouTubeTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                }
                .background(YouTubeTheme.pill)
                .cornerRadius(18)

                // Share Button
                Button(action: {
                    shareVideo()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 14))
                        Text("Share")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(YouTubeTheme.pill)
                    .cornerRadius(18)
                }

                // Library / Bookmark Button
                Button(action: {
                    favorites.toggleFavorite(video: video)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: favorites.isFavorite(video: video) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14))
                            .foregroundColor(favorites.isFavorite(video: video) ? YouTubeTheme.red : YouTubeTheme.textPrimary)
                        Text(favorites.isFavorite(video: video) ? "Saved" : "Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(YouTubeTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(YouTubeTheme.pill)
                    .cornerRadius(18)
                }

                // Download Pill (Privacy/Offline status)
                Button(action: {
                    UIPasteboard.general.string = "https://youtu.be/\(video.videoId)"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                        Text("Copy Link")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(YouTubeTheme.pill)
                    .cornerRadius(18)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
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
