import AppIntents

/// These intents are what the iOS Shortcuts NFC automation calls.
/// The automation itself is bound to one specific physical tag by iOS,
/// which is what makes "only my tag toggles it" work.

struct ToggleBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Boring Mode"
    static var description = IntentDescription(
        "Turns boring mode on if it is off, and off if it is on. Attach this to an NFC tag automation in Shortcuts."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ModeManager.shared
        manager.toggle()
        let dialog: IntentDialog = manager.isBoringModeOn
            ? "Boring mode on. See you on the other side."
            : "Boring mode off. Welcome back."
        return .result(dialog: dialog)
    }
}

struct EnableBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Enable Boring Mode"
    static var description = IntentDescription("Turns boring mode on.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.shared.setBoringMode(true)
        return .result(dialog: "Boring mode on.")
    }
}

struct DisableBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Disable Boring Mode"
    static var description = IntentDescription("Turns boring mode off.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.shared.setBoringMode(false)
        return .result(dialog: "Boring mode off.")
    }
}

struct BoringPhoneShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleBoringModeIntent(),
            phrases: ["Toggle \(.applicationName)"],
            shortTitle: "Toggle Boring Mode",
            systemImageName: "iphone.slash"
        )
    }
}
