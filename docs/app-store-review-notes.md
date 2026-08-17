# App Store review reply — Guideline 2.1 Information Needed

Rejection on submission `a29c3a99-31c7-4b07-b1cd-bbf3c29c7db2` (app id 6794351030).
The block below answers all seven items Apple listed. Paste it into **App Store
Connect → App Review Information → Notes**, and send the same text as the Resolution
Center reply with the screen-recording link attached — Apple's closing line asks for
this information to stay in the Notes field for future submissions, so leave it there
once it's in.

```
RIFF — APP REVIEW INFORMATION

=== DEMO ACCOUNT ===
Email:    [demo account email]
Password: [demo account password]

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
music fans. The app is worldwide and ships in English and Arabic.

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
The app was tested on the following physical devices before submission:
• [iPhone model, iOS version]
• [iPhone model, iOS version]

Minimum supported version: iOS 15.0.

=== CONTACT ===
Magd Kamal — zakymagd@gmail.com
(Developer contact. Not the demo account — see above.)
```

---

## Three blanks to fill when you paste

The credentials and the device list are deliberately placeholders in this file. Fill
them in **when you paste into App Store Connect**, not here — this file is committed
and pushed, and a live demo password does not belong in a git repository where
rewriting history later won't reliably remove it.

**1. The demo account — and make it a throwaway.** Do not hand Apple your own account
(`zakymagd@gmail.com` is the developer contact). The recording demonstrates the account
deletion flow, and a reviewer who repeats it on the demo login deletes that account for
real: the credentials stop working and the next reviewer is locked out, which is its
own rejection.

Create a separate account that holds nothing you care about and shares its password
with nothing else, then populate it — a few posts, some followers, and one conversation
with message history. A reviewer landing on empty screens is how "we could not review
it" happens a second time.

**2. Section 8, devices and OS versions.** Apple's item 2 asked for "a list of the
device models and operating systems the app was tested on". This is a claim about
testing you actually performed, so it has to be yours to write. It should include the
device the screen recording was captured on.

**3. The recording link** goes in the Resolution Center reply, not in this block —
the Notes field is plain text. Confirm the link opens in a private browser window
first: a reviewer will not sign in or request access, and a locked link reads exactly
like no video at all.