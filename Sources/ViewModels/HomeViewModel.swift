import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var videos: [Video] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let service = InvidiousService.shared

    public init() {
        Task {
            await loadTrending()
        }
    }

    public func loadTrending() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchTrending()
            self.videos = fetched
        } catch {
            self.errorMessage = "Failed to load trending: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
