import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Owns all boring-mode state: the allow-list of apps, whether boring mode is
/// active, and applying/clearing the Screen Time shield.
///
/// There is deliberately no quick "manual unlock" path here that the app's
/// own UI can reach. `setBoringMode`/`toggle` exist for the App Intents in
/// Intents.swift (called exclusively by the Shortcuts NFC automation) and
/// for the 24-hour emergency unlock in LostTagHelp.swift — nothing else in
/// this app calls them, so locking and unlocking always goes through the
/// tag, or through a deliberately slow, honest emergency path.
final class ModeManager: ObservableObject {
    static let shared = ModeManager()

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("boringMode"))
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let boringModeOn = "boringModeOn"
        static let selection = "allowedSelection"
        static let emergencyRequestedAt = "emergencyUnlockRequestedAt"
        static let emergencyRequestedUptime = "emergencyUnlockRequestedUptime"
    }

    /// How long the emergency unlock in LostTagHelp.swift makes you wait.
    /// Real hours, not app-open time — see `emergencyUnlockRemaining`.
    static let emergencyUnlockWait: TimeInterval = 24 * 60 * 60

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

    /// When a "lost my tag" emergency unlock is pending, when it was
    /// requested (wall-clock). Persisted so it survives the app being
    /// killed, the phone rebooting, or 24 hours simply passing while the
    /// app is never opened.
    @Published private(set) var emergencyUnlockRequestedAt: Date?

    private init() {
        isBoringModeOn = defaults.bool(forKey: Keys.boringModeOn)
        if let data = defaults.data(forKey: Keys.selection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            allowedSelection = saved
        } else {
            allowedSelection = FamilyActivitySelection()
        }
        emergencyUnlockRequestedAt = defaults.object(forKey: Keys.emergencyRequestedAt) as? Date
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
        if !on {
            // Unlocked (tag found, or the emergency wait completed) — any
            // pending emergency request is no longer relevant.
            cancelEmergencyUnlockRequest()
        }
    }

    func toggle() {
        isBoringModeOn.toggle()
    }

    // MARK: - Emergency unlock (24-hour wait)

    /// Starts the wait if one isn't already running. Re-entering the help
    /// flow later resumes the same clock rather than restarting it.
    func beginEmergencyUnlockRequest() {
        guard emergencyUnlockRequestedAt == nil else { return }
        let now = Date()
        emergencyUnlockRequestedAt = now
        defaults.set(now, forKey: Keys.emergencyRequestedAt)
        defaults.set(ProcessInfo.processInfo.systemUptime, forKey: Keys.emergencyRequestedUptime)
    }

    func cancelEmergencyUnlockRequest() {
        emergencyUnlockRequestedAt = nil
        defaults.removeObject(forKey: Keys.emergencyRequestedAt)
        defaults.removeObject(forKey: Keys.emergencyRequestedUptime)
    }

    /// Seconds still to wait, or nil if no request is pending. Cross-checks
    /// the wall clock against the device's monotonic uptime so casually
    /// setting the date forward in Settings doesn't skip the wait — if the
    /// phone hasn't rebooted since the request, uptime can't be tampered
    /// with the same way a wall-clock date can. If a reboot did happen,
    /// uptime alone can't tell us anything, so this falls back to trusting
    /// the wall clock (this is a friction device, not a security boundary —
    /// see SETUP.md).
    var emergencyUnlockRemaining: TimeInterval? {
        guard let requestedAt = emergencyUnlockRequestedAt else { return nil }
        let wallClockElapsed = Date().timeIntervalSince(requestedAt)

        if let requestedUptime = defaults.object(forKey: Keys.emergencyRequestedUptime) as? TimeInterval {
            let currentUptime = ProcessInfo.processInfo.systemUptime
            if currentUptime >= requestedUptime {
                let uptimeElapsed = currentUptime - requestedUptime
                let trustedElapsed = min(wallClockElapsed, uptimeElapsed)
                return max(0, Self.emergencyUnlockWait - trustedElapsed)
            }
        }
        return max(0, Self.emergencyUnlockWait - wallClockElapsed)
    }

    var isEmergencyUnlockReady: Bool {
        guard let remaining = emergencyUnlockRemaining else { return false }
        return remaining <= 0
    }

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(allowedSelection) {
            defaults.set(data, forKey: Keys.selection)
        }
    }

    /// Shields every app category except the explicitly allowed apps, and
    /// adds a few extra restrictions while locked. None of these are an
    /// absolute guarantee under individual (self-managed) authorization —
    /// Apple always lets a user revoke Screen Time access for their own
    /// apps via Settings, specifically so a self-installed app can never
    /// truly imprison someone's device. What they do provide: removing the
    /// casual "long-press the icon and delete it" escape, and stopping the
    /// classic "just set the clock forward" trick against the 24-hour
    /// emergency wait above.
    private func applyShield() {
        if isBoringModeOn {
            store.shield.applicationCategories = .all(except: allowedSelection.applicationTokens)
            store.shield.webDomainCategories = nil
            store.application.denyAppRemoval = true
            store.account.lockAccounts = true
            store.dateAndTime.requireAutomaticDateAndTime = true
        } else {
            store.shield.applicationCategories = nil
            store.shield.applications = nil
            store.shield.webDomainCategories = nil
            store.clearAllSettings()
        }
    }
}
