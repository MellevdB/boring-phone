import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Owns all boring-mode state: the allow-list of apps, whether boring mode is
/// active, and applying/clearing the Screen Time shield.
///
/// There is deliberately no public "manual unlock" path here that the app's
/// own UI can reach. `setBoringMode`/`toggle` exist only for the App Intents
/// in Intents.swift, which are called exclusively by the Shortcuts NFC
/// automation — so locking and unlocking the phone always goes through the
/// tag, never a button in this app.
final class ModeManager: ObservableObject {
    static let shared = ModeManager()

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("boringMode"))
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let boringModeOn = "boringModeOn"
        static let selection = "allowedSelection"
    }

    @Published private(set) var isBoringModeOn: Bool {
        didSet {
            defaults.set(isBoringModeOn, forKey: Keys.boringModeOn)
            applyShield()
        }
    }

    /// Apps the user is still allowed to use while in boring mode.
    /// Everything else gets shielded.
    @Published var allowedSelection: FamilyActivitySelection {
        didSet {
            persistSelection()
            applyShield()
        }
    }

    private init() {
        isBoringModeOn = defaults.bool(forKey: Keys.boringModeOn)
        if let data = defaults.data(forKey: Keys.selection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            allowedSelection = saved
        } else {
            allowedSelection = FamilyActivitySelection()
        }
        applyShield()
    }

    var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private static let shortcutsBundleID = "com.apple.shortcuts"

    /// Best-effort check for whether both this app and Shortcuts are already
    /// in the allow-list — used only to hide/show a UI reminder, never for
    /// any security decision (the shield itself doesn't care about this).
    /// `Application(token:).bundleIdentifier` isn't guaranteed to resolve in
    /// every context, so this fails closed: if it can't positively confirm
    /// both are present, it returns false and the reminder stays visible
    /// rather than risk a false "you're safe".
    var includesSelfAndShortcuts: Bool {
        guard let ownBundleID = Bundle.main.bundleIdentifier else { return false }
        var hasSelf = false
        var hasShortcuts = false
        for token in allowedSelection.applicationTokens {
            guard let bundleID = Application(token: token).bundleIdentifier else { continue }
            if bundleID == ownBundleID { hasSelf = true }
            if bundleID == Self.shortcutsBundleID { hasShortcuts = true }
        }
        return hasSelf && hasShortcuts
    }

    @MainActor
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        objectWillChange.send()
    }

    func setBoringMode(_ on: Bool) {
        guard isBoringModeOn != on else { return }
        isBoringModeOn = on
    }

    func toggle() {
        isBoringModeOn.toggle()
    }

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(allowedSelection) {
            defaults.set(data, forKey: Keys.selection)
        }
    }

    /// Shields every app category except the explicitly allowed apps.
    /// System apps like Phone and Settings cannot be shielded by iOS anyway,
    /// so they stay reachable regardless of the selection.
    private func applyShield() {
        if isBoringModeOn {
            store.shield.applicationCategories = .all(except: allowedSelection.applicationTokens)
            store.shield.webDomainCategories = nil
        } else {
            store.shield.applicationCategories = nil
            store.shield.applications = nil
            store.shield.webDomainCategories = nil
            store.clearAllSettings()
        }
    }
}
