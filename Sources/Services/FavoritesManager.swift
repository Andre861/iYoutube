import Foundation

public final class FavoritesManager: ObservableObject {
    public static let shared = FavoritesManager()

    @Published public var favorites: [Video] = []
    @Published public var history: [Video] = []

    private let favoritesKey = "user_favorite_videos"
    private let historyKey = "user_watch_history"

    public init() {
        loadData()
    }

    public func toggleFavorite(video: Video) {
        if isFavorite(video: video) {
            favorites.removeAll { $0.videoId == video.videoId }
        } else {
            favorites.insert(video, at: 0)
        }
        saveFavorites()
    }

    public func isFavorite(video: Video) -> Bool {
        favorites.contains { $0.videoId == video.videoId }
    }

    public func addToHistory(video: Video) {
        history.removeAll { $0.videoId == video.videoId }
        history.insert(video, at: 0)
        if history.count > 100 {
            history.removeLast()
        }
        saveHistory()
    }

    public func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func loadData() {
        if let favData = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Video].self, from: favData) {
            self.favorites = decoded
        }
        if let histData = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([Video].self, from: histData) {
            self.history = decoded
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
}
