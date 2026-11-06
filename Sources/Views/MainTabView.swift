import SwiftUI

public struct MainTabView: View {
    @ObservedObject private var coordinator = PlayerCoordinator.shared
    @State private var selectedTab = 0

    public init() {
        // Authentic YouTube Dark TabBar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)]
        itemAppearance.selected.iconColor = UIColor.white
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Tab Bar Navigation
            TabView(selection: $selectedTab) {
                NavigationView {
                    HomeFeedView(onSelectVideo: { video in
                        coordinator.play(video: video)
                    })
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                NavigationView {
                    SearchView(onSelectVideo: { video in
                        coordinator.play(video: video)
                    })
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

                NavigationView {
                    FavoritesView(onSelectVideo: { video in
                        coordinator.play(video: video)
                    })
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Library", systemImage: "play.square.stack.fill")
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
            .accentColor(.white)

            // Docked Miniplayer above Tab Bar
            if coordinator.displayState == .miniplayer, let video = coordinator.currentVideo {
                MiniPlayerView(video: video)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 54)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(50)
            }

            // Expanded / Fullscreen Watch Player
            if (coordinator.displayState == .expanded || coordinator.displayState == .fullscreen),
               let video = coordinator.currentVideo {
                VideoPlayerView(video: video)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
        }
        .background(YouTubeTheme.background)
        .ignoresSafeArea(.keyboard)
    }
}
