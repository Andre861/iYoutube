import SwiftUI

public struct YouTubeHeaderView: View {
    public let onSearchTap: (() -> Void)?
    public let onSettingsTap: (() -> Void)?

    @ObservedObject private var themeManager = ThemeManager.shared

    public init(onSearchTap: (() -> Void)? = nil, onSettingsTap: (() -> Void)? = nil) {
        self.onSearchTap = onSearchTap
        self.onSettingsTap = onSettingsTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // YouTube Logo Badge & Wordmark
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(YouTubeTheme.red)
                        .frame(width: 30, height: 21)

                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                }

                Text("iYoutube")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .tracking(-0.5)
            }

            Spacer()

            // Header Quick Action Icons
            HStack(spacing: 16) {
                // Quick Theme Toggle (Moon / Sun)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.toggleTheme()
                    }
                }) {
                    Image(systemName: themeManager.selectedTheme == .light ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 17))
                        .foregroundColor(YouTubeTheme.textPrimary)
                }

                // Cast / AirPlay
                Button(action: {}) {
                    Image(systemName: "airplayvideo")
                        .font(.system(size: 17))
                        .foregroundColor(YouTubeTheme.textPrimary)
                }

                // Notification Bell
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 17))
                        .foregroundColor(YouTubeTheme.textPrimary)
                }

                // Search
                if let onSearch = onSearchTap {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17))
                            .foregroundColor(YouTubeTheme.textPrimary)
                    }
                }

                // Settings Avatar
                if let onSettings = onSettingsTap {
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17))
                            .foregroundColor(YouTubeTheme.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(YouTubeTheme.background)
    }
}
