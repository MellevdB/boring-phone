# 📵 Bored Phone

Tap an NFC tag → your iPhone becomes a boring phone: calls, texts, WhatsApp,
a browser, and not much else, on a stripped-down home screen. Tap the same
tag again → normal phone.

No subscription gadget required — this is the DIY version of products like
Brick/Unpluq, built with Apple's own Screen Time API.

## How it works

Three pieces cooperate:

| Piece | What it does |
|---|---|
| **This app** | Uses the Screen Time API (`FamilyControls` + `ManagedSettings`) to shield every app except your allow-list. Exposes a "Toggle Boring Mode" action to Shortcuts. |
| **Shortcuts NFC automation** | iOS binds an NFC automation to *one specific physical tag*. Tapping your tag runs the toggle action. Other tags do nothing. |
| **A "Boring" Focus mode** | Swaps your home screen to a single minimal page and silences non-essential notifications. Toggled by the same automation. |

When boring mode is on, blocked apps show Apple's shield screen and can't be
opened — not from the home screen, not from search, not from notifications.

## Requirements

- iPhone XS or newer, iOS 16.4+ (NFC background reading + App Intents)
- A Mac with **Xcode 15+**
- A **paid Apple Developer Program membership** (€99/yr) — Apple does not
  allow the Family Controls capability on free Personal Teams, so the app
  cannot be signed without it. No budget? **[FREE-SETUP.md](FREE-SETUP.md)**
  gets you 80% of the way with zero code: NFC-toggled minimal layout via
  Focus, always-on blocking via Screen Time limits.
- One NFC tag (NTAG213/215/216 stickers all work, ~€1)

## Build & install

```sh
brew install xcodegen   # if you don't have it
xcodegen generate       # creates BoringPhone.xcodeproj
open BoringPhone.xcodeproj
```

In Xcode:

1. Select the **BoringPhone** target → *Signing & Capabilities* → pick your
   Team, and change the bundle identifier to something unique to you.
2. The **Family Controls** capability is already in the entitlements file.
   If signing fails on it, register your bundle ID with the Family Controls
   (development) capability enabled in your Apple Developer account.
3. Plug in your iPhone, select it as the run destination, hit **Run**.
4. On the phone: Settings → General → VPN & Device Management → trust your
   developer certificate.
5. Launch the app and grant the Screen Time permission it asks for.

Then follow **[SETUP.md](SETUP.md)** for the phone-side setup: allowed apps,
the Boring Focus, the minimal home screen, and the NFC automation.

## Sharing it via TestFlight

Want friends running this too? See **[ci/TESTFLIGHT.md](ci/TESTFLIGHT.md)** —
one script (`ci/release_to_testflight.sh`) archives, signs, and uploads a
build using an App Store Connect API key. Note: distributing a build (even
internally) needs Apple's separate Family Controls **distribution**
entitlement approval, on top of the paid membership — that doc explains it.

## Honest limitations

- **Phone, Messages, Settings can't be blocked** by iOS at all — which is
  fine, they're on your allow-list anyway.
- This is a **commitment device, not a prison.** Determined-you can delete
  the app or edit the automation. SETUP.md has a hardening section
  (Screen Time passcode + blocking app deletion) that makes cheating
  genuinely annoying.
- Development installs expire after a year; plug in and Run again to renew.

## Repo layout

```
project.yml                 XcodeGen spec (generates the .xcodeproj)
BoringPhone/
  BoringPhoneApp.swift      App entry point
  ContentView.swift         Status screen + app picker (no manual lock control)
  ModeManager.swift         Shield on/off + persistence
  Intents.swift             App Intents that Shortcuts/NFC call
  Info.plist, *.entitlements, Assets.xcassets
SETUP.md                    Full phone-side setup walkthrough
```

## License

MIT
