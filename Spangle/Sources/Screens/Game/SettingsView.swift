import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmsReset = false

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
                "Reset campaign and learning progress?",
                isPresented: $confirmsReset,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) {
                    onReset()
                    dismiss()
                }
            } message: {
                Text("Unlocked levels, ratings, scores, and word mastery will be removed. This cannot be undone.")
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }
}
