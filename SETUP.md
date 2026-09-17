# Phone setup walkthrough

Do these once, in order, after installing the app from Xcode. ~15 minutes.

## 1. Configure the app

1. Open **Boring Phone**, grant the Screen Time permission.
2. Tap **Choose allowed apps** and select what stays usable in boring mode:
   WhatsApp, Safari, Camera, Maps — whatever you decided. (Phone, Messages
   and Settings are system apps iOS never blocks, so don't worry about them.)
   **Important: also select Boring Phone itself and the Shortcuts app** —
   otherwise the app shields itself and your escape hatches along with
   everything else.

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

## 3. Create the NFC automation (the magic part)

1. Open **Shortcuts → Automation → + → NFC**.
2. Tap **Scan** and hold your phone on your NFC tag. Name it "boring tag".
   *iOS ties this automation to this exact physical tag — someone else's tag
   won't trigger it. That's your "specific tag only" requirement, handled by
   the OS.*
3. Choose **Run Immediately** (not "Run After Confirmation"), notify off.
4. Add actions, in this order:
   - **Toggle Boring Mode** (from the Boring Phone app)
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
   automation → run its **Toggle Boring Mode** action manually. The app has
   no off switch of its own on purpose — this is the sanctioned back door.
2. **Any new NFC tag**: Shortcuts → Automation → + → NFC → scan the new tag
   → add the Toggle Boring Mode action. Tags are ~€1; better yet, register
   a **backup tag now** and keep it in a drawer.
3. **Settings → Screen Time** (Settings is never blockable): revoke Boring
   Phone's Screen Time access, or delete the app — either clears the shield.
   Blocked by the hardening passcode? That's it doing its job: whoever holds
   the passcode can undo it.
4. Nuclear: reinstall from Xcode — a fresh install starts with the shield off.
