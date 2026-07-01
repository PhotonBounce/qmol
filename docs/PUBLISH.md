# Publishing Q-Mol (web app · microsite · APK)

Everything is built, tested, and pushed on `claude/epic-mendel-a7r40z` (PR #1).
What's live vs. what needs one manual step:

## ✅ Testable right now — the Android APK

The `mobile` CI job builds a sideloadable debug APK on every push and uploads it
as an artifact:

1. Open the latest **mobile** run: repo → **Actions → mobile** → newest run.
2. Download the **`qmol-debug-apk`** artifact (a zip → `qmol-debug.apk`).
3. On your phone, enable **Install unknown apps**, then open the APK.

It points at the live API (`https://qua-22p1.onrender.com`).

## 🌐 The web app (`app.html`)

A self-contained browser tool: sign in → compute a descriptor panel from SMILES
→ export CSV. It ships in **two** places and goes live wherever the code deploys:

- **On the API host:** served at `…/app.html` (route added in `api.py`). Live at
  `https://qua-22p1.onrender.com/app.html` **after the PR merges to `main`**
  (Render auto-deploys `main`).
- **On the microsite:** `microsite/app.html`, linked from the home page
  ("Open the web app"). Live at `…/qmol/app.html` after the microsite deploys.

## Choose how to publish the site — pick ONE

### A. FTP microsite (photon-bounce.com/qmol)
1. Repo → **Settings → Secrets and variables → Actions → New secret**:
   `FTP_PASSWORD` = your FTP password. *(The prior deploy failed only because
   this secret isn't set.)*
2. Merge PR #1 to `main` (or run **Actions → deploy-microsite → Run workflow**).
   It uploads `microsite/` to `/qmol`.

### B. GitHub Pages (photonbounce.github.io/qmol) — free, no secret
1. Repo → **Settings → Pages → Source: GitHub Actions**. *(One-time. The
   workflow can't enable this itself — token gets `Resource not accessible`.)*
2. Merge PR #1, or run **Actions → Deploy landing/ to GitHub Pages → Run
   workflow**. It publishes `landing/` (including `app.html`).

### C. Just merge — the API host
Merging PR #1 to `main` alone makes `https://qua-22p1.onrender.com/app.html`
live via Render's auto-deploy. No secret needed.

## 🏷️ Public APK download link (for the microsite button)

The microsite's "Download APK" button points at
`…/releases/latest/download/qmol-debug.apk`. Create that release once the
workflow is on `main`:

- Push a tag `app-v1.0.0`, **or** run **Actions → release-apk → Run workflow**.
  It builds the APK and attaches it to a GitHub Release.

## Data stance (unchanged)

The web app lets a signed-in user compute and export **their own** molecular
data, and links to Q-Mol's public-domain (PubChem-derived) dataset. It never
sells or redistributes structures users submit — that promise is in the Terms
and Privacy Policy and is what keeps the app shippable on Google Play.
