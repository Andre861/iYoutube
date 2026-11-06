import SwiftUI

public struct MainTabView: View {
    @State private var selectedVideo: Video?
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeFeedView(onSelectVideo: { video in
                    selectedVideo = video
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Trending", systemImage: "flame.fill")
            }
            .tag(0)

            NavigationView {
                SearchView(onSelectVideo: { video in
                    selectedVideo = video
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            NavigationView {
                FavoritesView(onSelectVideo: { video in
                    selectedVideo = video
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Library", systemImage: "bookmark.fill")
            }
            .tag(2)

            NavigationView {
                SettingsView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .sheet(item: $selectedVideo) { video in
            VideoPlayerView(video: video, onClose: {
                selectedVideo = nil
            })
        }
    }
}
