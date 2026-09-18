import AppIntents

/// These intents are what the iOS Shortcuts NFC automation calls.
/// The automation itself is bound to one specific physical tag by iOS,
/// which is what makes "only my tag toggles it" work.

// Titles below deliberately say "Boring Phone", not "Boring Mode" — this is
// exactly the string people search for in the Shortcuts automation editor,
// and a mismatch there is the most common reason this action seems "missing".

struct ToggleBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Boring Phone"
    static var description = IntentDescription(
        "Turns Boring Phone on if it is off, and off if it is on. Attach this to an NFC tag automation in Shortcuts."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ModeManager.shared
        manager.toggle()
        let dialog: IntentDialog = manager.isBoringModeOn
            ? "Boring Phone on. See you on the other side."
            : "Boring Phone off. Welcome back."
        return .result(dialog: dialog)
    }
}

struct EnableBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Lock Boring Phone"
    static var description = IntentDescription("Turns Boring Phone on.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.shared.setBoringMode(true)
        return .result(dialog: "Boring Phone on.")
    }
}

struct DisableBoringModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Unlock Boring Phone"
    static var description = IntentDescription("Turns Boring Phone off.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.shared.setBoringMode(false)
        return .result(dialog: "Boring Phone off.")
    }
}

struct BoringPhoneShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleBoringModeIntent(),
            phrases: ["Toggle \(.applicationName)"],
            shortTitle: "Toggle Boring Phone",
            systemImageName: "iphone.slash"
        )
    }
}
