# App Store review reply — Guideline 2.1 Information Needed

Rejection on submission `a29c3a99-31c7-4b07-b1cd-bbf3c29c7db2` (Riff 1.0.14, app id
6794351030). Nothing is wrong with the binary — Apple could not review it because the
**App Review Information** section was left thin. The fix is entirely in App Store
Connect: fill the Notes field, add a demo account, attach a screen recording, and reply
in Resolution Center.

Two things must be done by hand before replying — the screen recording (§3) and the
device list (§2, item 8). Everything else is below, ready to paste.

---

## 1. Paste into App Store Connect → App Review Information → Notes

Fill in every `[…]` before pasting. Then paste the same text as the Resolution Center
reply, with the screen recording attached.

---

## 2. The notes text

```
RIFF — APP REVIEW INFORMATION

=== DEMO ACCOUNT ===
Email:    [demo@…]
Password: […]

Second account, for testing chat, following and follow requests:
Email:    [demo2@…]
Password: […]

There is only one account type. Every account has identical capabilities —
there are no roles, tiers, paid accounts or region-locked accounts.
No sample files are needed; the demo account is pre-populated with posts,
followers and a conversation.

=== 1. WHAT THE APP DOES, AND FOR WHOM ===
Riff is a free social network for musicians and music fans.

Problem it solves: musicians who want to share what they are playing,
practising or listening to have to spread it across general-purpose social
apps that know nothing about instruments, genres or what someone is listening
to right now. Riff is built around that: every profile carries the
instruments the person plays and the genres they are into, and can show the
Spotify track they are currently listening to.

Value: a feed, short-form video ("reels"), and direct and group messaging,
all scoped to a music audience, with discovery driven by instrument and genre
rather than by generic interests.

Target audience: musicians (amateur and professional), music students, and
music fans, aged [match this to the age rating set in App Store Connect]+.
The app is worldwide and ships in English and Arabic.

The app is free. There are no in-app purchases, no subscriptions, and no paid
content or paid features of any kind. No purchase or subscription flow exists
in the app.

=== 2. HOW TO SET UP AND REACH EVERY CORE FEATURE ===
Launch → onboarding carousel → Log in.
Sign in with the demo credentials above, or tap "Sign up" to create a new
account with an email address and password, or use "Continue with Google".
On first launch after signing in, the app shows a privacy policy screen that
must be accepted before continuing.

A newly created account then goes through onboarding: profile picture,
instruments, genres, and suggested people to follow.

From the home screen:
• FEED — the home tab. Posts with photos and video, like, comment, share.
• CREATE A POST — the "+" button in the bottom bar. Pick photos or videos
  from the library or capture with the camera, add a caption, publish.
• REELS — the reels tab. Vertically swiped short videos.
• SEARCH / DISCOVER — the search tab. Find people and posts, filter by
  instrument and genre.
• CHAT — the message icon in the top bar. Direct messages and group chats;
  send text, photos, videos and voice notes. Long-press a message to react,
  edit, reply or delete.
• NOTIFICATIONS — the bell icon: likes, comments, follows, follow requests.
• PROFILE — the profile tab. Your posts, followers, following, instruments,
  genres, and "Connect Spotify".
• SIDE DRAWER (top-left) — Settings, Account settings, Change password,
  Privacy settings (public / private account), Blocked users, Privacy policy,
  About us, Report a bug, Request a feature, Log out.
• DELETE ACCOUNT — Side drawer → Account settings → Delete account. The screen
  lists exactly what is removed and asks for the account password (or, for
  accounts created with Google, for the user's own username) plus a final
  confirmation. Deleting is immediate and permanent: the profile, posts,
  reels, comments, likes, messages, followers and uploaded media are all
  removed and the app returns to the login screen.

=== 3. EXTERNAL SERVICES USED ===
• Riff's own backend API — NestJS + PostgreSQL, hosted on Railway. Serves all
  app data: accounts, posts, comments, follows, messages, notifications.
• Google Sign-In (Google OAuth) — optional sign-in method.
• Cloudinary — storage and CDN for user-uploaded photos, videos, voice notes
  and profile pictures.
• Firebase Cloud Messaging — push notifications only. No Firebase Analytics,
  no Crashlytics, no advertising SDK.
• Spotify Web API — optional, opt-in per user. If the user taps "Connect
  Spotify" on their own profile, the app runs the standard Spotify OAuth
  (PKCE) consent flow and requests two read-only scopes,
  user-read-currently-playing and user-read-playback-state. It is used solely
  to display the title, artist and cover art of the track the user is
  currently playing on Spotify. The app never streams, plays, downloads,
  caches or redistributes any Spotify audio, and the user can disconnect at
  any time from their profile. Riff works fully without connecting Spotify.

There are NO payment processors, NO advertising networks, NO analytics or
tracking SDKs, NO AI or machine-learning services, and NO third-party data
providers.

=== 4. PERMISSION PROMPTS THE APP SHOWS ===
• Camera — only when the user chooses to take a photo or video for a post,
  a chat message, or a profile picture.
• Photo library — only when the user chooses to attach an existing photo or
  video to a post, chat message, or profile picture.
• Microphone — only when the user records a voice note in a chat.
• Push notifications — requested after sign-in, for likes, comments, follows
  and new messages.

The app does NOT request location, contacts, calendar, health data, Bluetooth,
or App Tracking Transparency. It does not track users across apps or websites
and collects no data for advertising.

=== 5. USER-GENERATED CONTENT, REPORTING AND BLOCKING ===
All content in the app is user-generated: posts, reels, comments and chat
messages. The moderation controls are:

• REPORT A POST — "…" menu on any post → Report → pick a reason → Submit.
• REPORT A COMMENT — long-press / "…" on a comment → Report.
• REPORT A USER — "…" menu on any user's profile → Report.
  Every report goes to a moderation queue reviewed by the developer, and the
  author is notified when their content is flagged.
• BLOCK A USER — "…" menu on any user's profile → Block. A blocked person
  cannot message the user or see their content. Blocked accounts are listed
  and can be unblocked at Drawer → Blocked users.
• DELETE YOUR OWN CONTENT — "…" menu on your own post → Delete;
  long-press your own message → Delete.
• PRIVATE ACCOUNT — Account settings → Privacy: make the account private so
  only approved followers see its content.

=== 6. REGIONAL DIFFERENCES ===
None. The app behaves identically in every region and App Store storefront.
There is no geo-gated, geo-restricted or region-specific content, no
region-specific pricing (the app is free everywhere), and no feature that is
enabled or disabled by country. The only localisation is language: the
interface is available in English and in Arabic (right-to-left), following the
device language; the user can also switch language in Settings. Content itself
is whatever users post, worldwide.

=== 7. REGULATED INDUSTRY / PROTECTED THIRD-PARTY MATERIAL ===
Riff does not operate in a regulated industry. It is not a financial, medical,
gambling, HIPAA-covered, pharmaceutical, or telehealth product.

The only third-party material shown is Spotify track metadata (title, artist,
cover art) for the signed-in user's own currently-playing track, retrieved
through the official Spotify Web API after that user grants consent through
Spotify's own OAuth screen, under the Spotify Developer Terms of Service. No
audio is streamed, played, stored or redistributed by Riff. No other
third-party or licensed material is included in the app.

=== 8. DEVICES AND OS VERSIONS TESTED ===
Tested on physical devices before submission:
• [iPhone …, iOS …]
• [iPhone …, iOS …]
• [iPad …, iPadOS …  — or delete this line if iPad is not supported]
Minimum supported version: iOS 15.0.

=== CONTACT ===
[your name] — [your email]
```

