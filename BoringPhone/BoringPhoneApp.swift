import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system, en, nl

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .en: return Locale(identifier: "en")
        case .nl: return Locale(identifier: "nl")
        }
    }

    var label: String {
        switch self {
        case .system: return "Auto"
        case .en: return "EN"
        case .nl: return "NL"
        }
    }
}

@main
struct BoringPhoneApp: App {
    @StateObject private var modeManager = ModeManager.shared
    @AppStorage("appLanguage") private var languageRaw = AppLanguage.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some Scene {
        WindowGroup {
            ContentView(language: Binding(
                get: { AppLanguage(rawValue: languageRaw) ?? .system },
                set: { languageRaw = $0.rawValue }
            ))
            .environmentObject(modeManager)
            .environment(\.locale, (AppLanguage(rawValue: languageRaw) ?? .system).locale ?? Locale.autoupdatingCurrent)
            .modifier(ThemeInjector())
        }
    }
}

/// Reads the live system color scheme and publishes a `Theme` into the
/// environment, since our own view code reads `\.theme` rather than
/// re-deriving colors from `\.colorScheme` everywhere.
private struct ThemeInjector: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.environment(\.theme, Theme(colorScheme: colorScheme))
    }
}
