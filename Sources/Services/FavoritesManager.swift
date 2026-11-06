import Foundation

public struct ChannelSubscription: Codable, Identifiable, Equatable {
    public var id: String { authorId.isEmpty ? author : authorId }
    public let author: String
    public let authorId: String
    public let subCountText: String?
    public let avatarUrl: String?

    public init(author: String, authorId: String = "", subCountText: String? = nil, avatarUrl: String? = nil) {
        self.author = author
        self.authorId = authorId
        self.subCountText = subCountText
        self.avatarUrl = avatarUrl
    }
}

public final class FavoritesManager: ObservableObject {
    public static let shared = FavoritesManager()

    @Published public var favorites: [Video] = []
    @Published public var history: [Video] = []
    @Published public var subscriptions: [ChannelSubscription] = []

    private let favoritesKey = "user_favorite_videos"
    private let historyKey = "user_watch_history"
    private let subscriptionsKey = "user_channel_subscriptions"

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

    public func isSubscribed(author: String, authorId: String? = nil) -> Bool {
        subscriptions.contains { sub in
            if let id = authorId, !id.isEmpty, !sub.authorId.isEmpty {
                return sub.authorId == id
            }
            return sub.author.lowercased() == author.lowercased()
        }
    }

    public func toggleSubscription(author: String, authorId: String? = nil, subCountText: String? = nil, avatarUrl: String? = nil) {
        if isSubscribed(author: author, authorId: authorId) {
            subscriptions.removeAll { sub in
                if let id = authorId, !id.isEmpty, !sub.authorId.isEmpty {
                    return sub.authorId == id
                }
                return sub.author.lowercased() == author.lowercased()
            }
        } else {
            let sub = ChannelSubscription(author: author, authorId: authorId ?? "", subCountText: subCountText, avatarUrl: avatarUrl)
            subscriptions.insert(sub, at: 0)
        }
        saveSubscriptions()
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
        if let subData = UserDefaults.standard.data(forKey: subscriptionsKey),
           let decoded = try? JSONDecoder().decode([ChannelSubscription].self, from: subData) {
            self.subscriptions = decoded
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

    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: subscriptionsKey)
        }
    }
}
