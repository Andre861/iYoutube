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
    @State private var showFullDescription: Bool = false

    public init(video: Video, onClose: @escaping () -> Void) {
        self.video = video
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation / Dismiss Bar
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

                // Quality Selector Menu
                if !viewModel.availableFormats.isEmpty {
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
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }

                // Bookmark Toggle
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

            // Video Player Area
            ZStack {
                Color.black

                if let player = viewModel.player {
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
                        Button("Retry") {
                            Task { await viewModel.loadVideo(video: video) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .aspectRatio(16/9, contentMode: .fit)

            // Video Information Scroll Area
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
        .task {
            await viewModel.loadVideo(video: video)
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
