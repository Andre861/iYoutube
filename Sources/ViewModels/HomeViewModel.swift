import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var videos: [Video] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var selectedTopic: String = "All"

    private let service = InvidiousService.shared

    public init() {
        Task {
            await loadFeed(topic: "All")
        }
    }

    public func loadFeed(topic: String? = nil) async {
        let topicToLoad = topic ?? selectedTopic
        self.selectedTopic = topicToLoad
        isLoading = true
        errorMessage = nil

        do {
            let fetched: [Video]
            switch topicToLoad {
            case "All", "Trending":
                fetched = try await service.fetchTrending()
            case "Music":
                fetched = try await service.fetchTrending(type: "music")
            case "Gaming":
                fetched = try await service.fetchTrending(type: "gaming")
            case "News":
                fetched = try await service.fetchTrending(type: "news")
            default:
                fetched = try await service.search(query: topicToLoad)
            }
            self.videos = fetched
        } catch {
            self.errorMessage = "Failed to load \(topicToLoad): \(error.localizedDescription)"
        }
        isLoading = false
    }
}
