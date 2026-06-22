# Riff – Release Notes v1.0.10

*What's New in Riff*

---

## Welcome to Riff

Riff is a music-social app built for people who live and breathe music. Share what you're listening to, discover what your people are into, and connect through the universal language — sound.

---

## Features

### Music-First Social Feed
- Post reels, videos, and images centered around music moments
- Scroll a full-screen reel feed — think music content, not noise
- Like, comment, and engage with posts from people you follow

### Social Sharing — Bring Music From Anywhere
- Share directly into Riff from **Spotify**, **TikTok**, and **Instagram**
- Link a Spotify track, playlist, or artist straight from the Spotify app
- Share a TikTok or Instagram reel and it lands ready to post in Riff

### Spotify Integration
- Connect your Spotify account
- Show what you're listening to right now

### Messaging — DMs & Group Chats
- Direct messages with full media support (images, videos, voice notes)
- **Group chats** — create a group with a name, photo, and description
- Add members when creating a group or manage them later
- **Voice notes** — hold to record, send instantly
- Read receipts and typing indicators

### Group Management
- Group admins can update the group name, description, and photo anytime
- Clear admin badge so everyone knows who runs the group
- Members list with profile photos in the group details screen

### Push Notifications
- Real-time push notifications for messages, likes, and activity
- Powered by Firebase — delivered even when the app is closed

### Authentication
- Sign in with Google or email/password
- Secure JWT authentication with automatic token refresh — you stay logged in

---

## Bug Fixes & Improvements

- Fixed: voice notes occasionally appeared twice after sending — now shows once, always
- Fixed: editing a group name or description no longer crashes on close
- Fixed: sharing from Spotify or TikTok no longer causes a white/frozen screen
- Improved: shares from backgrounded apps now open the create post screen reliably
- Improved: automatic session recovery on 401 — no unexpected sign-outs

---

## About Riff

Built with Flutter. API powered by NestJS on Railway. Media hosted on Cloudinary.

Minimum Android version: Android 5.0 (Lollipop)

---

*Version 1.0.10 — Initial public release*
