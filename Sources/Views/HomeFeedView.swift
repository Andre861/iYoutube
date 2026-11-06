import SwiftUI

public struct HomeFeedView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var service = InvidiousService.shared
    public let onSelectVideo: (Video) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 450), spacing: 18)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 60)
                        Text("Connecting to server...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Button("Retry") {
                                Task { await viewModel.loadTrending() }
                            }
                            .buttonStyle(.borderedProminent)

                            Menu("Switch Server") {
                                ForEach(InvidiousInstance.defaultInstances) { inst in
                                    Button(inst.name) {
                                        service.currentInstance = inst.url
                                        Task { await viewModel.loadTrending() }
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
                    .padding()
                }
            }
        }
        .navigationTitle("Trending")
        .refreshable {
            await viewModel.loadTrending()
        }
    }
}
