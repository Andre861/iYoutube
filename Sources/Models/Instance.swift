import Foundation

public struct InvidiousInstance: Identifiable, Hashable {
    public var id: String { url }
    public let name: String
    public let url: String

    public static let defaultInstances: [InvidiousInstance] = [
        InvidiousInstance(name: "Tux Pizza", url: "https://inv.tux.pizza"),
        InvidiousInstance(name: "NerdVPN Invidious", url: "https://invidious.nerdvpn.de"),
        InvidiousInstance(name: "PrivAU", url: "https://vid.priv.au"),
        InvidiousInstance(name: "Yewtu.be", url: "https://yewtu.be"),
        InvidiousInstance(name: "Drgns Space", url: "https://invidious.drgns.space"),
        InvidiousInstance(name: "Jing Rocks", url: "https://invidious.jing.rocks")
    ]
}
