import SwiftUI

@main
struct BoringPhoneApp: App {
    @StateObject private var modeManager = ModeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modeManager)
                .preferredColorScheme(.dark)
        }
    }
}
