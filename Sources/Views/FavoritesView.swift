import SwiftUI

public struct FavoritesView: View {
    @ObservedObject private var favorites = FavoritesManager.shared
    public let onSelectVideo: (Video) -> Void

    @State private var selectedTab = 0

    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 550), spacing: 20)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(YouTubeTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(YouTubeTheme.background)

            // Custom Segmented Filter
            HStack(spacing: 8) {
                segmentButton(title: "Bookmarks (\(favorites.favorites.count))", tag: 0)
                segmentButton(title: "History (\(favorites.history.count))", tag: 1)
                segmentButton(title: "Subscriptions (\(favorites.subscriptions.count))", tag: 2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(YouTubeTheme.background)

            Divider()
                .background(YouTubeTheme.border)

            ScrollView {
                if selectedTab == 0 {
                    // Bookmarks
                    if favorites.favorites.isEmpty {
                        emptyStateView(
                            icon: "bookmark",
                            title: "No Bookmarked Videos",
                            message: "Tap the bookmark icon on any video to save it here for later."
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(favorites.favorites) { video in
                                VideoCardView(video: video, onSelect: onSelectVideo)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 80)
                    }
                } else if selectedTab == 1 {
                    // History
                    if favorites.history.isEmpty {
                        emptyStateView(
                            icon: "clock",
                            title: "Watch History is Empty",
                            message: "Videos you watch will appear here automatically."
                        )
                    } else {
                        HStack {
                            Spacer()
                            Button("Clear History") {
                                favorites.clearHistory()
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(YouTubeTheme.red)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                        }

                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(favorites.history) { video in
                                VideoCardView(video: video, onSelect: onSelectVideo)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                } else {
                    // Subscriptions
                    if favorites.subscriptions.isEmpty {
                        emptyStateView(
                            icon: "play.rectangle.on.rectangle",
                            title: "No Subscriptions Yet",
                            message: "Subscribe to channels from any video watch page to see them here."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites.subscriptions) { sub in
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(YouTubeTheme.red)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(sub.author.prefix(1).uppercased())
                                                .font(.headline.bold())
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sub.author)
                                            .font(.headline)
                                            .foregroundColor(YouTubeTheme.textPrimary)
                                        if let count = sub.subCountText {
                                            Text(count)
                                                .font(.caption)
                                                .foregroundColor(YouTubeTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        favorites.toggleSubscription(author: sub.author, authorId: sub.authorId)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "bell.fill")
                                            Text("Subscribed")
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(YouTubeTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(YouTubeTheme.surface)
                                        .cornerRadius(16)
                                    }
                                }
                                .padding()
                                .background(YouTubeTheme.card)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(YouTubeTheme.background)
        }
        .background(YouTubeTheme.background)
        .navigationBarHidden(true)
    }

    private func segmentButton(title: String, tag: Int) -> some View {
        let isSelected = selectedTab == tag
        return Button(action: {
            selectedTab = tag
        }) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : YouTubeTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? YouTubeTheme.pillSelected : YouTubeTheme.pill)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(YouTubeTheme.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundColor(YouTubeTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(YouTubeTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
    }
}
