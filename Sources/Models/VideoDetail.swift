import Foundation

public struct VideoDetail: Codable {
    public let title: String
    public let videoId: String
    public let description: String?
    public let author: String
    public let authorId: String?
    public let authorThumbnails: [Thumbnail]?
    public let subCountText: String?
    public let lengthSeconds: Int?
    public let viewCount: Int?
    public let likeCount: Int?
    public let formatStreams: [StreamFormat]?
    public let adaptiveFormats: [StreamFormat]?
    public let hlsUrl: String?

    public var bestPlaybackURL: URL? {
        // 1. Prefer direct muxed 720p or 480p or 360p MP4 format stream
        if let streams = formatStreams, !streams.isEmpty {
            if let p720 = streams.first(where: { $0.qualityLabel?.contains("720") == true }) {
                return URL(string: p720.url)
            }
            if let p480 = streams.first(where: { $0.qualityLabel?.contains("480") == true }) {
                return URL(string: p480.url)
            }
            if let p360 = streams.first(where: { $0.qualityLabel?.contains("360") == true }) {
                return URL(string: p360.url)
            }
            if let first = streams.first {
                return URL(string: first.url)
            }
        }
        // 2. Fallback to HLS playlist if present
        if let hls = hlsUrl, let url = URL(string: hls) {
            return url
        }
        return nil
    }
}

public struct StreamFormat: Codable, Identifiable {
    public var id: String { url }
    public let url: String
    public let quality: String?
    public let qualityLabel: String?
    public let resolution: String?
    public let container: String?
    public let encoding: String?
    public let fps: Int?
    public let size: String?
}
