# Gemini API Key Lockdown — Manual Steps

Perform these steps at https://aistudio.google.com/apikey **before** distributing the release APK.

---

## Step 1 — Find your API key

1. Open https://aistudio.google.com/apikey
2. Locate the key used by MbewuSmart (it will be listed under your Google account).
3. Click the three-dot menu (⋮) to the right of the key → **Edit API key** (or click the key name itself).

---

## Step 2 — Restrict by Android package name

1. Under **Application restrictions**, select **Android apps**.
2. Click **+ Add an item**.
3. Enter the following package name exactly:
   ```
   com.mbewusmart.mbewu_smart
   ```
4. Leave the SHA-1 field blank for now (or add your release signing SHA-1 if you have it — run `keytool -list -v -keystore your-release-key.jks` to get it).
5. Click **Done** → **Save**.

> After this change, the key will only function when called from an APK signed with the `com.mbewusmart.mbewu_smart` package. Requests from any other origin (cURL, Postman, a cloned APK with a different package name) will be rejected with a 403 error.

---

## Step 3 — Add a daily quota limit

1. In the same key settings, look for **Quotas** or navigate to:
   https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas
2. Find the quota for **Generative Language API — Requests per day**.
3. Click the pencil icon → set the limit to **1000 requests/day**.
4. Click **Save**.

> 1,000 requests per day is generous for a beta app with a small user base. It costs you nothing under the free tier and caps your exposure if the key leaks.

---

## Why this matters

When you publish an APK, anyone can extract the compiled code and retrieve strings embedded in it — including API keys. Even obfuscated builds can be reverse-engineered with enough effort.

**Without restrictions:** A bad actor extracts your key and uses it to make millions of requests, racking up charges on your Google Cloud account or exhausting your free-tier quota.

**With package-name restriction:** Requests using the extracted key succeed only when they originate from an APK with the exact package ID `com.mbewusmart.mbewu_smart`. A script or app using the key outside that package gets a 403.

**With a daily quota:** Even if the restriction is bypassed (e.g., by repackaging the APK), the attacker can cause at most 1,000 calls per day before hitting the limit. This caps your financial exposure and protects availability for real users.

---

## Checklist

- [ ] Application restriction set to Android → `com.mbewusmart.mbewu_smart`
- [ ] Daily quota set to 1,000 requests/day
- [ ] Key saved and active
- [ ] Tested the app still works after restrictions are applied (run one scan to confirm)
