import Testing
@testable import Spangle

struct CampaignPackTests {
    @Test
    func masterMindsAddsAnExpertCampaignAfterFoundations() throws {
        let expertPack = try #require(Campaign.packs.last)

        #expect(Campaign.packs.count == 2)
        #expect(expertPack.id == "master-minds")
        #expect(expertPack.firstLevelIndex == 12)
        #expect(expertPack.themes.count == 8)
        #expect(Campaign.themes.count == 20)
        #expect(Campaign.wordCount == 160)
    }

    @Test
    func campaignThemesAndVocabularyHaveStableUniqueIdentities() {
        let themeIDs = Campaign.themes.map(\.id)
        let vocabularyIDs = Campaign.themes.flatMap(\.words).map(\.id)

        #expect(Set(themeIDs).count == themeIDs.count)
        #expect(Set(vocabularyIDs).count == vocabularyIDs.count)
        #expect(Campaign.themes.allSatisfy { $0.words.count == 8 })
    }
}
