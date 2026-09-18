import SwiftUI
import FamilyControls
import UIKit

struct ContentView: View {
    @EnvironmentObject var modeManager: ModeManager
    @Environment(\.openURL) private var openURL
    @Environment(\.theme) private var theme
    @Binding var language: AppLanguage

    @State private var showPicker = false
    @State private var showLostTagHelp = false
    @State private var authError: String?
    @State private var pulse = false

    var body: some View {
        ZStack {
            backdrop

            ScrollView {
                VStack(spacing: 28) {
                    languageSwitcher
                    statusHero
                    if modeManager.isAuthorized {
                        if modeManager.isBoringModeOn {
                            lockedCard
                        } else {
                            configCard
                        }
                    } else {
                        authorizationCard
                    }
                    setupCard
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $modeManager.allowedSelection)
        .sheet(isPresented: $showLostTagHelp) {
            LostTagHelpSheet()
        }
        .task {
            if !modeManager.isAuthorized {
                do {
                    try await modeManager.requestAuthorization()
                } catch {
                    authError = error.localizedDescription
                }
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - Background

    private var backdrop: some View {
        LinearGradient(colors: [theme.backdropTop, theme.backdropBottom],
                        startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    // MARK: - Language

    private var languageSwitcher: some View {
        HStack {
            Spacer()
            HStack(spacing: 2) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        language = lang
                    } label: {
                        Text(lang.label)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(language == lang ? theme.accent : Color.clear)
                            .foregroundStyle(language == lang ? .black : theme.textSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(theme.cardFill)
            .clipShape(Capsule())
        }
    }

    // MARK: - Hero

    private var statusHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(modeManager.isBoringModeOn ? 0.08 : 0.14))
                    .frame(width: pulse ? 190 : 170, height: pulse ? 190 : 170)
                    .blur(radius: 10)
                Circle()
                    .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
                    .frame(width: 148, height: 148)
                Image(systemName: modeManager.isBoringModeOn ? "iphone.slash" : "iphone.gen3")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.top, 4)

            Text(modeManager.isBoringModeOn ? "LOCKED" : "UNLOCKED")
                .font(.system(size: 13, weight: .semibold))
                .tracking(4)
                .foregroundStyle(theme.accent)

            Text(modeManager.isBoringModeOn ? "Boring Phone is active" : "Full access")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text(modeManager.isBoringModeOn
                 ? "Only your allowed apps are reachable.\nTap your NFC tag to unlock."
                 : "Everything is available.\nTap your NFC tag to lock in.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Cards

    private var lockedCard: some View {
        VStack(spacing: 10) {
            card {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Locked by NFC")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("There is no button in this app to unlock it. Tap your tag.")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                }
            }

            Button {
                showLostTagHelp = true
            } label: {
                Text("I lost my NFC tag")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }

    private var configCard: some View {
        VStack(spacing: 14) {
            requiredAppsCallout

            card {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Allowed apps")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Text("\(modeManager.allowedSelection.applicationTokens.count + modeManager.allowedSelection.categoryTokens.count)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.accent)
                    }

                    if !modeManager.allowedSelection.applicationTokens.isEmpty
                        || !modeManager.allowedSelection.categoryTokens.isEmpty {
                        selectedAppsList
                    }

                    Text("These stay reachable once you lock with your tag. Phone, Messages and Settings are always reachable — iOS never lets them be blocked.")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textSecondary)

                    Button {
                        showPicker = true
                    } label: {
                        Text("Choose allowed apps")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(theme.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Shows exactly what's selected as a plain list — the system picker's
    /// own UI requires expanding each category to see checkmarks, which is
    /// not a substitute for a simple "here's what you picked" summary.
    private var selectedAppsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(modeManager.allowedSelection.applicationTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textPrimary)
            }
            ForEach(Array(modeManager.allowedSelection.categoryTokens), id: \.self) { token in
                HStack(spacing: 8) {
                    Label(token)
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textPrimary)
                    Text("(entire category)")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.buttonSecondaryFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Impossible-to-miss reminder, shown only while unlocked — this is the
    /// one moment it can still be acted on, since the app itself becomes
    /// unreachable if you forget it and then lock.
    private var requiredAppsCallout: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 6) {
                Text("Before you lock: include these two")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("Boring Phone and Shortcuts must both be in your allowed apps, or they'll shield themselves too.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.orange.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var authorizationCard: some View {
        card {
            HStack(spacing: 12) {
                if let authError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(authError)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textTertiary)
                } else {
                    ProgressView()
                        .tint(theme.accent)
                    Text("Waiting for Screen Time permission…")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    private var setupCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("How the tag works")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                setupStep(number: "1", text: "Choose your allowed apps above, and include Boring Phone + Shortcuts so they don't lock themselves out.")
                setupStep(number: "2", text: "In Shortcuts → Automation → NFC, scan your tag, set “Run Immediately”, and add the action “Toggle Boring Phone”. Opened Boring Phone at least once already? It should show up when you search “Boring”.")
                setupStep(number: "3", text: "Build a minimal home screen page with just your allowed apps, then make a Focus (still labeled “Do Not Disturb” in some places) that shows only that page. Full walkthrough in SETUP.md.")
                setupStep(number: "4", text: "That tag is now the only key.")

                HStack(spacing: 10) {
                    linkButton("Open Shortcuts", systemImage: "arrow.up.forward.app", url: "shortcuts://")
                    linkButton("Open Settings", systemImage: "gearshape", url: UIApplication.openSettingsURLString)
                }
            }
        }
    }

    private func linkButton(_ title: LocalizedStringKey, systemImage: String, url: String) -> some View {
        Button {
            guard let target = URL(string: url) else { return }
            openURL(target)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.buttonSecondaryFill)
            .foregroundStyle(theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func setupStep(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.accent.opacity(0.9)))
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    ContentView(language: .constant(.system))
        .environmentObject(ModeManager.shared)
}
