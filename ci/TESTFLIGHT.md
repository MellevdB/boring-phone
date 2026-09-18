# TestFlight release process

## One-time prerequisites (you, not me — see below)

1. **App Store Connect app record.** appstoreconnect.apple.com → My Apps → **+**
   → New App → iOS → Name "Bored Phone" → Bundle ID `com.melle.boringphone`
   → any SKU. Our API key can't create this (needs Admin role), so this step
   is manual, once.
2. **Family Controls (Distribution) entitlement approval from Apple.**
   Request it at
   https://developer.apple.com/contact/request/family-controls-distribution.
   This is separate from the paid membership — it's Apple manually approving
   this specific restricted entitlement for a distributed build. Until it's
   approved, the upload in step 3 will fail App Store Connect's binary
   validation (ITMS error mentioning `family-controls`). Turnaround is
   typically same-day to a few days.
3. Sign in to Xcode once with your Apple ID and confirm the "Melle van der
   Brugge" paid team appears (already done as of this writing).

## Releasing a build

```sh
ci/release_to_testflight.sh
```

This archives, exports with an App Store Connect distribution profile, and
uploads using the App Store Connect API key at
`~/.claude-secrets/appstoreconnect/`. Takes a few minutes to build, then
5-20 minutes for Apple to process the upload before it's testable.

## Adding your friends as testers

TestFlight has two tiers:

- **Internal testers**: people added as *Users* on your App Store Connect
  account (Users and Access → +). No beta review needed, builds available
  instantly, but they must accept an invite to join your team — a bit much
  for friends who just want to try an app.
- **External testers** (what you want): add by email under TestFlight →
  your app → **External Testing** → a group (e.g. "Friends") → add testers.
  **The first build submitted for external testing needs a one-time,
  lightweight Beta App Review** (usually hours, not the full App Store
  review) — after that, new builds to the same group go out instantly.

Once the app record exists, I can add tester emails and create the testing
group via the API — just give me the list of emails.

## Privacy Policy & Support links

Required by App Store Connect's beta app info (and later, full App Store
submission). Hosted as static pages at `docs/privacy.html` and
`docs/support.html` in this repo, served via **GitHub Pages** (enabled on
this repo, source: `main` branch, `/docs`):

- Privacy: https://mellevdb.github.io/boring-phone/privacy.html
- Support: https://mellevdb.github.io/boring-phone/support.html

Both URLs are already set on the app's `betaAppLocalizations` record via the
API (feedback email, marketing URL, privacy policy URL, and a beta
description). Beta review contact info (name, email, phone) and reviewer
notes are set on `betaAppReviewDetails`. Editing either page: edit the file
in `docs/`, commit, push — GitHub Pages rebuilds automatically within a
minute or two.

## Renewing

Distribution builds signed with a paid account are valid for a full year
(vs. 7 days on a free account), and TestFlight builds themselves expire
90 days after upload — just rerun the script above to refresh.
