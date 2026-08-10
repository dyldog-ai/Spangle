import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    let onReset: () -> Void
    let onUnlockEverything: () -> Void
    let onClearUnlocks: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmsReset = false
    @State private var confirmsClearUnlocks = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle("Sound effects", isOn: $settings.soundEnabled)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                }
                Section("Accessibility") {
                    Toggle("Reduce game motion", isOn: $settings.reducedMotion)
                    Toggle("High contrast", isOn: $settings.highContrast)
                }
                Section("Progress") {
                    Button("Reset all progress", role: .destructive) { confirmsReset = true }
                }
                #if DEVELOPER_FEATURES
                Section("Developer") {
                    Button("Unlock all campaign levels", systemImage: "lock.open.fill") {
                        onUnlockEverything()
                    }
                    Button("Clear level unlocks", systemImage: "lock.fill", role: .destructive) {
                        confirmsClearUnlocks = true
                    }
                    Text("These controls only change campaign access. Scores, ratings, stars, characters, and learning history are preserved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif
                Section("About") {
                    LabeledContent("Game", value: "Spangle")
                    Text("Offline-first · No ads · No analytics")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Clear campaign level unlocks?",
                isPresented: $confirmsClearUnlocks,
                titleVisibility: .visible
            ) {
                Button("Clear unlocks", role: .destructive) {
                    onClearUnlocks()
                }
            } message: {
                Text("Only the first campaign level will remain unlocked.")
            }
            .confirmationDialog(
                "Reset campaign and learning progress?",
                isPresented: $confirmsReset,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) {
                    onReset()
                    dismiss()
                }
            } message: {
                Text("Unlocked levels, ratings, scores, star balance, characters, and word mastery will be removed. This cannot be undone.")
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }
}
