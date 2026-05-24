import SwiftUI

@main
struct PhotoboothApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var eventStore = EventStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(eventStore)
                .preferredColorScheme(.dark)
        }
    }
}
