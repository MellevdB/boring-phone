import SwiftUI

/// Colors that adapt to the system's light/dark appearance. Kept as plain
/// computed values (not an asset catalog) since the palette is small and
/// this keeps ContentView's call sites simple: `theme.textPrimary`, etc.
struct Theme {
    let colorScheme: ColorScheme

    var isDark: Bool { colorScheme == .dark }

    var accent: Color { Color(red: 1.0, green: isDark ? 0.78 : 0.52, blue: isDark ? 0.55 : 0.16) }

    var backdropTop: Color {
        isDark ? Color(red: 0.09, green: 0.09, blue: 0.11) : Color(red: 0.97, green: 0.96, blue: 0.94)
    }
    var backdropBottom: Color { isDark ? .black : Color(red: 0.91, green: 0.9, blue: 0.87) }

    var textPrimary: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1) }
    var textSecondary: Color { isDark ? .white.opacity(0.5) : .black.opacity(0.5) }
    var textTertiary: Color { isDark ? .white.opacity(0.65) : .black.opacity(0.6) }

    var cardFill: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.035) }
    var cardBorder: Color { isDark ? .white.opacity(0.08) : .black.opacity(0.08) }
    var buttonSecondaryFill: Color { isDark ? .white.opacity(0.08) : .black.opacity(0.05) }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(colorScheme: .dark)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
