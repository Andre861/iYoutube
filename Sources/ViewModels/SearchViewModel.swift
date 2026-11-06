import Foundation

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public var results: [Video] = []
    @Published public var isSearching: Bool = false
    @Published public var errorMessage: String? = nil

    private let service = InvidiousService.shared

    public init() {}

    public func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        do {
            let res = try await service.search(query: trimmed)
            self.results = res
        } catch {
            self.errorMessage = "Search failed: \(error.localizedDescription)"
        }
        isSearching = false
    }
}
