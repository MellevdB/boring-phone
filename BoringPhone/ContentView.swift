import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var modeManager: ModeManager
    @Environment(\.openURL) private var openURL
    @State private var showPicker = false
    @State private var authError: String?
    @State private var pulse = false

    private var accent: Color { Color(red: 1.0, green: 0.78, blue: 0.55) }

    var body: some View {
        ZStack {
            backdrop

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 24)
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
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $modeManager.allowedSelection)
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
        LinearGradient(
            colors: modeManager.isBoringModeOn
                ? [Color(red: 0.05, green: 0.05, blue: 0.06), Color.black]
                : [Color(red: 0.09, green: 0.09, blue: 0.11), Color.black],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero

    private var statusHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(modeManager.isBoringModeOn ? 0.08 : 0.14))
                    .frame(width: pulse ? 190 : 170, height: pulse ? 190 : 170)
                    .blur(radius: 10)
                Circle()
                    .strokeBorder(accent.opacity(0.35), lineWidth: 1)
                    .frame(width: 148, height: 148)
                Image(systemName: modeManager.isBoringModeOn ? "iphone.slash" : "iphone.gen3")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(.white)
            }
            .padding(.top, 12)

            Text(modeManager.isBoringModeOn ? "LOCKED" : "UNLOCKED")
                .font(.system(size: 13, weight: .semibold))
                .tracking(4)
                .foregroundStyle(accent)

            Text(modeManager.isBoringModeOn ? "Boring Phone is active" : "Full access")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(.white)

            Text(modeManager.isBoringModeOn
                 ? "Only your allowed apps are reachable.\nTap your NFC tag to unlock."
                 : "Everything is available.\nTap your NFC tag to lock in.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Cards

    private var lockedCard: some View {
        card {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Locked by NFC")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("There is no button in this app to unlock it. Tap your tag.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
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
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(modeManager.allowedSelection.applicationTokens.count)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent)
                    }

                    Text("These stay reachable once you lock with your tag. Phone, Messages and Settings are always reachable — iOS never lets them be blocked.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))

                    Button {
                        showPicker = true
                    } label: {
                        Text("Choose allowed apps")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                    .foregroundStyle(.white)
                Text("Boring Phone and Shortcuts must both be in your allowed apps, or they'll shield themselves too. If you ever forget, Settings → Screen Time always clears the lock — you can't be permanently shut out.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.65))
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
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    ProgressView()
                        .tint(accent)
                    Text("Waiting for Screen Time permission…")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private var setupCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("How the tag works")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                setupStep(number: "1", text: "Choose your allowed apps above, and include Boring Phone + Shortcuts so they don't lock themselves out.")
                setupStep(number: "2", text: "In Shortcuts → Automation → NFC, scan your tag, set “Run Immediately”, and add the action “Toggle Boring Phone”. Opened Boring Phone at least once already? It should show up when you search “Boring”.")
                setupStep(number: "3", text: "That tag is now the only key. Full walkthrough in SETUP.md.")

                Button {
                    openURL(URL(string: "shortcuts://")!)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Open Shortcuts")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func setupStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(Circle().fill(accent.opacity(0.9)))
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(ModeManager.shared)
        .preferredColorScheme(.dark)
}
