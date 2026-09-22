# Phone setup walkthrough

Do these once, in order, after installing the app from Xcode. ~15 minutes.

## 1. Configure the app

1. Open **Bored Phone**. It shows a short explainer before asking for
   Screen Time permission — tap **Continue** there, then on Apple's own
   system dialog choose **Continue**/**Allow**. We can't change that
   system dialog's layout or colors (it's entirely Apple's), which is
   exactly why the app explains it first.
2. Tap **Choose allowed apps** and select what stays usable in boring mode:
   WhatsApp, Safari, Camera, Maps — whatever you decided. (Phone, Messages
   and Settings are system apps iOS never blocks, so don't worry about them.)
   Two things about this picker that are just how it is, not bugs:
   - It lists apps and websites generally known to Apple, not only ones
     installed on this phone — that's inherent to the same privacy design
     that keeps the picker from leaking your installed-apps list to any
     app, ours included. Anything you don't recognize is harmless to skip.
   - You *can* tap "Select All" and then deselect the ones you want kept —
     but tapping each app you actually want individually keeps the allow
     list small on purpose, which is the whole point.

   **Important: also select Bored Phone itself and the Shortcuts app** —
   otherwise the app shields itself and your escape hatches along with
   everything else. iOS's app picker doesn't let anyone (including us)
   pre-select or lock in specific apps here — it's a genuine platform
   restriction, not something we chose — so this has to be a manual, careful
   step each time you re-pick your apps. (The app hides its own reminder
   about this automatically once it can confirm both are selected.)

   **If you forget anyway, you're not stuck** — see §6 for how to recover.
   It's deliberately not a one-liner here: easy-to-find unlock instructions
   would defeat the entire point of this app.

There is deliberately no on/off switch in the app itself — locking and
unlocking only ever happens through the NFC automation in the next section.
You'll do your first real test there.

## 2. Create the "Boring" Focus (the different layout)

1. First build the minimal home screen page: long-press the home screen →
   swipe to a new empty page → add only your allowed apps (Phone, Messages,
   WhatsApp, Safari…). Optional but recommended: plain black wallpaper, no
   widgets. Keep your normal pages as they are.
2. **Settings → Focus → + → Custom** → name it **Boring**, give it the ⛔ icon.
3. Under **People**: allow calls/messages from everyone you actually want to
   reach you (or Favorites only).
4. Under **Apps**: allow notifications only from Phone, Messages, WhatsApp.
5. Under **Customize Screens → Home Screen**: enable page filtering and tick
   **only** your minimal page. Now when Boring Focus is on, every other home
   screen page disappears.

**This step is cosmetic, not the lock.** No app — ours included — can
rearrange your home screen or build this for you automatically; iOS gives
zero API for that, so it's manual every time. The layout just reduces
temptation. The actual blocking is the Screen Time shield from step 1,
which works independently of what you can see: with Boring Focus on, a
blocked app's icon can still turn up in the **App Library** or **Spotlight
search** (Focus filtering doesn't hide those), but tapping it from
anywhere — home screen, App Library, search, a notification — shows
Apple's block screen regardless. You can *see* the app exists; you can't
*open* it.

## 3. Create the NFC automation (the magic part)

1. Open **Shortcuts** (the in-app "Open Shortcuts" button on Bored Phone's
   main screen jumps straight there) → **Automation → + → NFC**.
2. Tap **Scan** and hold your phone on your NFC tag. Name it "boring tag".
   *iOS ties this automation to this exact physical tag — someone else's tag
   won't trigger it. That's your "specific tag only" requirement, handled by
   the OS.*
3. **Important:** after the tag is scanned, tap **"Create New Shortcut"** —
   do **not** tap an app suggestion (like a Bored Phone icon) that iOS
   offers here. Tapping an app suggestion skips straight to a single
   one-action shortcut, and you won't be able to add the second action
   below. "Create New Shortcut" opens the full editor.
4. Choose **Run Immediately** (not "Run After Confirmation"), notify off.
5. Add actions, in this order:
   - **Toggle Bored Phone** (from the Bored Phone app) — search "Bored"
     if it doesn't show up immediately. Two things cause it to be missing:
     you haven't opened the Bored Phone app on this device yet (iOS only
     indexes an app's actions after its first launch — open it once, then
     come back), or, rarely, the phone needs a restart for a freshly
     installed app's actions to register.

     If instead you get **"Something went wrong, try again"** while adding
     it: this is a known iOS bug with stale App Intents metadata, most
     common right after an app's actions were renamed across a few
     incremental reinstalls. Fix: fully **delete** the app (not just
     reinstall over it) → **restart the phone** → reinstall fresh from
     Xcode → open it once → try adding the action again. A plain overwrite
     install usually isn't enough to clear this.
   - **Set Focus** → pick the **Boring** Focus you made in §2, and set the
     action's own mode to **Toggle** — not "Turn On". Leaving it on "Turn
     On" means tapping the tag a second time won't switch your layout back,
     even though the app's shield does — the same physical tap needs to
     flip both.
6. Save. Done.

**Test:** tap the phone on the tag → shield goes up, home screen collapses to
the minimal page, and the app's status screen shows **LOCKED**. Tap again →
everything back, status shows **UNLOCKED**.

Before wiring the tag, you can sanity-check the shield alone: in the
Shortcuts app, open the "boring tag" automation and tap the **Toggle Bored
Phone** action's play button, or run it from My Shortcuts if you saved a
duplicate there. It flips the same intent the tag does — useful for
verifying the app picker worked before you trust it to a tap.

## 4. Strict Mode (built in, automatic)

While the phone is locked, the app automatically turns on three extra
restrictions — no toggle needed, no separate hardening step:

- **Can't delete the app** — the long-press "Remove App" option disappears
  for Bored Phone (and everything else) while locked.
- **Can't change accounts** — adding/removing Mail, Contacts, or iCloud
  accounts is blocked, closing one common workaround.
- **Can't manually change the date/time** — this specifically protects the
  24-hour emergency wait in §6 from the classic "just set the clock forward"
  trick.

**The honest limit, straight from Apple's own developer forum:** none of
this is an absolute guarantee. `denyAppRemoval` "isn't guaranteed to
prevent app deletion with `.individual` authorization, since `.individual`
authorizations can be revoked at any time via Settings" — Apple deliberately
keeps `Settings → Screen Time → Bored Phone → Stop Using Screen Time`
open for *any* self-installed app, specifically so an app you installed
yourself can never permanently imprison your device (imagine the opposite:
a piece of malware that could lock itself in place forever). True
tamper-proof enforcement only exists for supervised/child devices under
Family Sharing, which isn't what a personal focus app should require.

So: Strict Mode stops the *casual* "long-press and delete" impulse and the
naive clock trick, but the Settings route always remains — same as it
always has. Optional extra step if you want more friction on top:

- **Settings → Screen Time → Lock Screen Time Settings** — set a Screen
  Time passcode. Best: have a partner/friend set it so you don't know it,
  or use a random code stored somewhere inconvenient (paper in a drawer at
  home). This doesn't close the Settings route either — it just means
  whoever holds the passcode has to be involved.

## 5. Daily use

- Stick the tag somewhere meaningful: front door, desk, kitchen drawer.
- Tap when you want your life back from the phone. Tap again when you need
  a real phone.
## 6. Lost the tag? Recovery, by design, is not easy

If you're locked out (tag at home, you're at work) there is a real way
back — but it's deliberately gated, not a quick tip in this file. On the
locked screen, under the status card, there's a small, low-key **"I lost my
NFC tag"** link. Tapping it walks you through:

1. A prompt to actually go check your pockets/bag/desk again.
2. An honesty check: is this a real emergency, or is scrolling just feeling
   urgent right now?
3. **A genuine 24-hour wait** — not app-open time. It's timestamped and
   persisted, so it survives closing the app, restarting your phone, or
   never opening Bored Phone again until the 24 hours are up. It's also
   checked against your phone's own uptime clock, so setting the date
   forward in Settings doesn't skip it (Strict Mode in §4 blocks that
   directly anyway, while locked).
4. Once the 24 hours pass, reopen the same link: a real **"Unlock Bored
   Phone now"** button appears and unlocks it immediately, right there —
   no need to go anywhere else. You can also cancel a pending request at
   any point if you change your mind, which doesn't unlock anything early,
   it just stops the clock.

That's on purpose. If the instructions were easy to find, "I locked myself
out and I'm at work" would become the standard excuse to undo the entire
point of this app. Use it when you mean it.

Worth being upfront about: this 24-hour gate applies to the path *this app
teaches*. It can't gate the `Settings → Screen Time → Stop Using Screen
Time` route itself — as covered in §4, Apple keeps that always available
for any self-managed app, and it requires no special knowledge once
someone's used Screen Time before. The wait exists to raise the bar on the
route most people will actually take, not to claim a technical impossibility
that iOS doesn't allow any app to make.

Other recovery routes, for completeness:

- **Any new NFC tag**: Shortcuts → Automation → + → NFC → scan the new tag
  → add the Toggle Bored Phone action. Tags are ~€1; register a **backup
  tag now** and keep it somewhere you won't carry both at once (a drawer at
  home, not your other pocket).
- Blocked by the hardening passcode from §4? That's it doing its job —
  whoever holds the passcode can undo it; that's the whole design.
- Nuclear: reinstall from Xcode — a fresh install starts with the shield off.
