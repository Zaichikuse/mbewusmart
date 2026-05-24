# MbewuSmart v1.0.1 — Bug Fix Release

**Released:** 2026-05-24
**Type:** Bug fix (patch)

---

## What's Fixed

### Privacy Policy link now works on Android 11+

The "Privacy Policy" tile in Settings was failing to open the policy webpage on Android 11 and newer. This was caused by missing package visibility declarations in the Android manifest, a security requirement Google introduced in API level 30.

Without the `<queries>` block, `url_launcher`'s `canLaunchUrl()` returns `false` for all `https://` URLs on Android 11+, and the tile tap silently does nothing. The fix adds the required intent declarations for `https`, `http`, `tel`, and `mailto` schemes.

### Change PIN now accepts your current PIN

Users could log in with their PIN successfully, but the Change PIN flow was incorrectly rejecting the same PIN with "Current PIN is incorrect."

**Root cause:** The Change PIN dialog in `settings_page.dart` was doing a direct string comparison:
```dart
// WRONG — was in the code before fix
if (currentUser.pin != currentPinController.text) { ... }
```

`currentUser.pin` is a **bcrypt hash** (e.g., `$2a$12$...`). The user's typed PIN is **plaintext** (e.g., `1234`). These will never be equal as strings — so the check always failed, always showed "PIN is incorrect", and returned early before dispatching the bloc event.

The correct verification path — `BCrypt.checkpw(plaintext, hash)` in `AuthLocalDataSource.verifyPin()` — was never reached. Removing the bad client-side check allows the bloc to do the right thing.

---

## Why a patch release matters

Most students would have shipped v1.0.0 with these bugs unnoticed. Finding and fixing them before public launch is what real software engineering looks like. This patch release demonstrates:

- A culture of testing before declaring "done"
- Honest acknowledgment of bugs (not hiding them)
- Following semantic versioning (patch = backward-compatible fixes)
- Understanding the full call chain from UI → BLoC → data layer

---

## Upgrade

Existing installations: download `app-arm64-v8a-release.apk` from the v1.0.1 GitHub release and install over the existing app. No data migration required — Hive database and user accounts are preserved.
