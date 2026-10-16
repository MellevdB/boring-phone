import Foundation
import Combine
import FamilyControls
import ManagedSettings

enum LockError: Error, CustomLocalizedStringResourceConvertible {
    case notAuthorized
    case tooManySelected
    case shieldDidNotApply

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthorized:
            return "Bored Phone can't lock: Screen Time access is off. Open Bored Phone and tap Continue."
        case .tooManySelected:
            return "Bored Phone can't lock: too many apps and sites are selected (limit 50 in total). Open Bored Phone and remove some."
        case .shieldDidNotApply:
            return "Bored Phone couldn't switch the Screen Time shield on, so it stayed unlocked. Open Bored Phone and pick your allowed apps again."
        }
    }
}

/// Owns all boring-mode state: the allow-list of apps, whether boring mode is
/// active, and applying/clearing the Screen Time shield.
///
/// There is deliberately no quick "manual unlock" path here that the app's
/// own UI can reach. `lock`/`unlock`/`toggle` exist for the App Intents in
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
        static let blockedSelection = "blockedSelection"
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

    /// Apps that must be shielded directly, on top of the "everything except
    /// the allow-list" category shield. A category shield skips apps on the
    /// user's Always Allowed list (and some system apps); a directly
    /// selected app is shielded regardless.
    @Published var blockedSelection: FamilyActivitySelection {
        didSet {
            if let data = try? JSONEncoder().encode(blockedSelection) {
                defaults.set(data, forKey: Keys.blockedSelection)
            }
            applyShield()
        }
    }

    /// When a "lost my tag" emergency unlock is pending, when it was
    /// requested (wall-clock). Persisted so it survives the app being
    /// killed, the phone rebooting, or 24 hours simply passing while the
    /// app is never opened.
    @Published private(set) var emergencyUnlockRequestedAt: Date?

    /// Set when iOS reported our saved selection could not be refreshed
    /// (iOS 26.5+ lets saved app tokens expire). Allowed apps might then be
    /// blocked or "always block" apps unshielded until they are picked again.
    @Published private(set) var selectionNeedsRepick = false

    private var tokenExpiryObservation: Any?

    private init() {
        isBoringModeOn = defaults.bool(forKey: Keys.boringModeOn)
        if let data = defaults.data(forKey: Keys.selection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            allowedSelection = saved
        } else {
            allowedSelection = FamilyActivitySelection()
        }
        if let data = defaults.data(forKey: Keys.blockedSelection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            blockedSelection = saved
        } else {
            blockedSelection = FamilyActivitySelection()
        }
        emergencyUnlockRequestedAt = defaults.object(forKey: Keys.emergencyRequestedAt) as? Date
        refreshExpiredTokens()
        applyShield()
        observeTokenExpiry()
    }

    private func observeTokenExpiry() {
        guard #available(iOS 26.5, *) else { return }
        tokenExpiryObservation = NotificationCenter.default.addObserver(
            of: ManagedSettingsStore.self,
            for: .tokensDidExpire
        ) { _ in
            await MainActor.run { ModeManager.shared.refreshExpiredTokens() }
        }
    }

    /// Asks iOS to renew saved tokens that expired (iOS 26.5+). A renewed
    /// array is only adopted if it has the same number of tokens, so a
    /// misbehaving refresh can never silently shrink the user's lists.
    /// A refresh that throws means the user has to pick again.
    func refreshExpiredTokens() {
        guard #available(iOS 26.5, *) else { return }
        var failed = false

        var allowedApps = Array(allowedSelection.applicationTokens)
        let allowedAppsBefore = allowedApps.count
        if !allowedApps.isEmpty {
            do { try ManagedSettingsStore.refresh(&allowedApps) } catch { failed = true }
        }
        if !failed, allowedApps.count == allowedAppsBefore,
           Set(allowedApps) != allowedSelection.applicationTokens {
            allowedSelection.applicationTokens = Set(allowedApps)
        }

        var allowedWeb = Array(allowedSelection.webDomainTokens)
        let allowedWebBefore = allowedWeb.count
        if !allowedWeb.isEmpty {
            do { try ManagedSettingsStore.refresh(&allowedWeb) } catch { failed = true }
        }
        if !failed, allowedWeb.count == allowedWebBefore,
           Set(allowedWeb) != allowedSelection.webDomainTokens {
            allowedSelection.webDomainTokens = Set(allowedWeb)
        }

        var blockedApps = Array(blockedSelection.applicationTokens)
        let blockedAppsBefore = blockedApps.count
        if !blockedApps.isEmpty {
            do { try ManagedSettingsStore.refresh(&blockedApps) } catch { failed = true }
        }
        if !failed, blockedApps.count == blockedAppsBefore,
           Set(blockedApps) != blockedSelection.applicationTokens {
            blockedSelection.applicationTokens = Set(blockedApps)
        }

        if selectionNeedsRepick != failed { selectionNeedsRepick = failed }
    }

    var isAuthorized: Bool {
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved { return true }
        if #available(iOS 26.4, *), status == .approvedWithDataAccess { return true }
        return false
    }

    /// iOS silently stops shielding anything once a store holds more than
    /// about 50 tokens (forum-reported, apps and websites combined), so the
    /// app refuses to lock above this rather than show LOCKED over an open
    /// phone.
    static let maxSelectedItems = 50

    var selectedItemCount: Int {
        allowedSelection.applicationTokens.count
            + allowedSelection.webDomainTokens.count
            + blockedSelection.applicationTokens.count
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

    /// Locks only if the shield can really be applied; throws otherwise so
    /// the Shortcuts automation stops before it turns the Focus on.
    func lock() throws {
        guard !isBoringModeOn else { return }
        guard isAuthorized else { throw LockError.notAuthorized }
        refreshExpiredTokens()
        guard selectedItemCount <= Self.maxSelectedItems else { throw LockError.tooManySelected }
        isBoringModeOn = true
        if !isShieldApplied {
            isBoringModeOn = false
            throw LockError.shieldDidNotApply
        }
    }

    func unlock() {
        guard isBoringModeOn else { return }
        isBoringModeOn = false
        // Unlocked (tag found, or the emergency wait completed) — any
        // pending emergency request is no longer relevant.
        cancelEmergencyUnlockRequest()
    }

    func toggle() throws {
        if isBoringModeOn { unlock() } else { try lock() }
    }

    var isShieldApplied: Bool {
        store.shield.applicationCategories != nil
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

    /// Shields every app category except the explicitly allowed apps, blocks
    /// every website in Safari except the explicitly allowed ones, and adds
    /// a few extra restrictions while locked. None of these are an
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
            store.shield.webDomainCategories = .all(except: allowedSelection.webDomainTokens)
            store.shield.applications = blockedSelection.applicationTokens
                .subtracting(allowedSelection.applicationTokens)
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
