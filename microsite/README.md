# Q-Mol microsite

Static marketing microsite for the Q-Mol app + API. Plain HTML/CSS (no build
step) so it drops onto any host and uses **relative links** — it works whether
it's served at a domain root, a `/qmol` subfolder, or a subdomain.

```
microsite/
  index.html        home (hero, features, app, pricing, ad slots)
  app.html          the web app — log in, compute descriptors, export CSV
  privacy.html      privacy policy (covers cookies + AdSense)
  terms.html        terms of service
  assets/
    styles.css      modern responsive dark theme
    shot-dashboard.png
    ads.txt         AdSense ads.txt — move to the DOMAIN ROOT when you enable ads
```

`app.html` is a self-contained browser app that calls the live API
(`https://qua-22p1.onrender.com`, overridable via `window.QMOL_API`). CORS is
open on the API, so it works from any origin. Users sign in with an API key (or
get a free one), compute a molecular-property panel from SMILES, and download
the results as CSV. It never stores or transmits anything except to the API to
return the user's own results.

The home page's **Download APK** button points at
`…/releases/latest/download/qmol-debug.apk`, published by the `release-apk`
workflow (push a `app-v*` tag or run it manually).

## Deploy — automatic (recommended)

`.github/workflows/deploy-microsite.yml` uploads this folder to the FTP `/qmol`
directory. It runs on **push to `main`** (i.e. after this PR merges) or **on
demand** (Actions → deploy-microsite → Run workflow) from any branch. One-time
setup:

1. Repo → **Settings → Secrets and variables → Actions → New repository secret**
   - name: `FTP_PASSWORD`  · value: *(your FTP password)*
2. (Optional) repo **variables**: `FTP_SERVER` / `FTP_USERNAME` to override the
   defaults (`ftp.photon-bounce.com` / `photonb`), and `FTP_PROTOCOL` (`ftps`
   default; set `ftp` if your host only supports plain FTP).
3. Merge to `main`, or trigger the workflow manually.

If `FTP_PASSWORD` isn't set, the job **skips** (stays green) instead of failing.
The password lives only in the GitHub secret — never in the repo.

## Deploy — manual

Upload the **contents** of `microsite/` into the server's `/qmol` folder with any
FTP client (FileZilla, Cyberduck) or:

```bash
lftp -u photonb ftp.photon-bounce.com -e "mirror -R microsite /qmol; bye"
```

## Enable ads later

1. Get a Google AdSense publisher id (`ca-pub-…`).
2. In `index.html`, replace both `ca-pub-XXXXXXXXXXXXXXXX` placeholders.
3. Put `assets/ads.txt` (with your id) at your **domain root**, e.g.
   `https://photon-bounce.com/ads.txt`.
4. Ads load only after a visitor accepts the cookie banner (already wired).

## Security note

The FTP password was shared in chat — consider **rotating it** and relying on the
GitHub secret for deploys going forward.
