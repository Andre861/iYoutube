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
        controller.videoGravity = .resizeAspect
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

    public init(video: Video) {
        self.video = video
        self.viewModel = PlayerCoordinator.shared.viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            // Automatically enter fullscreen when rotated to landscape, or when manually triggered
            let isTrueFullscreen = (coordinator.displayState == .fullscreen) || isLandscape

            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            // In portrait normal mode, player height is 16:9 of screen width
            // In fullscreen or landscape, player expands to the full screen height
            let playerHeight: CGFloat = isTrueFullscreen ? screenHeight : (screenWidth * 9.0 / 16.0)
            let topBarHeight: CGFloat = isTrueFullscreen ? 0 : 50

            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea(.all)

                // Layer 1: Normal Portrait Watch UI (Top bar and Details ScrollView)
                // Kept in hierarchy with opacity so view identity of player is NEVER disturbed
                VStack(spacing: 0) {
                    normalTopBar
                        .frame(height: 50)

                    // Reserved space corresponding to the player's 16:9 portrait position
                    Color.clear
                        .frame(width: screenWidth, height: screenWidth * 9.0 / 16.0)

                    videoDetailsScrollArea
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isTrueFullscreen ? 0.0 : 1.0)
                .allowsHitTesting(!isTrueFullscreen)

                // Layer 2: Persistent Video Player (NEVER in an if-statement, never unmounted on rotation)
                videoContainer(isTrueFullscreen: isTrueFullscreen)
                    .frame(width: screenWidth, height: playerHeight)
                    .offset(y: isTrueFullscreen ? 0 : topBarHeight)
                    .ignoresSafeArea(isTrueFullscreen ? .all : [])

                // Layer 3: Floating Fullscreen Overlay HUD
                if isTrueFullscreen {
                    fullscreenOverlay(isLandscape: isLandscape)
                        .transition(.opacity)
                }
            }
            .statusBar(hidden: isTrueFullscreen)
            .animation(.easeInOut(duration: 0.25), value: isTrueFullscreen)
            .onAppear {
                if isTrueFullscreen {
                    resetAutoHideTimer()
                }
            }
            .onChange(of: isLandscape) { newIsLandscape in
                if newIsLandscape {
                    resetAutoHideTimer()
                }
            }
        }
    }

    // MARK: - Normal Mode Top Bar
    private var normalTopBar: some View {
        HStack(spacing: 12) {
            // Minimize Button (Swipe/Tap down to miniplayer dock)
            Button(action: {
                coordinator.minimize()
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
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

    // MARK: - Video Container (Direct Touch Access, Zero Blocking Overlays)
    private func videoContainer(isTrueFullscreen: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            // Video Engine
            if viewModel.playbackMode == .web {
                EmbeddedPlayerView(videoId: video.videoId, viewModel: viewModel)
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

            // On-player Fullscreen Toggle (Only in normal portrait mode)
            if !isTrueFullscreen {
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
    private func fullscreenOverlay(isLandscape: Bool) -> some View {
        VStack {
            if showControlsOverlay {
                HStack(spacing: 10) {
                    // Exit Fullscreen / Minimize
                    Button(action: {
                        if isLandscape {
                            // If in landscape, minimize to miniplayer dock so user can browse
                            coordinator.minimize()
                        } else {
                            coordinator.exitFullscreen()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLandscape ? "chevron.down" : "arrow.down.right.and.arrow.up.left")
                            Text(isLandscape ? "Minimize" : "Exit Fullscreen")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                    }

                    // Seek Buttons (Native only)
                    if viewModel.playbackMode == .native {
                        Button(action: {
                            viewModel.seek(by: -10)
                            resetAutoHideTimer()
                        }) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            viewModel.seek(by: 10)
                            resetAutoHideTimer()
                        }) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                        }
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
                // Minimized subtle corner controls (does not obstruct video)
                HStack(spacing: 8) {
                    Button(action: {
                        if isLandscape {
                            coordinator.minimize()
                        } else {
                            coordinator.exitFullscreen()
                        }
                    }) {
                        Image(systemName: isLandscape ? "chevron.down" : "arrow.down.right.and.arrow.up.left")
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
