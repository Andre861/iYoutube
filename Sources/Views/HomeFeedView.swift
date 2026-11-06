import SwiftUI

public struct HomeFeedView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var service = InvidiousService.shared
    public let onSelectVideo: (Video) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 550), spacing: 20)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(spacing: 0) {
            // YouTube Header
            YouTubeHeaderView()

            // Topic Filter Chips Bar
            TopicChipsBar(
                selectedTopic: $viewModel.selectedTopic,
                onSelectTopic: { topic in
                    Task {
                        await viewModel.loadFeed(topic: topic)
                    }
                }
            )

            Divider()
                .background(YouTubeTheme.border)

            // Feed Content
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.videos.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: YouTubeTheme.red))
                                .scaleEffect(1.4)
                                .padding(.top, 60)
                            Text("Loading feed...")
                                .font(.subheadline)
                                .foregroundColor(YouTubeTheme.textSecondary)
                        }
                    } else if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 44))
                                .foregroundColor(YouTubeTheme.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(YouTubeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                Button("Retry") {
                                    Task { await viewModel.loadFeed() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(YouTubeTheme.red)

                                Menu("Switch Server") {
                                    ForEach(InvidiousInstance.defaultInstances) { inst in
                                        Button(inst.name) {
                                            service.currentInstance = inst.url
                                            Task { await viewModel.loadFeed() }
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.videos) { video in
                                VideoCardView(video: video, onSelect: onSelectVideo)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 80) // Leave space for miniplayer dock
                    }
                }
            }
            .background(YouTubeTheme.background)
            .refreshable {
                await viewModel.loadFeed()
            }
        }
        .background(YouTubeTheme.background)
        .navigationBarHidden(true)
    }
}
