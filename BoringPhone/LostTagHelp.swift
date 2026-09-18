import SwiftUI
import UIKit
import Combine

/// Deliberately not a one-tap escape. Real emergencies (tag lost, tag left
/// at home while locked out at work) should still be solvable — but casual
/// willpower lapses shouldn't find this easier than just waiting it out.
/// Each step adds real friction: an honest self-check, a cooldown, then
/// finally the walkthrough.
struct LostTagHelpSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var step = 0
    @State private var secondsLeft = 20
    @State private var timerRunning = false

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
                        switch step {
                        case 0: checkAgainStep
                        case 1: honestyStep
                        case 2: cooldownStep
                        default: walkthroughStep
                        }
                    }
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
            guard step == 2, timerRunning, secondsLeft > 0 else { return }
            secondsLeft -= 1
        }
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
            Text("This exists for real emergencies — not for when five more minutes of scrolling feels urgent. If you continue, you're turning off the exact thing you set up to protect your focus.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            bigButton("I understand, continue anyway") { advance() }
            Button("Actually, I'll wait") { dismiss() }
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)
        }
    }

    private var cooldownStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "hourglass")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(theme.textSecondary)
            Text("One more moment")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text("If it's genuinely urgent, twenty seconds won't matter.")
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)

            if secondsLeft > 0 {
                Text("\(secondsLeft)")
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .onAppear { timerRunning = true }
            } else {
                bigButton("Show me the steps") { advance() }
            }
        }
    }

    private var walkthroughStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to unlock without the tag")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            walkStep("1", "Open Settings → Screen Time.")
            walkStep("2", "Tap Bored Phone → Stop Using Screen Time (or delete the app).")
            walkStep("3", "Every shield clears immediately.")

            Text("This also means anyone who knows your Screen Time passcode can do this — which is exactly why setting that passcode with someone else is worth doing.")
                .font(.system(size: 12.5))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)

            Button {
                openURL(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                Text("Open Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(theme.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func walkStep(_ number: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.accent.opacity(0.9)))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
