import SwiftUI
import AVKit

// Native AVPlayerViewController wrapper for full system controls & PiP
public struct CustomPlayerController: UIViewControllerRepresentable {
    public let player: AVPlayer

    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.updatesNowPlayingInfoCenter = true
        controller.showsPlaybackControls = true
        return controller
    }

    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != player {
            uiViewController.player = player
        }
    }
}

public struct VideoPlayerView: View {
    public let video: Video

    @ObservedObject private var coordinator = PlayerCoordinator.shared
    @ObservedObject private var viewModel: PlayerViewModel
    @ObservedObject private var favorites = FavoritesManager.shared

    @State private var showFullDescription: Bool = false
    @State private var showControlsOverlay: Bool = true
    @State private var hideTimer: DispatchWorkItem?
    
    // Double-tap Seek Animation States
    @State private var seekBackwardRipple: Bool = false
    @State private var seekForwardRipple: Bool = false

    public init(video: Video) {
        self.video = video
        self.viewModel = PlayerCoordinator.shared.viewModel
    }

    private var isFullScreen: Bool {
        coordinator.displayState == .fullscreen
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(isFullScreen ? UIColor.black : UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar (Only in normal expanded mode)
                if !isFullScreen {
                    normalTopBar
                }

                // Video Player Container
                videoContainer
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: isFullScreen ? .infinity : nil
                    )
                    .aspectRatio(isFullScreen ? nil : 16/9, contentMode: .fit)

                // Video Details & Up Next (Only in normal expanded mode)
                if !isFullScreen {
                    videoDetailsScrollArea
                }
            }
            .ignoresSafeArea(isFullScreen ? .all : [])

