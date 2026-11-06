import SwiftUI

public struct ChannelBarView: View {
    public let author: String
    public let authorId: String?
    public let subCountText: String?
    public let authorThumbnails: [Thumbnail]?

    @ObservedObject private var favorites = FavoritesManager.shared

    public init(author: String, authorId: String? = nil, subCountText: String? = nil, authorThumbnails: [Thumbnail]? = nil) {
        self.author = author
        self.authorId = authorId
        self.subCountText = subCountText
        self.authorThumbnails = authorThumbnails
    }

    public var body: some View {
        let isSubbed = favorites.isSubscribed(author: author, authorId: authorId)

        HStack(spacing: 12) {
            // Circular Channel Avatar
            ZStack {
                if let thumb = authorThumbnails?.first, let url = URL(string: thumb.url) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        fallbackAvatar
                    }
                } else {
                    fallbackAvatar
                }
            }

            // Channel Title & Subscriber Count
            VStack(alignment: .leading, spacing: 2) {
                Text(author)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .lineLimit(1)

                if let count = subCountText, !count.isEmpty {
                    Text(count)
                        .font(.system(size: 12))
                        .foregroundColor(YouTubeTheme.textSecondary)
                }
            }

            Spacer()

            // Subscribe Button
            Button(action: {
                favorites.toggleSubscription(
                    author: author,
                    authorId: authorId,
                    subCountText: subCountText,
                    avatarUrl: authorThumbnails?.first?.url
                )
            }) {
                HStack(spacing: 4) {
                    if isSubbed {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                        Text("Subscribed")
                    } else {
                        Text("Subscribe")
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSubbed ? YouTubeTheme.textPrimary : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSubbed ? YouTubeTheme.surface : Color.white)
                .cornerRadius(18)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var fallbackAvatar: some View {
        let colors: [Color] = [.red, .blue, .purple, .orange, .green, .teal]
        let colorIndex = abs(author.hashValue) % colors.count
        return Circle()
            .fill(colors[colorIndex].opacity(0.85))
            .frame(width: 40, height: 40)
            .overlay(
                Text(author.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}
