import SwiftUI
import WebKit

public struct EmbeddedPlayerView: UIViewRepresentable {
    public let videoId: String
    @ObservedObject private var viewModel: PlayerViewModel

    public init(videoId: String, viewModel: PlayerViewModel) {
        self.videoId = videoId
        self.viewModel = viewModel
    }

    public func makeUIView(context: Context) -> WKWebView {
        return viewModel.getOrCreateWebView(for: videoId)
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Persistent instance in PlayerViewModel manages playback lifecycle without reload
    }
}
