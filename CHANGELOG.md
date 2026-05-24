# Changelog

All notable changes to MbewuSmart are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.1] — 2026-05-24

### Fixed
- Privacy Policy link in Settings now opens correctly on Android 11+ (added required `<queries>` block to AndroidManifest.xml)
- Change PIN verification now correctly accepts the current PIN (removed incorrect client-side bcrypt-hash vs plaintext comparison in settings_page.dart — the bloc's `verifyPin()` with `BCrypt.checkpw` is the correct verification path)

### Added
- Comprehensive `debugPrint` logging in authentication flow (`AuthLocalDataSource.login`, `AuthLocalDataSource.verifyPin`, `AuthBloc._onChangePinRequested`, `SettingsPage` Change PIN dispatch) for diagnostics

---
Versions follow [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-05-24

### Initial public beta release

**Features:**
- AI-powered crop disease diagnosis via Google Gemini 2.5 Flash
- Supports maize, cassava, and tomato
- Bilingual interface: English and Chichewa
- Disease Watch community feed — anonymised reports from farmers across Malawi
- Manager analytics dashboard with choropleth Malawi map and district-level trends
- Alert system: managers can notify extension officers about outbreaks
- AI chat assistant for follow-up questions after a diagnosis
- Nearby Help: find extension officers and agro-dealers by GPS location
- Scan history stored locally with full offline access
- Shareable PDF diagnosis reports (WhatsApp and email)
- Voice prompts via text-to-speech for low-literacy users

**User roles:**
- Farmer — scan crops, view history, access Disease Watch
- Extension Officer — receive alerts, access community trends
- Manager — analytics dashboard, alert management, map view
- Agro-dealer — dealer-specific dashboard

**Security (7 layers):**
- bcrypt-hashed PINs (cost factor 12)
- AES-256 encrypted NID numbers
- Android Keystore hardware-backed key storage
- Encrypted Hive local database
- Anonymous IDs for all community data shared to Firestore
- Hybrid Firestore architecture (private + public collections)
- Production Firestore security rules — server-side enforcement

**Known limitations:**
- FCM push notifications are partially implemented; alerts may not arrive on all devices
- Firebase Phone Authentication uses placeholder verification (SMS OTP not yet live)
- Beta status — AI diagnosis accuracy depends on photo quality and lighting conditions
- Disease Watch feed requires internet; offline browsing is not yet supported
