import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var service = InvidiousService.shared
    @State private var customURL: String = ""

    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("Invidious Instance")) {
                Picker("Active Server", selection: $service.currentInstance) {
                    ForEach(InvidiousInstance.defaultInstances) { inst in
                        Text(inst.name).tag(inst.url)
                    }
                }

                HStack {
                    Text("Custom Server")
                    TextField("https://...", text: $customURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button("Use") {
                        if customURL.hasPrefix("http") {
                            service.currentInstance = customURL
                        }
                    }
                    .disabled(!customURL.hasPrefix("http"))
                }

                Text("Current: \(service.currentInstance)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Features")) {
                HStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Background Audio")
                            .font(.headline)
                        Text("Audio continues playing when the iPad screen is turned off or when switching apps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                HStack {
                    Image(systemName: "pip.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Picture in Picture")
                            .font(.headline)
                        Text("Swipe up or press Home while a video is playing to watch in a floating window.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Zero Ads & No Tracking")
                            .font(.headline)
                        Text("Video streams are retrieved directly from privacy-friendly Invidious proxy nodes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("About")) {
                HStack {
                    Text("App Name")
                    Spacer()
                    Text("iYoutube")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Target Device")
                    Spacer()
                    Text("iPad Air 2 (iOS 15.0+)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
