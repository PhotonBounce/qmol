# Q-Mol launch checklist — SaaS + Google Play

The single source of truth for "are we ready?" Split into **✅ Done in code**
(shipped, tested, on `main`) and **🔑 Your move** (things that need *your*
login/secrets — I can't do these from the dev environment).

Related runbooks: `docs/PUBLISH.md` (hosting), `docs/COMPLIANCE.md` (Play
policy details), `docs/GO_LIVE.md` (payments).

---

## Part 1 — SaaS (API + web app)

### ✅ Done in code
- FastAPI service, ~80 routes, **340 tests green**; deploys to Render from `main`.
- Web app at **`/app.html`** (login → compute → CSV) + microsite.
- Stripe Checkout endpoint (`POST /billing/checkout`) + webhook that provisions
  and emails the key. Degrades to 503 until keys are set (safe to ship).
- Quotas, rate limits, teams, audit, `/usage`, account export + delete.
- Privacy (`/privacy`) and Terms (`/terms`) served at stable URLs.

### 🔑 Your move (to actually charge money)
1. **Render env vars** (Dashboard → your service → Environment):
   - `QMOL_ADMIN_TOKEN` — pick a strong secret.
   - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, and the price IDs
     `STRIPE_PRICE_RESEARCH`, `STRIPE_PRICE_COMMERCIAL`.
   - `MAILGUN_API_KEY` + `MAILGUN_DOMAIN` (to email keys on purchase).
2. **Stripe** (dashboard.stripe.com): create the two subscription products/prices,
   add a webhook to `https://<your-api>/stripe/webhook`, paste its signing secret
   into `STRIPE_WEBHOOK_SECRET`.
3. Smoke test: `POST /billing/checkout {"tier":"research"}` → returns a Stripe URL
   → pay in test mode → confirm the key email arrives.

---

## Part 2 — Google Play (Android app)

### ✅ Done in code
- Flutter app: Compute / Subscribe / Account; **APK + AAB build in CI**.
- **Play Billing** (Billing Library 7 via `in_app_purchase`), verified
  server-side at `POST /billing/play/verify` (Stripe is *not* used on Android).
- Required policies covered: in-app **Privacy/Terms links**, **Delete account &
  data** (`DELETE /account`), INTERNET-only permission, graceful billing
  fallback on unsupported platforms.
- Test APK published as a GitHub Release:
  `…/releases/latest/download/qmol-debug.apk`.

### 🔑 Your move (to publish on Play)
1. **Play Console** account (one-time US$25) → create the app.
2. **Signing:** generate an upload keystore:
   ```
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
   Add repo secrets `ANDROID_KEYSTORE_BASE64` (`base64 upload-keystore.jks`),
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
   then run **Actions → release-aab** → download the signed `qmol-release.aab`
   and upload it to Play (enable Play App Signing).
3. **Play Billing products:** create subscriptions with IDs
   `qmol_research_monthly` and `qmol_commercial_monthly` (must match
   `mobile/lib/billing.dart` and the backend `_PLAY_PRODUCTS`).
4. **Server verification env** (Render): `ANDROID_PACKAGE_NAME` (`app.qmol.qmol`)
   and `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (a Play Developer API service account),
   so `/billing/play/verify` can validate purchase tokens.
5. **Store listing:** icon, screenshots (see `docs/app-screens/`), description,
   the hosted Privacy URL (`/privacy`), and the Data Safety form (declare:
   email + submitted structures processed to provide the service; not sold).

---

## Part 3 — Hosting the microsite (optional; the API already serves the web app)
- **Own domain (photon-bounce.com/qmol):** add the `FTP_PASSWORD` secret →
  `deploy-microsite` publishes on merge.
- **Free (GitHub Pages):** Settings → Pages → Source: **GitHub Actions** → the
  `pages` workflow publishes `landing/`.

---

## The honest revenue model
Sell **the tool** (SaaS subscriptions + the app) and the **commodity
public-domain dataset** — never users' submitted structures. That promise is in
the Terms/Privacy and is what keeps the app on Google Play.
