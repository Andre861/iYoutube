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
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 25
        self.session = URLSession(configuration: config)

        // Reset if saved instance was one of the outdated broken ones
        let saved = UserDefaults.standard.string(forKey: "invidious_instance")
        if let s = saved, !s.contains("tux.pizza") && !s.contains("priv.au") && !s.contains("drgns.space") {
            self.currentInstance = s
        } else {
            let def = InvidiousInstance.defaultInstances[0].url
            self.currentInstance = def
            UserDefaults.standard.set(def, forKey: "invidious_instance")
        }
    }

    public func fetchTrending(type: String? = nil) async throws -> [Video] {
        return try await performWithFailover { baseURL in
            var path = "\(baseURL)/api/v1/trending"
            if let type = type, !type.isEmpty {
                path += "?type=\(type)"
            } else {
                // Try popular first (returns 40 curated videos), then fallback to trending
                if let popularUrl = URL(string: "\(baseURL)/api/v1/popular") {
                    do {
                        let (data, response) = try await self.session.data(from: popularUrl)
                        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                            let decoded = try JSONDecoder().decode([Video].self, from: data)
                            if !decoded.isEmpty { return decoded }
                        }
                    } catch {
                        // Fallback to trending
                    }
                }
            }

            guard let url = URL(string: path) else {
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

    private func performWithFailover<T>(_ block: @escaping (String) async throws -> T) async throws -> T {
        // Try current primary instance
        do {
            return try await block(currentInstance)
        } catch {
            print("Primary instance \(currentInstance) failed: \(error.localizedDescription). Trying fallbacks...")
        }

        // Try fallbacks
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
