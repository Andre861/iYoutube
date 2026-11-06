import SwiftUI

public struct FavoritesView: View {
    @ObservedObject private var favorites = FavoritesManager.shared
    public let onSelectVideo: (Video) -> Void

    @State private var selectedTab = 0

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 450), spacing: 18)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("Library", selection: $selectedTab) {
                Text("Bookmarks (\(favorites.favorites.count))").tag(0)
                Text("History (\(favorites.history.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                if selectedTab == 0 {
                    if favorites.favorites.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Bookmarked Videos")
                                .font(.headline)
                            Text("Tap the bookmark icon on any video to save it here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(favorites.favorites) { video in
                                VideoCardView(video: video, onSelect: onSelectVideo)
                            }
                        }
                        .padding()
                    }
                } else {
                    if favorites.history.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Watch History is Empty")
                                .font(.headline)
                            Text("Videos you watch will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 80)
                    } else {
                        HStack {
                            Spacer()
                            Button("Clear History") {
                                favorites.clearHistory()
                            }
                            .foregroundColor(.red)
                            .padding(.trailing)
                        }

                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(favorites.history) { video in
                                VideoCardView(video: video, onSelect: onSelectVideo)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Library")
    }
}