---

## 3. The screen recording

Apple asked for one recording, made on a **physical device running the latest iOS**,
starting from the app launching. One continuous take is fine and is what they prefer.
Cover, in this order:

1. Launch from the home screen (show the icon being tapped).
2. **Sign-up** — create a brand-new account with email + password, accept the privacy
   policy, and go through onboarding (profile picture → instruments → genres →
   suggested users). This is where the **camera / photo library** prompt appears —
   let it show on screen.
3. **Push notification prompt** — let it appear, allow it.
4. Log out, then **log in** with the demo account.
5. Feed: scroll, like, open comments, post a comment.
6. Create a post with a photo, publish it, show it in the feed, then delete it.
7. Reels: swipe through a couple.
8. Search / discover: find a user, open their profile, follow them.
9. Chat: open a conversation, send a text, send a photo, record a **voice note**
   (this is the microphone prompt).
10. **Report** a post (open the reason list and submit) and **report** a comment.
11. **Block** a user from their profile, then show Drawer → Blocked users and unblock.
12. **Account deletion** — the account you created in step 2, not the demo account.
    Drawer → Account settings → Delete account, read the warning, enter the
    password, confirm, and show that the app lands back on login and that the
    same credentials no longer work. Apple explicitly asked for this flow.
13. Show that there is no paid content anywhere — there is no purchase flow to record.

Record with iOS Screen Recording, then trim. Upload it to a link Apple can open
(Google Drive / Dropbox, sharing set to "anyone with the link") and paste that link
into the Resolution Center reply, since the notes field itself takes text only.

---

## 4. In-app account deletion (built for 1.0.15)

