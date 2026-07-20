import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var modeManager: ModeManager
    @State private var showPicker = false
    @State private var authError: String?

    var body: some View {
        NavigationStack {
            List {
                statusSection
                if modeManager.isAuthorized {
                    controlSection
                    configSection
                }
                helpSection
            }
            .navigationTitle("Boring Phone")
            .familyActivityPicker(isPresented: $showPicker,
                                  selection: $modeManager.allowedSelection)
            .task {
                if !modeManager.isAuthorized {
                    do {
                        try await modeManager.requestAuthorization()
                    } catch {
                        authError = error.localizedDescription
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: modeManager.isBoringModeOn ? "iphone.slash" : "iphone")
                    .font(.largeTitle)
                    .foregroundStyle(modeManager.isBoringModeOn ? .green : .secondary)
                VStack(alignment: .leading) {
                    Text(modeManager.isBoringModeOn ? "Boring mode is ON" : "Boring mode is OFF")
                        .font(.headline)
                    Text(modeManager.isBoringModeOn
                         ? "Everything except your allowed apps is blocked."
                         : "Your phone is a normal, distracting phone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let authError {
                Label(authError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if !modeManager.isAuthorized {
                Label("Waiting for Screen Time permission…", systemImage: "hourglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlSection: some View {
        Section("Control") {
            if modeManager.isBoringModeOn && modeManager.isStrictMode {
                Label("Strict mode: tap your NFC tag to unlock.",
                      systemImage: "lock.fill")
                    .foregroundStyle(.orange)
            } else {
                Button {
                    modeManager.toggle()
                } label: {
                    Label(modeManager.isBoringModeOn ? "Turn boring mode off" : "Turn boring mode on",
                          systemImage: "power")
                }
            }
        }
    }

    private var configSection: some View {
        Section("Configuration") {
            Button {
                showPicker = true
            } label: {
                Label("Choose allowed apps", systemImage: "checklist")
            }
            .disabled(modeManager.isBoringModeOn && modeManager.isStrictMode)

            Toggle(isOn: $modeManager.isStrictMode) {
                Label("Strict mode", systemImage: "lock")
            }
            .disabled(modeManager.isBoringModeOn)

            LabeledContent("Allowed apps",
                           value: "\(modeManager.allowedSelection.applicationTokens.count)")
        } footer: {
            Text("Strict mode hides the in-app off switch while boring mode is on, so only your NFC tag automation can bring the phone back. Configure it before turning boring mode on.")
        }
    }

    private var helpSection: some View {
        Section("Setup") {
            Label("Pick your allowed apps above (WhatsApp, Safari, Camera, Maps…). Phone, Messages and Settings are system apps iOS never blocks.",
                  systemImage: "1.circle")
            Label("In Shortcuts, create a Personal Automation → NFC → scan your tag → run “Toggle Boring Mode” (and toggle your Boring Focus). Enable “Run Immediately”.",
                  systemImage: "2.circle")
            Label("See SETUP.md in the repo for the full walkthrough, including the minimal home screen layout.",
                  systemImage: "book")
        }
        .font(.callout)
    }
}

#Preview {
    ContentView()
        .environmentObject(ModeManager.shared)
}
