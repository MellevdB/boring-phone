import SwiftUI
import UIKit
import Combine
import Foundation

/// Deliberately not a one-tap escape. Real emergencies (tag lost, tag left
/// at home while locked out at work) should still be solvable — but casual
/// willpower lapses shouldn't find this easier than just waiting it out.
///
/// The flow: an honest self-check, a reflection prompt, then a real
/// 24-hour wait (persisted in ModeManager, so it survives the app being
/// killed or the phone rebooting — reopening this sheet mid-wait resumes
/// the same clock, it doesn't restart it). Only after that does an actual
/// unlock button appear.
///
/// This is a friction device, not a security boundary: Apple guarantees
/// Settings -> Screen Time can always revoke this app's access, for any
/// self-managed app, precisely so a self-installed app can never truly
/// imprison someone's device. That route is mentioned honestly at the end
/// rather than hidden — hiding it would strand someone in a genuine
/// emergency without actually stopping a determined person, since it's
/// common knowledge to anyone who's used Screen Time before.
struct LostTagHelpSheet: View {
    @EnvironmentObject private var modeManager: ModeManager
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var step = 0
    @State private var tick = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [theme.backdropTop, theme.backdropBottom],
                                startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Group {
                        if modeManager.emergencyUnlockRequestedAt != nil {
                            if modeManager.isEmergencyUnlockReady {
                                readyStep
                            } else {
                                waitingStep
                            }
                        } else {
                            switch step {
                            case 0: checkAgainStep
                            default: honestyStep
                            }
                        }
                    }
                    .id(modeManager.emergencyUnlockRequestedAt != nil ? (modeManager.isEmergencyUnlockReady ? "ready" : "waiting") : "step\(step)")
                    .transition(.opacity)
                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .onReceive(timer) { _ in
            // emergencyUnlockRemaining is computed, not @Published — this
            // forces a redraw each second so the countdown actually ticks.
            tick += 1
        }
        .animation(.easeInOut(duration: 0.2), value: modeManager.emergencyUnlockRequestedAt)
        .animation(.easeInOut(duration: 0.2), value: modeManager.isEmergencyUnlockReady)
    }

    private var checkAgainStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(theme.textSecondary)
            Text("Have you really checked?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Pockets. Bag. Desk. The place you usually leave it. Most \"lost\" tags are five meters away.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            bigButton("I checked, still can't find it") { advance() }
            Button("Let me go check again") { dismiss() }
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)
        }
    }

    private var honestyStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(theme.textSecondary)
            Text("Be honest with yourself")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("This exists for real emergencies — not for when five more minutes of scrolling feels urgent. Continuing starts a 24-hour wait before you can unlock this way.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            bigButton("Start the 24-hour wait") { modeManager.beginEmergencyUnlockRequest() }
            Button("Actually, I'll wait for the tag") { dismiss() }
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)
        }
    }

    private var waitingStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "hourglass")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(theme.textSecondary)
            Text("Waiting it out")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text("If it's genuinely urgent, this is the price — a real 24 hours, not app-open time. It keeps counting even if you close Bored Phone.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            Text(formattedRemaining)
                .font(.system(size: 36, weight: .thin, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .monospacedDigit()

            Button("Cancel this request") {
                modeManager.cancelEmergencyUnlockRequest()
                withAnimation { step = 0 }
            }
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)
            .padding(.top, 6)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(theme.accent)
                Text("The wait is over")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            Button {
                modeManager.setBoringMode(false)
                dismiss()
            } label: {
                Text("Unlock Bored Phone now")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(theme.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("Prefer to do it manually, or want to remove Bored Phone entirely? Settings → Screen Time → Bored Phone → Stop Using Screen Time works too, and always has — Apple guarantees that path stays open for an app you install yourself.")
                .font(.system(size: 12.5))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)

            Button {
                openURL(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                    Text("Open Settings")
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedRemaining: String {
        let remaining = modeManager.emergencyUnlockRemaining ?? 0
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: remaining) ?? "0:00:00"
    }

    private func bigButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(theme.accent)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        withAnimation { step += 1 }
    }
}
