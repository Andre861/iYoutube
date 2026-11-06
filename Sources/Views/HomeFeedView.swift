import SwiftUI

public struct HomeFeedView: View {
    @StateObject private var viewModel = HomeViewModel()
    public let onSelectVideo: (Video) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 450), spacing: 18)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.videos.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.top, 60)
                    Text("Loading Trending Videos...")
                        .foregroundColor(.secondary)
                }
            } else if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task { await viewModel.loadTrending() }
                    }
                    .buttonStyle(.borderedProminent)
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
        .navigationTitle("Trending")
        .refreshable {
            await viewModel.loadTrending()
        }
    }
}
