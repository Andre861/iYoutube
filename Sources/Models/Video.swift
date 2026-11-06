import Foundation

public struct Video: Identifiable, Codable, Equatable, Hashable {
    public var id: String { videoId }
    public let videoId: String
    public let title: String
    public let author: String
    public let authorId: String?
    public let authorUrl: String?
    public let publishedText: String?
    public let viewCount: Int?
    public let lengthSeconds: Int?
    public let videoThumbnails: [Thumbnail]?

    public init(
        videoId: String,
        title: String,
        author: String,
        authorId: String? = nil,
        authorUrl: String? = nil,
        publishedText: String? = nil,
        viewCount: Int? = nil,
        lengthSeconds: Int? = nil,
        videoThumbnails: [Thumbnail]? = nil
    ) {
        self.videoId = videoId
        self.title = title
        self.author = author
        self.authorId = authorId
        self.authorUrl = authorUrl
        self.publishedText = publishedText
        self.viewCount = viewCount
        self.lengthSeconds = lengthSeconds
        self.videoThumbnails = videoThumbnails
    }

    public var bestThumbnailURL: URL? {
        // Look for medium or high quality thumbnail, or direct fallback to standard YouTube thumbnail
        if let thumbs = videoThumbnails, !thumbs.isEmpty {
            if let medium = thumbs.first(where: { $0.quality == "medium" || $0.quality == "high" }) {
                return URL(string: medium.url)
            }
            if let first = thumbs.first {
                return URL(string: first.url)
            }
        }
        return URL(string: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg")
    }

    public var formattedDuration: String {
        guard let seconds = lengthSeconds, seconds > 0 else { return "" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    public var formattedViews: String {
        guard let count = viewCount else { return "" }
        if count >= 1_000_000 {
            return String(format: "%.1fM views", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK views", Double(count) / 1_000.0)
        } else {
            return "\(count) views"
        }
    }
}

public struct Thumbnail: Codable, Equatable, Hashable {
    public let quality: String?
    public let url: String
    public let width: Int?
    public let height: Int?
}
