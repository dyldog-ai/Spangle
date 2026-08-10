import SwiftUI

struct CharacterShopView: View {
    @ObservedObject var store: CharacterStore
    let onSelectionChanged: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackdrop()
                ScrollView {
                    VStack(spacing: 18) {
                        wallet
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.designs) { design in
                                characterCard(design)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Character Atelier")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 560)
        #endif
    }

    private var wallet: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.storybookGold)
            VStack(alignment: .leading, spacing: 1) {
                Text("STAR BANK").font(.caption.weight(.black)).tracking(1.4)
                Text("\(store.starBalance.formatted()) stars")
                    .font(.title2.weight(.black).monospacedDigit())
            }
            Spacer()
            Text("Finish runs to bank every star you collect.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.storybookInk.opacity(0.62))
        }
        .foregroundStyle(Color.storybookInk)
        .padding(16)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.storybookInk.opacity(0.45), lineWidth: 2))
    }

    private func characterCard(_ design: CharacterDesign) -> some View {
        let owned = store.owns(design)
        let selected = store.selectedID == design.id
        return Button {
            if owned {
                store.equip(design)
                onSelectionChanged()
            } else if store.purchase(design) {
                onSelectionChanged()
            }
        } label: {
            VStack(spacing: 7) {
                CharacterPortrait(design: design)
                Text(design.name)
                    .font(.headline.weight(.black))
                    .lineLimit(1)
                Text(design.tagline)
                    .font(.caption)
                    .foregroundStyle(Color.storybookInk.opacity(0.62))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(design.rarity.uppercased())
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(rarityColor(design))
                status(for: design, owned: owned, selected: selected)
            }
            .foregroundStyle(Color.storybookInk)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 245)
            .background(Color.storybookPaper.opacity(0.96), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(selected ? Color.storybookGold : Color.storybookInk.opacity(0.35),
                            lineWidth: selected ? 4 : 2)
            }
            .opacity(!owned && !store.canAfford(design) ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(design, owned: owned, selected: selected))
    }

    @ViewBuilder
    private func status(for design: CharacterDesign, owned: Bool, selected: Bool) -> some View {
        if selected {
            Label("Equipped", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.storybookGreen)
        } else if owned {
            Text("Equip")
        } else {
            Label("\(design.cost.formatted())", systemImage: "star.fill")
                .foregroundStyle(store.canAfford(design) ? Color.storybookRed : Color.storybookInk.opacity(0.45))
        }
    }

    private func rarityColor(_ design: CharacterDesign) -> Color {
        switch design.style {
        case .dragon, .aurora, .stardust, .speedster: .purple
        case .legend, .isaac: .storybookRed
        case .clockwork, .astronaut, .knight, .moonwalker, .sleuth, .plumber: .storybookBlue
        default: .storybookGreen
        }
    }

    private func accessibilityLabel(_ design: CharacterDesign, owned: Bool, selected: Bool) -> String {
        if selected { return "\(design.name), equipped" }
        if owned { return "\(design.name), owned, double tap to equip" }
        return "\(design.name), costs \(design.cost) stars"
    }
}
