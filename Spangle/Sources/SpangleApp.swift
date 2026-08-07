import SwiftUI

@main
struct SpangleApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
