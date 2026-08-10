#if DEVELOPER_FEATURES
import SwiftUI

struct LevelCreatorLibraryView: View {
    @ObservedObject var store: LevelCreatorStore
    let initialEditorLevelID: UUID?
    let onPlay: (CustomLevelDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showsEditor = false
    @State private var editorLevelID: UUID?
    @State private var editorSessionID = UUID()
    @State private var levelPendingDeletion: CustomLevelDefinition?
    @State private var handledInitialEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackdrop()
                ScrollView {
                    VStack(spacing: 14) {
                        HStack {
                            Text(store.levels.isEmpty ? "No saved levels yet" : "\(store.levels.count) saved level\(store.levels.count == 1 ? "" : "s")")
                                .font(.headline)
                                .foregroundStyle(Color.storybookPaper)
                            Spacer()
                            Button("New Level", systemImage: "plus", action: createLevel)
                                .buttonStyle(StorybookPrimaryButtonStyle())
                        }
                        if store.levels.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.levels) { level in
                                levelRow(level)
                            }
                        }
                    }
                    .frame(maxWidth: 760)
                    .padding(18)
                }
            }
            .navigationTitle("My Levels")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Level", systemImage: "plus", action: createLevel)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 520)
        .sheet(isPresented: $showsEditor) { editor }
        #else
        .fullScreenCover(isPresented: $showsEditor) { editor }
        #endif
        .confirmationDialog(
            "Delete \(levelPendingDeletion?.title ?? "this level")?",
            isPresented: deletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete level", role: .destructive, action: deletePendingLevel)
            Button("Cancel", role: .cancel) { levelPendingDeletion = nil }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear(perform: openInitialEditorIfNeeded)
    }

    private var emptyState: some View {
        StorybookPanel {
            VStack(spacing: 14) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.storybookBlue)
                Text("Build your first level")
                    .font(.title2.bold())
                Text("Create a timeline, add vocabulary, save it, and playtest it instantly.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.storybookInk.opacity(0.65))
                Button("New Level", systemImage: "plus", action: createLevel)
                    .buttonStyle(StorybookPrimaryButtonStyle())
            }
        }
    }

    private func levelRow(_ level: CustomLevelDefinition) -> some View {
        HStack(spacing: 14) {
            Text(level.emoji.isEmpty ? "🛠️" : level.emoji)
                .font(.system(size: 38))
                .frame(width: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(level.title)
                    .font(.headline)
                Text("\(level.vocabularyCount) words · finish at \(Int(level.finishX))")
                    .font(.caption)
                    .foregroundStyle(Color.storybookInk.opacity(0.62))
            }
            Spacer()
            Button("Play", systemImage: "play.fill") {
                dismiss()
                onPlay(level)
            }
            .buttonStyle(StorybookPrimaryButtonStyle())
            Button("Edit", systemImage: "pencil") {
                edit(level)
            }
            .buttonStyle(StorybookSecondaryButtonStyle())
            Button(role: .destructive) {
                levelPendingDeletion = level
            } label: {
                Image(systemName: "trash.fill")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Delete \(level.title)")
        }
        .foregroundStyle(Color.storybookInk)
        .padding(14)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.storybookInk.opacity(0.35), lineWidth: 2))
    }

    private var editor: some View {
        LevelCreatorView(
            store: store,
            initialLevelID: editorLevelID
        )
        .id(editorSessionID)
    }

    private var deletionConfirmation: Binding<Bool> {
        Binding(
            get: { levelPendingDeletion != nil },
            set: { if !$0 { levelPendingDeletion = nil } }
        )
    }

    private func createLevel() {
        editorLevelID = nil
        editorSessionID = UUID()
        showsEditor = true
    }

    private func edit(_ level: CustomLevelDefinition) {
        editorLevelID = level.id
        editorSessionID = UUID()
        showsEditor = true
    }

    private func deletePendingLevel() {
        guard let level = levelPendingDeletion else { return }
        store.delete(level)
        levelPendingDeletion = nil
    }

    private func openInitialEditorIfNeeded() {
        guard !handledInitialEditor else { return }
        handledInitialEditor = true
        guard let initialEditorLevelID,
              store.levels.contains(where: { $0.id == initialEditorLevelID }) else { return }
        editorLevelID = initialEditorLevelID
        editorSessionID = UUID()
        showsEditor = true
    }
}
#endif
