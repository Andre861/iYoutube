import Foundation

public struct InvidiousInstance: Identifiable, Hashable {
    public var id: String { url }
    public let name: String
    public let url: String

    public static let defaultInstances: [InvidiousInstance] = [
        InvidiousInstance(name: "ChocolateMoo (Fast / Verified)", url: "https://yt.chocolatemoo53.com"),
        InvidiousInstance(name: "Nadeko Network", url: "https://inv.nadeko.net"),
        InvidiousInstance(name: "NerdVPN Invidious", url: "https://invidious.nerdvpn.de"),
        InvidiousInstance(name: "Yewtu.be", url: "https://yewtu.be")
    ]
}
