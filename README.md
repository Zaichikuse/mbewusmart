# MbewuSmart

![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Beta-orange)
![Version](https://img.shields.io/badge/Version-1.1.0-blue)

**AI-powered crop disease diagnosis for Malawian farmers — in English and Chichewa.**

---

## The problem

Malawi has roughly two million smallholder farmers. Most grow maize, cassava, or tomatoes on plots smaller than two hectares. When a disease strikes — grey leaf spot, cassava mosaic, early blight — farmers have limited options. Extension officers cover dozens of villages each. The nearest agro-dealer may be hours away. By the time a diagnosis arrives, the damage is done.

The gap between *noticing a sick plant* and *getting actionable advice* costs farmers harvests they cannot afford to lose.

---

## The solution

MbewuSmart puts that gap in a phone camera's field of view.

Point your phone at a diseased leaf, get an AI diagnosis in seconds, see treatment steps in plain Chichewa or English, and connect to a nearby extension officer — all without leaving your field.

---

## Key features

- 📸 **AI-powered scanning** — Gemini 2.5 Flash identifies diseases, pests, and nutrient deficiencies from a single photo
- 🌽 **Crop support** — maize, cassava, tomato (more coming)
- 🇲🇼 **Bilingual** — full English and Chichewa throughout the app
- 🗺️ **Disease Watch** — anonymised community feed showing what other farmers are seeing across Malawi, with exact three-tier location (Region → District → Locality)
- 💬 **Community Comments** — comment on Disease Watch reports, like and reply to other farmers' comments — peer-to-peer knowledge sharing across Malawi
- 📊 **Manager dashboard** — district-level analytics with an interactive, zoomable Malawi map featuring colour-coded severity markers, animated fly-to on marker tap, and a bottom info card with full case details
- 🔔 **Alerts** — managers can push outbreak warnings to extension officers instantly
- 🤖 **AI chat assistant** — ask follow-up questions after a diagnosis
- 📍 **Nearby Help** — GPS-based search for extension officers and agro-dealers

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| UI framework | Flutter 3.10+ |
| State management | BLoC / flutter_bloc |
| AI vision | Google Gemini 2.5 Flash |
| Cloud database | Cloud Firestore |
| Local storage | Hive (encrypted) |
| Authentication | Firebase Auth |
| Push notifications | Firebase Cloud Messaging |
| Maps | flutter_map + OpenStreetMap tiles |
| PDF reports | pdf + printing packages |
| Location | Geolocator + Geocoding + latlong2 |

---

## Architecture

MbewuSmart follows **Clean Architecture** with three layers:

- **Domain** — entities, use cases, repository interfaces. Zero Flutter or Firebase dependencies.
- **Data** — repository implementations, Firestore datasources, local Hive datasources.
- **Presentation** — BLoC blocs/states/events, pages, widgets.

Feature modules live under `lib/features/`, each with its own domain/data/presentation split. Shared code (theme, routes, widgets) lives under `lib/shared/` and `lib/core/`.

---

## Security and privacy

MbewuSmart handles sensitive personal data (national ID numbers, phone numbers, GPS coordinates). Eight security layers protect it:

1. **bcrypt PIN hashing** — user PINs are hashed with cost factor 12; the plaintext never touches storage.
2. **AES-256 NID encryption** — national ID numbers are encrypted with AES-256-CBC before being written to Firestore.
3. **Android Keystore** — encryption keys are stored in hardware-backed secure storage, not in app files.
4. **Encrypted Hive** — the local database is encrypted at rest using a key derived from the Keystore.
5. **Anonymous IDs** — all data shared to the community Disease Watch feed uses rotating anonymous identifiers; no personally identifying information is included.
6. **Hybrid Firestore architecture** — private farmer data and public community data live in separate Firestore collections with independent access rules.
7. **Production security rules** — Firestore rules are server-enforced; no client-side trust.
8. **Restricted API key scoping** — the Gemini API key is restricted to a single API and tied to the application's package signature.

Full details: [PRIVACY_POLICY.md](PRIVACY_POLICY.md) · [Live policy](https://zaichikuse.github.io/mbewusmart/PRIVACY_POLICY)

---

## Screenshots

| Splash | Home | Scan | Results |
|--------|------|------|---------|
| ![Splash](docs/screenshots/01_splash.png) | ![Home](docs/screenshots/02_home.png) | ![Scan](docs/screenshots/03_scan.png) | ![Results](docs/screenshots/04_results.png) |

| Disease Watch | Manager Dashboard |
|--------------|------------------|
| ![Disease Watch](docs/screenshots/05_disease_watch.png) | ![Dashboard](docs/screenshots/06_manager_dashboard.png) |

---

## Installation

### For users

Download the latest APK from the [Releases](https://github.com/Zaichikuse/mbewusmart/releases) page.

- Most Android phones (2018 and newer): use `app-arm64-v8a-release.apk`
- Older 32-bit phones: use `app-armeabi-v7a-release.apk`

Enable "Install from unknown sources" in your Android settings before installing.

### For developers

**Requirements:** Flutter SDK ≥ 3.10.8, Android Studio, a device or emulator running Android API 21+.

```bash
git clone https://github.com/Zaichikuse/mbewusmart.git
cd mbewusmart
flutter pub get
```

Create a `.env` file at the project root:

```
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_API_KEY=your_google_maps_api_key_here
```

Place `google-services.json` in `android/app/` (request from the maintainer or connect your own Firebase project).

```bash
flutter run
```

**Build a release APK:**

```bash
flutter build apk --release --split-per-abi
```

---

## Changelog

### v1.1.0 (23 June 2026)
- **Added:** Community comments on Disease Watch reports — post, like, reply with @mentions
- **Added:** Exact three-tier location on reports (Region → District → Locality) via GPS reverse geocoding
- **Added:** Interactive disease map for Agriculture Manager — zoomable Malawi map with colour-coded severity markers, animated fly-to on marker tap, bottom case info card, legend, case counter, and zoom controls
- **Added:** Firestore security rules for comments sub-collection
- **Added:** LocationService, Comment model, MapMarker model, location card widget

### v1.0.1 (24 May 2026)
- **Fixed:** Privacy Policy link on Android 11+
- **Fixed:** Change PIN double-hashing bug
- **Added:** Debug logging in authentication flow

### v1.0.0 (24 May 2026)
- Initial public beta release

---

## Roadmap

- Firebase Phone Authentication — real SMS OTP verification
- SMS fallback — diagnosis results delivered by text message for farmers without smartphones
- More crops — rice, groundnuts, cotton, soya beans
- Yield prediction — estimate harvest impact from detected diseases
- Offline AI inference — on-device model for areas with no connectivity

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, branch naming, commit format, and PR guidelines.

Security vulnerabilities should be reported privately to zaichikuse@gmail.com — not as public issues.

---

## License

Copyright © 2026 Zaithwa Chikuse. All rights reserved. 
For licensing or partnership inquiries, contact zaichikuse@gmail.com.

---

## Acknowledgments

- [Anthropic Claude](https://anthropic.com) — AI pair-programmer throughout development
- [Google Gemini](https://deepmind.google/technologies/gemini/) — vision AI powering crop diagnosis
- The Malawian farming community — whose needs shaped every design decision

---

## Contact

**Zai Chikuse**  
zaichikuse@gmail.com  
GitHub: [@Zaichikuse](https://github.com/Zaichikuse)
