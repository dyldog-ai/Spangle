#if DEVELOPER_FEATURES
import SwiftUI

/// A dedicated modal boundary for playing a custom level without exposing the app's menu flow.
struct CustomLevelGameView: View {
    let level: CustomLevelDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GameView(previewLevel: level, onPreviewExit: dismiss.callAsFunction)
    }
}
#endif
