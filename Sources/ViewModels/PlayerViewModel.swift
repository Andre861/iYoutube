import Foundation
import AVKit
import WebKit
import Combine

public enum PlaybackMode: String {
    case native = "Native"
    case web = "Web"
}

@MainActor
public final class PlayerViewModel: ObservableObject {
    @Published public var player: AVPlayer?
    @Published public var videoDetail: VideoDetail?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var selectedQuality: String = "Auto"
    @Published public var availableFormats: [StreamFormat] = []
    @Published public var playbackMode: PlaybackMode = .native
    @Published public var isPlaying: Bool = true
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var playbackRate: Float = 1.0

    // Persistent WebKit instance so rotation or UI updates NEVER reload the web player
    public private(set) var webView: WKWebView?
    public private(set) var loadedWebVideoId: String? = nil

    private let service = InvidiousService.shared
    private var statusObservation: AnyCancellable?
    private var timeObserverToken: Any?

    public init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    public func getOrCreateWebView(for videoId: String) -> WKWebView {
        if let existing = webView, loadedWebVideoId == videoId {
            return existing
        }

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true
        }

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

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.isOpaque = false
        wv.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 15_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"

        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html {
                    margin: 0; padding: 0; width: 100%; height: 100%;
                    background-color: #000; overflow: hidden;
                    display: flex; justify-content: center; align-items: center;
                }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
        </head>
        <body>
            <iframe src="https://www.youtube-nocookie.com/embed/\(videoId)?autoplay=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1&fs=1" 
                    allow="autoplay; encrypted-media; picture-in-picture; fullscreen" 
                    allowfullscreen="true">
            </iframe>
        </body>
        </html>
        """
        wv.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.youtube-nocookie.com"))

        self.webView = wv
        self.loadedWebVideoId = videoId
        return wv
    }

    public func loadVideo(video: Video) async {
        isLoading = true
        errorMessage = nil
        removeTimeObserver()
        player?.pause()
        player = nil

        // Clear webview if switching to a different video
        if loadedWebVideoId != video.videoId {
            webView = nil
            loadedWebVideoId = nil
        }

        playbackMode = .native
        isPlaying = true
        currentTime = 0.0
        duration = Double(video.lengthSeconds ?? 0)

        FavoritesManager.shared.addToHistory(video: video)

        do {
            let detail = try await service.fetchVideoDetail(videoId: video.videoId)
            self.videoDetail = detail

            var formats = detail.formatStreams ?? []
            if let hls = detail.hlsUrl, !hls.isEmpty {
                let hlsFormat = StreamFormat(
                    url: hls,
                    quality: "Auto",
                    qualityLabel: "Auto (HLS)",
                    resolution: "Auto",
                    container: "m3u8",
                    encoding: "h264",
                    fps: 30,
                    size: nil
                )
                formats.insert(hlsFormat, at: 0)
            }
            self.availableFormats = formats

            if let playbackURL = detail.bestPlaybackURL {
                let playerItem = AVPlayerItem(url: playbackURL)
                let avPlayer = AVPlayer(playerItem: playerItem)
                self.player = avPlayer
                
                observePlayerItem(playerItem)
                setupTimeObserver(for: avPlayer)
                avPlayer.play()
                self.isPlaying = true
            } else {
                self.playbackMode = .web
                _ = getOrCreateWebView(for: video.videoId)
            }
        } catch {
            print("Invidious stream fetch failed: \(error.localizedDescription). Falling back to Web engine.")
            self.playbackMode = .web
            _ = getOrCreateWebView(for: video.videoId)
        }
        isLoading = false
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        statusObservation?.cancel()
        statusObservation = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .failed {
                    print("Native player item failed. Switching to Web fallback.")
                    self.player?.pause()
                    self.player = nil
                    self.playbackMode = .web
                    if let vid = self.videoDetail?.videoId {
                        _ = self.getOrCreateWebView(for: vid)
                    }
                }
            }
    }

    private func setupTimeObserver(for avPlayer: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let currentItem = avPlayer.currentItem, currentItem.duration.seconds > 0 {
                self.duration = currentItem.duration.seconds
            }
            self.isPlaying = (avPlayer.timeControlStatus == .playing)
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let avPlayer = player {
            avPlayer.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    public func togglePlayPause() {
        if playbackMode == .native, let avPlayer = player {
            if avPlayer.timeControlStatus == .playing {
                avPlayer.pause()
                isPlaying = false
            } else {
                avPlayer.play()
                isPlaying = true
            }
        } else {
            isPlaying.toggle()
        }
    }

    public func seek(by seconds: Double) {
        guard let avPlayer = player else { return }
        let target = max(0, min(currentTime + seconds, duration))
        let targetCMTime = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer.seek(to: targetCMTime)
    }

    public func setSpeed(_ rate: Float) {
        self.playbackRate = rate
        player?.rate = rate
    }

    public func togglePlaybackMode() {
        if playbackMode == .native {
            player?.pause()
            playbackMode = .web
            if let vid = videoDetail?.videoId {
                _ = getOrCreateWebView(for: vid)
            }
        } else {
            playbackMode = .native
            if let playbackURL = videoDetail?.bestPlaybackURL {
                let item = AVPlayerItem(url: playbackURL)
                let avPlayer = AVPlayer(playerItem: item)
                self.player = avPlayer
                observePlayerItem(item)
                setupTimeObserver(for: avPlayer)
                avPlayer.play()
                self.isPlaying = true
            }
        }
    }

    public func switchFormat(to format: StreamFormat) {
        guard let url = URL(string: format.url) else { return }
        let time = player?.currentTime() ?? .zero
        let wasPlaying = player?.timeControlStatus == .playing

        let item = AVPlayerItem(url: url)
        observePlayerItem(item)
        player?.replaceCurrentItem(with: item)
        player?.seek(to: time)
        if wasPlaying {
            player?.play()
        }
        self.selectedQuality = format.qualityLabel ?? "Custom"
        self.playbackMode = .native
    }

    public func stop() {
        removeTimeObserver()
        statusObservation?.cancel()
        statusObservation = nil
        player?.pause()
        player = nil
        webView?.loadHTMLString("", baseURL: nil)
        webView = nil
        loadedWebVideoId = nil
        isPlaying = false
    }
}
