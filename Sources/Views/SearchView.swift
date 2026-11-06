import SwiftUI

public struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    public let onSelectVideo: (Video) -> Void

    private let quickSuggestions = ["iPad Air 2", "Lofi Music", "Apple Event", "Tech News", "Gaming", "Documentary"]

    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 550), spacing: 20)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(YouTubeTheme.textSecondary)

                    TextField("Search YouTube...", text: $viewModel.query, onCommit: {
                        Task { await viewModel.search() }
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(YouTubeTheme.textPrimary)

                    if !viewModel.query.isEmpty {
                        Button(action: { viewModel.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(YouTubeTheme.textSecondary)
                        }
                    }
                }
                .padding(10)
                .background(YouTubeTheme.surface)
                .cornerRadius(20)

                Button("Search") {
                    Task { await viewModel.search() }
                }
                .font(.headline)
                .foregroundColor(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty ? YouTubeTheme.textSecondary : YouTubeTheme.red)
                .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(YouTubeTheme.background)

            // Quick suggestion chips when not searched yet
            if viewModel.results.isEmpty && !viewModel.isSearching {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                viewModel.query = suggestion
                                Task { await viewModel.search() }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                    Text(suggestion)
                                        .font(.subheadline)
                                }
                                .foregroundColor(YouTubeTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(YouTubeTheme.pill)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(YouTubeTheme.background)
            }

            Divider()
                .background(YouTubeTheme.border)

            // Results Area
            ScrollView {
                if viewModel.isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: YouTubeTheme.red))
                            .scaleEffect(1.5)
                        Text("Searching...")
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(YouTubeTheme.red)
                        Text(error)
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(YouTubeTheme.textSecondary)
                        Text("No videos found")
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.results) { video in
                            VideoCardView(video: video, onSelect: onSelectVideo)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            }
            .background(YouTubeTheme.background)
        }
        .background(YouTubeTheme.background)
        .navigationBarHidden(true)
    }
}
