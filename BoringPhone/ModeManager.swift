import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Owns all boring-mode state: the allow-list of apps, whether boring mode is
/// active, and applying/clearing the Screen Time shield.
final class ModeManager: ObservableObject {
    static let shared = ModeManager()

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("boringMode"))
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let boringModeOn = "boringModeOn"
        static let strictMode = "strictMode"
        static let selection = "allowedSelection"
    }

    @Published var isBoringModeOn: Bool {
        didSet {
            defaults.set(isBoringModeOn, forKey: Keys.boringModeOn)
            applyShield()
        }
    }

    /// When strict mode is on, the in-app "off" switch is hidden while boring
    /// mode is active — only the NFC tag (via the Shortcuts automation running
    /// the Disable/Toggle intent) can turn it off.
    @Published var isStrictMode: Bool {
        didSet { defaults.set(isStrictMode, forKey: Keys.strictMode) }
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
        isStrictMode = defaults.bool(forKey: Keys.strictMode)
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