            // Floating HUD Overlay (Only in fullscreen mode)
            if isFullScreen {
                fullscreenOverlay
            }
        }
        .statusBar(hidden: isFullScreen)
    }

    // MARK: - Normal Mode Top Bar
    private var normalTopBar: some View {
        HStack(spacing: 12) {
            // Minimize Button (Swipe/Tap down to miniplayer dock)
            Button(action: {
                coordinator.minimize()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(YouTubeTheme.textPrimary)
                .padding(8)
            }

            Spacer()

            // True Fullscreen Button
            Button(action: {
                coordinator.enterFullscreen()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Fullscreen")
                }
                .font(.caption.bold())
                .foregroundColor(YouTubeTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(YouTubeTheme.pill)
                .cornerRadius(8)
            }

            // Playback Speed Menu
            Menu {
                ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], id: \.self) { rate in
                    Button("\(String(format: "%.2fx", rate))") {
                        viewModel.setSpeed(Float(rate))
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "gauge")
                    Text("\(String(format: "%.1fx", viewModel.playbackRate))")
                }
                .font(.caption.bold())
                .foregroundColor(YouTubeTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(YouTubeTheme.pill)
                .cornerRadius(8)
            }

            // Engine Toggle
            Button(action: {
                viewModel.togglePlaybackMode()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.playbackMode == .native ? "play.circle.fill" : "globe")
                    Text(viewModel.playbackMode == .native ? "Native" : "Web")
                }
                .font(.caption.bold())
                .foregroundColor(YouTubeTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(YouTubeTheme.pill)
                .cornerRadius(8)
            }

            // Quality Menu (Native only)
            if viewModel.playbackMode == .native && !viewModel.availableFormats.isEmpty {
                Menu {
                    ForEach(viewModel.availableFormats) { format in
                        Button(format.qualityLabel ?? format.quality ?? "Format") {
                            viewModel.switchFormat(to: format)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text(viewModel.selectedQuality)
                    }
                    .font(.caption.bold())
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(YouTubeTheme.pill)
                    .cornerRadius(8)
                }
            }

            // Dismiss Entire Player
            Button(action: {
                coordinator.close()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(YouTubeTheme.textSecondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(YouTubeTheme.background)
    }

    // MARK: - Video Container with Gestures
    private var videoContainer: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            // Video Engine
            if viewModel.playbackMode == .web {
                EmbeddedPlayerView(videoId: video.videoId)
            } else if let player = viewModel.player {
                CustomPlayerController(player: player)
            } else if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: YouTubeTheme.red))
                        .scaleEffect(1.5)
                    Text("Loading Stream...")
                        .foregroundColor(.white)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(YouTubeTheme.red)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Switch to Web Player") {
                        viewModel.playbackMode = .web
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(YouTubeTheme.red)
                }
            }

            // Double-tap Seek Gestures Overlays
            HStack(spacing: 0) {
                // Left 40% area: Double-tap back 10s
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        triggerSeekBackward()
                    }

                // Middle 20% area
                Color.clear
                    .contentShape(Rectangle())

                // Right 40% area: Double-tap forward 10s
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        triggerSeekForward()
                    }
            }

            // Animated Seek Ripples
            if seekBackwardRipple {
                HStack {
                    VStack(spacing: 6) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 32, weight: .bold))
                        Text("10 seconds")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(.leading, 30)

                    Spacer()
                }
                .transition(.opacity)
            }

            if seekForwardRipple {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 32, weight: .bold))
                        Text("10 seconds")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(.trailing, 30)
                }
                .transition(.opacity)
            }

            // On-player Fullscreen Toggle (Normal mode)
            if !isFullScreen {
                Button(action: {
                    coordinator.enterFullscreen()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(10)
            }
        }
    }

    // MARK: - Fullscreen Overlay HUD
    private var fullscreenOverlay: some View {
        VStack {
            if showControlsOverlay {
                HStack(spacing: 10) {
                    // Exit Fullscreen
                    Button(action: {
                        coordinator.exitFullscreen()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Exit Fullscreen")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                    }

                    Spacer()

                    // Playback Speed
                    Menu {
                        ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], id: \.self) { rate in
                            Button("\(String(format: "%.2fx", rate))") {
                                viewModel.setSpeed(Float(rate))
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge")
                            Text("\(String(format: "%.1fx", viewModel.playbackRate))")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                    }

                    // Engine Toggle in Fullscreen
                    Button(action: {
                        viewModel.togglePlaybackMode()
                        resetAutoHideTimer()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.playbackMode == .native ? "play.circle.fill" : "globe")
                            Text(viewModel.playbackMode == .native ? "Native" : "Web")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                    }

                    // Quality Menu (Native only)
                    if viewModel.playbackMode == .native && !viewModel.availableFormats.isEmpty {
                        Menu {
                            ForEach(viewModel.availableFormats) { format in
                                Button(format.qualityLabel ?? format.quality ?? "Format") {
                                    viewModel.switchFormat(to: format)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text(viewModel.selectedQuality)
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(20)
                        }
                    }

                    // Hide HUD button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showControlsOverlay = false
                        }
                    }) {
                        Image(systemName: "eye.slash")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Circle())
                    }

                    // Close Video
                    Button(action: {
                        coordinator.close()
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .transition(.opacity)
            } else {
                // Minimized subtle corner controls
                HStack(spacing: 8) {
                    Button(action: {
                        coordinator.exitFullscreen()
                    }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showControlsOverlay = true
                            resetAutoHideTimer()
                        }
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .transition(.opacity)
            }

            Spacer()
        }
    }

    // MARK: - Video Details & Up Next Scroll Area
    private var videoDetailsScrollArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Video Title
                Text(video.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(YouTubeTheme.textPrimary)
                    .lineLimit(3)

                // Views & Published Info
                HStack(spacing: 8) {
                    if let views = video.viewCount {
                        Text("\(views.formatted()) views")
                            .font(.system(size: 12))
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }

                    if let published = video.publishedText, !published.isEmpty {
                        Text("•")
                            .foregroundColor(YouTubeTheme.textSecondary)
                        Text(published)
                            .font(.system(size: 12))
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }

                    Spacer()
                }

                // Action Buttons Bar (Like, Dislike, Share, Save)
                VideoActionButtonsView(video: video, videoDetail: viewModel.videoDetail)

                Divider()
                    .background(YouTubeTheme.border)

                // Channel Info & Subscribe Bar
                ChannelBarView(
                    author: video.author,
                    authorId: video.authorId,
                    subCountText: viewModel.videoDetail?.subCountText,
                    authorThumbnails: viewModel.videoDetail?.authorThumbnails
                )

                Divider()
                    .background(YouTubeTheme.border)

                // Expandable Description Box
                if let detail = viewModel.videoDetail, let desc = detail.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(YouTubeTheme.textSecondary)

                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(YouTubeTheme.textPrimary)
                            .lineLimit(showFullDescription ? nil : 4)

                        Button(showFullDescription ? "Show Less" : "Show More") {
                            showFullDescription.toggle()
                        }
                        .font(.caption.bold())
                        .foregroundColor(YouTubeTheme.red)
                    }
                    .padding(12)
                    .background(YouTubeTheme.surface)
                    .cornerRadius(10)
                }

                // "Up Next" Related Videos List
                if let recommended = viewModel.videoDetail?.recommendedVideos, !recommended.isEmpty {
                    RelatedVideosView(videos: recommended) { selectedRecommended in
                        coordinator.play(video: selectedRecommended)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .background(YouTubeTheme.background)
    }

    // MARK: - Gesture Helpers
    private func triggerSeekBackward() {
        viewModel.seek(by: -10)
        withAnimation {
            seekBackwardRipple = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation {
                seekBackwardRipple = false
            }
        }
    }

    private func triggerSeekForward() {
        viewModel.seek(by: 10)
        withAnimation {
            seekForwardRipple = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation {
                seekForwardRipple = false
            }
        }
    }

    private func resetAutoHideTimer() {
        hideTimer?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                showControlsOverlay = false
            }
        }
        hideTimer = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: task)
    }
}
