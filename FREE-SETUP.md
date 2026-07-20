# Free version — boring phone without the app

Apple only allows the app-blocking API (Family Controls) for paid Apple
Developer Program members (€99/yr). The free version skips the app entirely:

- **NFC tag → toggles the boring layout + silence** (Focus mode, via Shortcuts)
- **Hard blocking is always-on** (Screen Time limits with a passcode) instead
  of tag-controlled

Tap the tag: minimal home screen, notifications silenced. Tap again: normal
layout back. The distracting apps stay limited either way.

## A. Minimal home screen page

1. Long-press the home screen → swipe to a new empty page.
2. Add only: Phone, Messages, WhatsApp, Safari (+ Camera, Maps if you want).
3. Optional: plain black wallpaper, no widgets.

## B. "Boring" Focus

1. **Settings → Focus → + → Custom** → name it **Boring**.
2. **People**: allow calls from Favorites (or everyone if you prefer).
3. **Apps**: allow notifications only from Phone, Messages, WhatsApp.
4. **Customize Screens → Home Screen**: enable page filtering, tick **only**
   the minimal page from step A.

## C. NFC tag → toggle the Focus (no app needed)

1. **Shortcuts → Automation → + → NFC → Scan** → hold the phone on your tag.
2. Name it "boring tag". iOS binds the automation to this exact physical tag.
3. **Run Immediately**, notifications off.
4. Action: **Set Focus → Boring → Toggle**.

Test: tap phone on tag → minimal page + silence. Tap again → normal phone.

## D. Hard blocking (always-on)

Pick one flavor:

### Flavor 1 — block the bad apps (recommended)

1. **Settings → Screen Time → App Limits → Add Limit**.
2. Expand the categories and tick the individual apps that eat your life
   (Instagram, TikTok, YouTube, Reddit, games…). Don't tick whole categories
   if an allowed app (like WhatsApp, in Social) lives inside one.
3. Set the limit to **1 minute**, enable **Block at End of Limit**.

### Flavor 2 — allow-list only (strictest)

1. **Settings → Screen Time → Downtime** → schedule it all day
   (e.g. 00:00–23:59, every day).
2. **Always Allowed** → add WhatsApp, Safari, Camera, Maps.
   (Phone and Messages are always available anyway.)
3. Now *everything else* is blocked around the clock.

### Lock it in (both flavors)

- **Screen Time → Lock Screen Time Settings** → set a passcode. Ideally
  someone else sets it, or you store it somewhere inconvenient. Without this,
  "Ignore Limit" is one tap and the whole thing is theatre.

## Upgrading later

Enroll at [developer.apple.com](https://developer.apple.com/programs/) →
in Xcode pick the new (non-Personal) team → the Family Controls signing
error disappears → install the app → follow [SETUP.md](SETUP.md). Then
blocking becomes tag-controlled too, and you can delete the App Limits.