Guideline 5.1.1(v) requires any app with account creation to let people delete the
account **from inside the app**; the previous release only had a web page telling
users to email support, which does not satisfy it. That is now built on both sides.

**In the app:** Drawer → Account settings → **Delete account**. The screen states what
is removed, then re-authenticates before anything happens — the account password, or,
for accounts created through Google that have no password, the user's own username
typed back. A final confirmation dialog follows. On success the app runs the normal
sign-out teardown (stored credentials cleared, app-lifetime singletons reset, the
per-user offline cache wiped) and returns to login with an empty stack.

**On the API:** `DELETE /api/users/me` re-checks the confirmation, flags shares of the
user's posts as `original_post_deleted` while the foreign key still points somewhere,
deletes their direct conversations, then hard-deletes the user row — nearly every FK
into `users` is `ON DELETE CASCADE`, so that removes posts, comments, likes, follows,
messages, reactions, blocks, notifications and post views in one transaction.
Cloudinary assets are then deleted best-effort, deliberately outside the transaction:
an image-host outage must not report failure for a deletion that already happened.

**Deployment note:** this needs the API deployed to Railway before the build reaches
review. A reviewer tapping Delete account against the old API gets a 404, which is a
worse rejection than not having the feature. Deploy the API first, verify
`DELETE /api/users/me` responds, then submit the build.

---

## 5. Spotify: one thing left that is not in the code

Three real bugs were fixed for 1.0.15 (see the release notes below), but there is a
fourth cause that lives in your Spotify Developer Dashboard and **cannot be fixed from
this repo**. Check it before you submit.

**Development Mode.** A Spotify app that has not been granted extended quota is in
Development Mode, where only Spotify accounts explicitly added to its allowlist
(25 max) can authorise it. Every other account is rejected at the authorize step. If
that is the current state, then:

- every tester who is not on the allowlist sees "Connect Spotify" fail — which matches
  the symptom you described;
- **the App Review reviewer will fail too**, because their Spotify account is
  certainly not on your allowlist.

What to do, at <https://developer.spotify.com/dashboard> → your app → Settings:

1. Confirm the redirect URI is exactly `com.riff.app://spotify-callback`. The app,
   `ios/Runner/Info.plist` and `android/app/build.gradle.kts` all already agree on it;
   the dashboard is the fourth place that has to match.
2. Check whether the app shows Development Mode. If it does, either request extended
   quota (Spotify reviews it, so allow time) **or** add the reviewer's Spotify account
   to the allowlist — which you can't, since you don't know it.
3. Given (2), the safe move for this submission is to tell the reviewer in the notes
   that Spotify is an optional extra requiring their own Spotify account, and that
   every core feature works without it. Text for that is in the notes block above
   under external services.

After 1.0.15, a failed connect shows Spotify's own error text in a snackbar instead of
silently doing nothing — so if it still fails on a real device, the message on screen
will say which of these it is.

---

## 6. Also worth doing before you resubmit

- **Screenshots (Guideline 2.3.3).** The rejection letter's tips section calls this out.
  Make sure the App Store screenshots show the feed, reels, chat and a profile in use —
  not the splash screen or the login page.
- **Keep the demo account alive.** Do not delete or rotate the password on the demo
  accounts while review is in progress, and make sure they have content: a few posts,
  some followers, and at least one conversation with message history. A reviewer landing
  on empty screens is how "we could not review it" happens again.
- **Fill the notes for good.** Apple's last line asks for this information to be in the
  Notes field for *future* submissions — leave the §2 text there permanently and update
  the device list each release.
- **Don't let the reviewer delete the demo account.** The recording should delete a
  throwaway account you create on camera, not the demo login you gave Apple. If a
  reviewer follows the flow on the demo account itself, the credentials in App Store
  Connect stop working and the next reviewer is locked out.

---

## 7. Release order for 1.0.15

The version is bumped to `1.0.15+10015`. Do these in order — the middle step is the
one that bites if skipped.

1. **Deploy the API to Railway** and confirm `DELETE /api/users/me` is live. The build
   depends on it; shipping the app first means a reviewer's Delete account tap 404s.
2. **Build and upload** with the Spotify client id, as always:

```bash
flutter build ipa --release --flavor production -t lib/main_production.dart --dart-define=SPOTIFY_CLIENT_ID=5bf7c19bb7b84c8cb8af0128fa7c59eb
```

   Or let Xcode Cloud do it — `ios/ci_scripts/ci_post_clone.sh` already passes the
   define and sets the build number from `CI_BUILD_NUMBER`.
3. **Record the video** on a physical device (§3), including the deletion flow.
4. **Fill App Review Information** with the §2 notes and the demo credentials.
5. **Reply in Resolution Center** with the notes plus the video link.
