import SwiftUI

public struct MiniPlayerView: View {
    public let video: Video
    @ObservedObject private var coordinator = PlayerCoordinator.shared
    @ObservedObject private var viewModel: PlayerViewModel

    public init(video: Video) {
        self.video = video
        self.viewModel = PlayerCoordinator.shared.viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Thin Red Progress Bar on Top of Miniplayer
            GeometryReader { geo in
                let progress = viewModel.duration > 0 ? (viewModel.currentTime / viewModel.duration) : 0.0
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(YouTubeTheme.border)
                        .frame(height: 2)

                    Rectangle()
                        .fill(YouTubeTheme.red)
                        .frame(width: geo.size.width * CGFloat(min(max(progress, 0.0), 1.0)), height: 2)
                }
            }
            .frame(height: 2)

            // Main Miniplayer Content Row
            HStack(spacing: 12) {
                // Video Preview Thumbnail
                ZStack {
                    CachedAsyncImage(url: video.bestThumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(YouTubeTheme.card)
                    }
                }
                .frame(width: 88, height: 50)
                .cornerRadius(6)

                // Title and Channel Name
                VStack(alignment: .leading, spacing: 3) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(YouTubeTheme.textPrimary)
                        .lineLimit(1)

                    Text(video.author)
                        .font(.system(size: 11))
                        .foregroundColor(YouTubeTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Play / Pause Button
                Button(action: {
                    coordinator.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(YouTubeTheme.textPrimary)
                        .frame(width: 36, height: 36)
                }

                // Close Button
                Button(action: {
                    coordinator.close()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(YouTubeTheme.textSecondary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(YouTubeTheme.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(YouTubeTheme.border, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.expand()
        }
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.height < -20 {
                        coordinator.expand()
                    } else if value.translation.width > 50 || value.translation.height > 20 {
                        coordinator.close()
                    }
                }
        )
    }
}
