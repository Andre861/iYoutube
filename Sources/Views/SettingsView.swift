import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var service = InvidiousService.shared
    @State private var customURL: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(YouTubeTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(YouTubeTheme.background)

            Divider()
                .background(YouTubeTheme.border)

            Form {
                Section(header: Text("Invidious Server").foregroundColor(YouTubeTheme.textSecondary)) {
                    Picker("Active Node", selection: $service.currentInstance) {
                        ForEach(InvidiousInstance.defaultInstances) { inst in
                            Text(inst.name).tag(inst.url)
                        }
                    }

                    HStack {
                        Text("Custom Node")
                        TextField("https://...", text: $customURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button("Apply") {
                            if customURL.hasPrefix("http") {
                                service.currentInstance = customURL
                            }
                        }
                        .disabled(!customURL.hasPrefix("http"))
                    }

                    Text("Active: \(service.currentInstance)")
                        .font(.caption)
                        .foregroundColor(YouTubeTheme.textSecondary)
                }

                Section(header: Text("Playback & Hardware").foregroundColor(YouTubeTheme.textSecondary)) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(YouTubeTheme.red)
                        VStack(alignment: .leading) {
                            Text("iPad Air 2 Hardware Optimization")
                                .font(.headline)
                            Text("A8X memory-capped image cache (60MB) prevents jetsam crashes on 2GB RAM.")
                                .font(.caption)
                                .foregroundColor(YouTubeTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Background Audio & Screen Off")
                                .font(.headline)
                            Text("Audio continues uninterrupted when switching apps or locking the iPad.")
                                .font(.caption)
                                .foregroundColor(YouTubeTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Image(systemName: "pip.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Picture in Picture (PiP)")
                                .font(.headline)
                            Text("System PiP allows watching videos while using other iPad apps.")
                                .font(.caption)
                                .foregroundColor(YouTubeTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("About").foregroundColor(YouTubeTheme.textSecondary)) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("iYoutube Pro")
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                    HStack {
                        Text("Target Hardware")
                        Spacer()
                        Text("iPad Air 2 (iOS 15.0+)")
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0 (YouTube Parity)")
                            .foregroundColor(YouTubeTheme.textSecondary)
                    }
                }
            }
        }
        .background(YouTubeTheme.background)
        .navigationBarHidden(true)
    }
}
