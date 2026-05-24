# Release Notes — v1.0.0

**Release date:** 2026-05-24  
**Status:** Public beta  
**Build:** 1

---

## What's in this release

### Feature highlights

**AI crop diagnosis**
Point the phone camera at a diseased leaf and receive a diagnosis from Google Gemini 2.5 Flash in under ten seconds. Results include disease name, severity level, confidence score, and step-by-step treatment advice — in English or Chichewa.

**Disease Watch**
A community feed showing anonymised reports from farmers across Malawi. Filterable by crop type and district. Helps farmers spot incoming outbreaks before they reach their area.

**Manager analytics dashboard**
District managers see a live choropleth map of Malawi, disease frequency trends by crop, and a summary of recent alerts. Built on fl_chart and flutter_map with real Firestore data.

**Alert system**
Managers can publish outbreak alerts that are pushed to extension officers in affected districts via Firebase Cloud Messaging.

**Nearby Help**
GPS-based search returns the nearest extension officers and agro-dealers with phone numbers and distance. Calls launch directly from the app.

**Scan history**
All diagnoses are stored locally in an encrypted Hive database. Viewable offline. Exportable as a PDF report for sharing via WhatsApp or email.

**AI chat assistant**
After a diagnosis, farmers can ask follow-up questions in a conversational interface powered by Gemini.

---

### Security (7 layers)

| Layer | What it does |
|-------|-------------|
| bcrypt PIN hashing | User PINs hashed with cost factor 12 — never stored in plaintext |
| AES-256 NID encryption | National ID numbers encrypted before Firestore storage |
| Android Keystore | Encryption keys in hardware-backed secure storage |
| Encrypted Hive | Local database encrypted at rest |
| Anonymous IDs | Community feed data uses rotating anonymous identifiers |
| Hybrid Firestore | Private and public data in separate collections |
| Production security rules | Server-enforced access control — zero client-side trust |

---

### User roles

| Role | Capabilities |
|------|-------------|
| Farmer | Scan crops, view history, browse Disease Watch, access Nearby Help |
| Extension Officer | Everything a farmer can do, plus receive alerts from managers |
| Manager | All of the above, plus analytics dashboard, alert publishing, map view |
| Agro-dealer | Dealer-specific dashboard |

---

## Known limitations

- **FCM notifications are partial.** Alert delivery works on most devices but may be delayed or absent on some battery-restricted Android configurations (MIUI, One UI with aggressive background restrictions).
- **SMS OTP not yet live.** Phone authentication uses a placeholder verification step. Firebase Phone Auth with real SMS is on the roadmap.
- **AI accuracy depends on photo quality.** Blurry or dark images produce lower-confidence results. The app warns users when confidence is below threshold.
- **Beta status.** This is a first public release. Edge cases exist. Report issues to zaichikuse@gmail.com.

---

## Install instructions

| Device type | APK file |
|-------------|---------|
| Most phones from 2018 onward (64-bit ARM) | `app-arm64-v8a-release.apk` |
| Older 32-bit ARM phones | `app-armeabi-v7a-release.apk` |
| x86_64 emulators | `app-x86_64-release.apk` |

**Minimum Android version:** 5.0 (API 21)

Enable "Install from unknown sources" (Settings → Apps → Special app access → Install unknown apps) before sideloading the APK.

---

## APK location (after build)

```
build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
build\app\outputs\flutter-apk\app-x86_64-release.apk
```
