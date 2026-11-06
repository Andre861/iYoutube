import SwiftUI

public struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    public let onSelectVideo: (Video) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 450), spacing: 18)
    ]

    public init(onSelectVideo: @escaping (Video) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search YouTube...", text: $viewModel.query, onCommit: {
                        Task { await viewModel.search() }
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    if !viewModel.query.isEmpty {
                        Button(action: { viewModel.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

                Button("Search") {
                    Task { await viewModel.search() }
                }
                .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.leading, 8)
            }
            .padding()

            Divider()

            // Results Area
            ScrollView {
                if viewModel.isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No videos found")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.results) { video in
                            VideoCardView(video: video, onSelect: onSelectVideo)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Search")
    }
}
