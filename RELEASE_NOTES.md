# Release Notes

## Riff app

### Dark mode fixes
- **Action sheets now respect dark mode.** The post options sheet, the reels comment sheets, and the share sheet were rendering with a white background in dark mode. They now use the theme surface color, with theme-aware drag handles and text/icon colors.
- **Edit Post screen is fully dark-mode aware.** Removed the hardcoded white AppBar (it now follows the theme), and made the content card, media picker sheet, empty-state placeholder, "add more" cell, and sheet tiles adapt to light/dark.

### Theme persistence
- **Theme choice is remembered between launches.** Your light/dark selection is saved and restored the next time you open the app.
- **First install follows the phone.** Before you've made a choice, the app matches your device's system light/dark setting. The drawer toggle now resolves the effective brightness, so it flips correctly even from system mode.

### Editing a shared post
- **Opening Edit on a shared post now shows your caption and a preview of the shared post.** You can edit the caption you wrote above the share; the original post is shown as a read-only preview and the media picker is hidden (shares don't carry their own media).

## Backend (API)
- No functional changes shipped. (An "unshare" endpoint flag was prototyped during development and then reverted, so `PATCH /api/posts/:id` is unchanged.)

## Commercial dashboard (macOS)
- **Fixed "Connection failed" on macOS login.** The macOS app is sandboxed but was missing the network-client entitlement, so all outbound API calls were blocked. Added `com.apple.security.network.client` to both the Debug and Release entitlements.
- **Allowed the local HTTP dev API.** Added an App Transport Security exception so the app can reach the cleartext `http://` development server. (Development only — tighten before shipping.)
- Note: these are build-level changes, so a full app restart/rebuild is required for them to take effect.
