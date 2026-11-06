import SwiftUI
import WebKit

public struct EmbeddedPlayerView: UIViewRepresentable {
    public let videoId: String

    public init(videoId: String) {
        self.videoId = videoId
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        // Inject ad-blocker & clean layout styles
        let script = """
        const style = document.createElement('style');
        style.innerHTML = `
            .ytp-pause-overlay, .ytp-watermark, .ytp-chrome-top,
            .ytp-show-cards-title, .ytp-ad-overlay-container,
            .ad-container, .video-ads, .ytp-ad-module, ytd-ad-slot-renderer { display: none !important; }
        `;
        document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false

        loadVideo(in: webView)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadVideo(in webView: WKWebView) {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: #000; overflow: hidden; }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
        </head>
        <body>
            <iframe src="https://www.youtube-nocookie.com/embed/\(videoId)?autoplay=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1" 
                    allow="autoplay; encrypted-media; picture-in-picture" 
                    allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
}
