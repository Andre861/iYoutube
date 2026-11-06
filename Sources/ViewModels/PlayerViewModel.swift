import Foundation
import AVKit

@MainActor
public final class PlayerViewModel: ObservableObject {
    @Published public var player: AVPlayer?
    @Published public var videoDetail: VideoDetail?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var selectedQuality: String = "Auto"
    @Published public var availableFormats: [StreamFormat] = []

    private let service = InvidiousService.shared

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
                avPlayer.play()
            } else {
                self.errorMessage = "No playable video streams found for this video."
            }
        } catch {
            self.errorMessage = "Failed to load video: \(error.localizedDescription)"
        }
        isLoading = false
    }

    public func switchFormat(to format: StreamFormat) {
        guard let url = URL(string: format.url) else { return }
        let currentTime = player?.currentTime() ?? .zero
        let wasPlaying = player?.timeControlStatus == .playing

        let item = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: item)
        player?.seek(to: currentTime)
        if wasPlaying {
            player?.play()
        }
        self.selectedQuality = format.qualityLabel ?? "Custom"
    }

    public func stop() {
        player?.pause()
        player = nil
    }
}
