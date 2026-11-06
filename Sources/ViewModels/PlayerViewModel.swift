import Foundation
import AVKit
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

    private let service = InvidiousService.shared
    private var statusObservation: AnyCancellable?

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

    public func loadVideo(video: Video) async {
        isLoading = true
        errorMessage = nil
        player?.pause()
        player = nil
        playbackMode = .native

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
                
                // Monitor for playback failures (such as Google 403 bot-check blocks)
                observePlayerItem(playerItem)
                avPlayer.play()
            } else {
                // If Invidious has no streams, seamlessly fallback to web player
                self.playbackMode = .web
            }
        } catch {
            print("Invidious stream fetch failed: \(error.localizedDescription). Falling back to Web engine.")
            // Automatically switch to Web engine so video plays without interruption
            self.playbackMode = .web
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
                }
            }
    }

    public func togglePlaybackMode() {
        if playbackMode == .native {
            player?.pause()
            playbackMode = .web
        } else {
            playbackMode = .native
            if let playbackURL = videoDetail?.bestPlaybackURL {
                let item = AVPlayerItem(url: playbackURL)
                self.player = AVPlayer(playerItem: item)
                observePlayerItem(item)
                self.player?.play()
            }
        }
    }

    public func switchFormat(to format: StreamFormat) {
        guard let url = URL(string: format.url) else { return }
        let currentTime = player?.currentTime() ?? .zero
        let wasPlaying = player?.timeControlStatus == .playing

        let item = AVPlayerItem(url: url)
        observePlayerItem(item)
        player?.replaceCurrentItem(with: item)
        player?.seek(to: currentTime)
        if wasPlaying {
            player?.play()
        }
        self.selectedQuality = format.qualityLabel ?? "Custom"
        self.playbackMode = .native
    }

    public func stop() {
        statusObservation?.cancel()
        statusObservation = nil
        player?.pause()
        player = nil
    }
}
