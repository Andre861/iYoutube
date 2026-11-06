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
    public let onClose: () -> Void

    @StateObject private var viewModel = PlayerViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared

    @State private var isFullScreen: Bool = false
    @State private var showControlsOverlay: Bool = true
    @State private var hideTimer: DispatchWorkItem?
    @State private var showFullDescription: Bool = false

    public init(video: Video, onClose: @escaping () -> Void) {
        self.video = video
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(isFullScreen ? UIColor.black : UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar (Only in normal mode)
                if !isFullScreen {
                    normalTopBar
                }

                // Video Player Container (Preserved identity across fullscreen toggle)
                videoContainer
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: isFullScreen ? .infinity : nil
                    )
                    .aspectRatio(isFullScreen ? nil : 16/9, contentMode: .fit)

                // Video Details (Only in normal mode)
                if !isFullScreen {
                    videoDetailsView
                }
            }
            .ignoresSafeArea(isFullScreen ? .all : [])

            // Floating HUD Overlay (Only in fullscreen mode)
            if isFullScreen {
                fullscreenOverlay
            }
        }
        .statusBar(hidden: isFullScreen)
        .task {
            await viewModel.loadVideo(video: video)
        }
        .onDisappear {
            hideTimer?.cancel()
            viewModel.stop()
        }
    }

    // MARK: - Normal Mode Top Bar
    private var normalTopBar: some View {
        HStack {
            Button(action: {
                viewModel.stop()
                onClose()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                    Text("Close")
                }
                .font(.headline)
                .padding(8)
            }

            Spacer()

            // True Fullscreen Button
            Button(action: {
                enterFullScreen()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Fullscreen")
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Engine Toggle
            Button(action: {
                viewModel.togglePlaybackMode()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.playbackMode == .native ? "play.circle.fill" : "globe")
                    Text(viewModel.playbackMode == .native ? "Native" : "Web Engine")
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Quality Selector Menu (Native only)
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }

            // Bookmark Button
            Button(action: {
                favorites.toggleFavorite(video: video)
            }) {
                Image(systemName: favorites.isFavorite(video: video) ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundColor(favorites.isFavorite(video: video) ? .red : .primary)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    // MARK: - Video Container
    private var videoContainer: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            if viewModel.playbackMode == .web {
                EmbeddedPlayerView(videoId: video.videoId)
            } else if let player = viewModel.player {
                CustomPlayerController(player: player)
            } else if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading Stream...")
                        .foregroundColor(.white)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Switch to Web Player") {
                        viewModel.playbackMode = .web
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // On-player Fullscreen Toggle (Normal mode)
            if !isFullScreen {
                Button(action: {
                    enterFullScreen()
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
                        exitFullScreen()
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

                    // Engine Toggle in Fullscreen
                    Button(action: {
                        viewModel.togglePlaybackMode()
                        resetAutoHideTimer()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.playbackMode == .native ? "play.circle.fill" : "globe")
                            Text(viewModel.playbackMode == .native ? "Native" : "Web Engine")
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
                        viewModel.stop()
                        onClose()
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
                        exitFullScreen()
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

    // MARK: - Video Details Scroll Area
    private var videoDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(video.title)
                    .font(.title3.bold())

                HStack(spacing: 12) {
                    Text(video.author)
                        .font(.headline)
                        .foregroundColor(.accentColor)

                    Spacer()

                    if let views = video.viewCount {
                        Text("\(views.formatted()) views")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Notice if running on Web Engine
                if viewModel.playbackMode == .web {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                        Text("Playing via Ad-Free Web Engine (Bypasses Google Bot Check)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Divider()

                if let detail = viewModel.videoDetail, let desc = detail.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        Text(desc)
                            .font(.footnote)
                            .lineLimit(showFullDescription ? nil : 4)

                        Button(showFullDescription ? "Show Less" : "Show More") {
                            showFullDescription.toggle()
                        }
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }

    // MARK: - Fullscreen Helpers
    private func enterFullScreen() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isFullScreen = true
            showControlsOverlay = true
        }
        resetAutoHideTimer()
    }

    private func exitFullScreen() {
        hideTimer?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            isFullScreen = false
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
