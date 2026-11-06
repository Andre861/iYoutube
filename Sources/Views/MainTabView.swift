import SwiftUI

public struct MainTabView: View {
    @ObservedObject private var coordinator = PlayerCoordinator.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    public init() {
        configureTabBarAppearance()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
                : UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.0)
        }

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
                : UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0)
        }
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
                    : UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0)
            }
        ]

        itemAppearance.selected.iconColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white : UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
        }
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.white : UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
            }
        ]

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
                HomeFeedView(onSelectVideo: { video in
                    coordinator.play(video: video)
                })
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                SearchView(onSelectVideo: { video in
                    coordinator.play(video: video)
                })
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

                FavoritesView(onSelectVideo: { video in
                    coordinator.play(video: video)
                })
                .tabItem {
                    Label("Library", systemImage: "play.square.stack.fill")
                }
                .tag(2)

                SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
            }
            .accentColor(themeManager.selectedTheme == .light ? .black : .white)

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .background(YouTubeTheme.background)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        .ignoresSafeArea(.keyboard)
    }
}
