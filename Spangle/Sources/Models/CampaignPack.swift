/// A named chapter of the built-in campaign shown as its own level collection.
struct CampaignPack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
    let firstLevelIndex: Int
    let themes: [Theme]
}
