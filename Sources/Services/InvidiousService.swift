import Foundation

public final class InvidiousService: ObservableObject {
    public static let shared = InvidiousService()

    @Published public var currentInstance: String {
        didSet {
            UserDefaults.standard.set(currentInstance, forKey: "invidious_instance")
        }
    }

    private let session: URLSession

    public init() {
        let saved = UserDefaults.standard.string(forKey: "invidious_instance")
        self.currentInstance = saved ?? InvidiousInstance.defaultInstances[0].url
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    public func fetchTrending() async throws -> [Video] {
        return try await performWithFailover { baseURL in
            guard let url = URL(string: "\(baseURL)/api/v1/trending?type=music,gaming,news,movies") ?? URL(string: "\(baseURL)/api/v1/trending") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await self.session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode([Video].self, from: data)
        }
    }

    public func search(query: String) async throws -> [Video] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        return try await performWithFailover { baseURL in
            guard let url = URL(string: "\(baseURL)/api/v1/search?q=\(encoded)&type=video") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await self.session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode([Video].self, from: data)
        }
    }

    public func fetchVideoDetail(videoId: String) async throws -> VideoDetail {
        return try await performWithFailover { baseURL in
            guard let url = URL(string: "\(baseURL)/api/v1/videos/\(videoId)") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await self.session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode(VideoDetail.self, from: data)
        }
    }

    // Attempt request on current instance; if it fails, try other available instances
    private func performWithFailover<T>(_ block: @escaping (String) async throws -> T) async throws -> T {
        // Try current instance first
        do {
            return try await block(currentInstance)
        } catch {
            print("Primary instance \(currentInstance) failed: \(error.localizedDescription). Trying fallbacks...")
        }

        // Try fallback instances
        for instance in InvidiousInstance.defaultInstances where instance.url != currentInstance {
            do {
                let result = try await block(instance.url)
                await MainActor.run {
                    self.currentInstance = instance.url
                }
                return result
            } catch {
                continue
            }
        }

        throw URLError(.cannotConnectToHost)
    }
}
