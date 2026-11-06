import SwiftUI

public struct TopicChipsBar: View {
    public let topics: [String]
    @Binding public var selectedTopic: String
    public let onSelectTopic: (String) -> Void

    public init(
        topics: [String] = ["All", "Trending", "Music", "Gaming", "News", "Podcasts", "Tech", "Live"],
        selectedTopic: Binding<String>,
        onSelectTopic: @escaping (String) -> Void
    ) {
        self.topics = topics
        self._selectedTopic = selectedTopic
        self.onSelectTopic = onSelectTopic
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(topics, id: \.self) { topic in
                    let isSelected = topic == selectedTopic
                    Button(action: {
                        selectedTopic = topic
                        onSelectTopic(topic)
                    }) {
                        Text(topic)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .black : YouTubeTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isSelected ? YouTubeTheme.pillSelected : YouTubeTheme.pill)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(YouTubeTheme.background)
    }
}
