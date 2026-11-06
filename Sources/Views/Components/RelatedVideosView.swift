import SwiftUI

public struct RelatedVideosView: View {
    public let videos: [Video]
    public let onSelectVideo: (Video) -> Void

    public init(videos: [Video], onSelectVideo: @escaping (Video) -> Void) {
        self.videos = videos
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Up Next")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(YouTubeTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            LazyVStack(spacing: 16) {
                ForEach(videos) { video in
                    Button(action: {
                        onSelectVideo(video)
                    }) {
                        HStack(alignment: .top, spacing: 12) {
                            // Thumbnail with duration
                            ZStack(alignment: .bottomTrailing) {
                                CachedAsyncImage(url: video.bestThumbnailURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: 140, height: 79)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .fill(YouTubeTheme.surface)
                                        .frame(width: 140, height: 79)
                                }
                                .cornerRadius(8)

                                if !video.formattedDuration.isEmpty {
                                    Text(video.formattedDuration)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.85))
                                        .cornerRadius(4)
                                        .padding(4)
                                }
                            }

                            // Metadata
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(YouTubeTheme.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Text(video.author)
                                    .font(.system(size: 11))
                                    .foregroundColor(YouTubeTheme.textSecondary)
                                    .lineLimit(1)

                                if !video.formattedViews.isEmpty {
                                    Text(video.formattedViews)
                                        .font(.system(size: 11))
                                        .foregroundColor(YouTubeTheme.textSecondary)
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
