# Phone setup walkthrough

Do these once, in order, after installing the app from Xcode. ~15 minutes.

## 1. Configure the app

1. Open **Boring Phone**, grant the Screen Time permission.
2. Tap **Choose allowed apps** and select what stays usable in boring mode:
   WhatsApp, Safari, Camera, Maps — whatever you decided. (Phone, Messages
   and Settings are system apps iOS never blocks, so don't worry about them.)
   **Important: also select Boring Phone itself and the Shortcuts app** —
   otherwise the app shields itself and your escape hatches along with
   everything else. iOS's app picker doesn't let anyone (including us)
   pre-select or lock in specific apps here — it's a genuine platform
   restriction, not something we chose — so this has to be a manual, careful
   step each time you re-pick your apps.

   **If you forget anyway, you're not stuck.** Settings can never be
   shielded by iOS — no exceptions. `Settings → Screen Time → Boring Phone →
   Stop Using Screen Time` (or delete the app) instantly clears every
   shield, tag or no tag. Keep this in your back pocket; you won't need it
   if you do step 2 correctly, but it means a mistake here is never
   permanent.

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

1. Open **Shortcuts** (the in-app "Open Shortcuts" button on Boring Phone's
   main screen jumps straight there) → **Automation → + → NFC**.
2. Tap **Scan** and hold your phone on your NFC tag. Name it "boring tag".
   *iOS ties this automation to this exact physical tag — someone else's tag
   won't trigger it. That's your "specific tag only" requirement, handled by
   the OS.*
3. Choose **Run Immediately** (not "Run After Confirmation"), notify off.
4. Add actions, in this order:
   - **Toggle Boring Phone** (from the Boring Phone app) — search "Boring"
     if it doesn't show up immediately. Two things cause it to be missing:
     you haven't opened the Boring Phone app on this device yet (iOS only
     indexes an app's actions after its first launch — open it once, then
     come back), or, rarely, the phone needs a restart for a freshly
     installed app's actions to register.
   - **Set Focus**: Toggle **Boring** Focus
5. Save. Done.

**Test:** tap the phone on the tag → shield goes up, home screen collapses to
the minimal page, and the app's status screen shows **LOCKED**. Tap again →
everything back, status shows **UNLOCKED**.

Before wiring the tag, you can sanity-check the shield alone: in the
Shortcuts app, open the "boring tag" automation and tap the **Toggle Boring
Mode** action's play button, or run it from My Shortcuts if you saved a
duplicate there. It flips the same intent the tag does — useful for
verifying the app picker worked before you trust it to a tap.

## 4. Hardening (optional, recommended)

Make cheating annoying enough that you won't bother:

1. **Settings → Screen Time → Lock Screen Time Settings** — set a Screen Time
   passcode. Best: have a partner/friend set it so you don't know it, or use
   a random code stored somewhere inconvenient (paper in a drawer at home).
2. **Settings → Screen Time → Content & Privacy Restrictions → iTunes & App
   Store Purchases → Deleting Apps → Don't Allow** — now you can't delete
   the Boring Phone app to escape the shield.

Remaining escape hatches (deliberately not closed — this is a commitment
device, not a prison): you could still open Shortcuts and run the toggle
manually, or delete the automation. If even that tempts you, put the
Shortcuts app itself outside your allowed list so it's shielded in boring
mode. Careful: then *only* the tag can save you — don't lose the tag.

## 5. Daily use

- Stick the tag somewhere meaningful: front door, desk, kitchen drawer.
- Tap when you want your life back from the phone. Tap again when you need
  a real phone.
## 6. Lost the tag? Escape routes, easiest first

1. **Shortcuts app** (you kept it allowed, right?) → open the "boring tag"
   automation → run its **Toggle Boring Phone** action manually. The app has
   no off switch of its own on purpose — this is the sanctioned back door.
2. **Any new NFC tag**: Shortcuts → Automation → + → NFC → scan the new tag
   → add the Toggle Boring Phone action. Tags are ~€1; better yet, register
   a **backup tag now** and keep it in a drawer.
3. **Settings → Screen Time** (Settings is never blockable): revoke Boring
   Phone's Screen Time access, or delete the app — either clears the shield.
   Blocked by the hardening passcode? That's it doing its job: whoever holds
   the passcode can undo it.
4. Nuclear: reinstall from Xcode — a fresh install starts with the shield off.
