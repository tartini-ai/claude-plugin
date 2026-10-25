# How to write it

Part of the ga4-bigquery-consent skill.

- **The region comes from the visitor's IP address, worked out at the edge, and reaches the page with no
  server code.** The load balancer or CDN adds the visitor's country to every response as a header, and
  the consent module reads it with one same-origin request before it decides. On Google Cloud the global
  external Application Load Balancer does it with one setting (`X-Client-Region: {client_region}` as a
  custom response header, platform-commands.md); Cloudflare, Vercel and CloudFront can add a response header from their own
  country value with an edge rule or function. The country is the platform's estimate from the IP address.
  Never the browser's time zone or language, never a third-party lookup from the page, never a cookie. Only
  where the edge cannot add a response header does the server hand the region over (a same-origin endpoint,
  or the HTML it writes), from the request header the platform sets (`X-Client-Region`, `CF-IPCountry`,
  `x-vercel-ip-country`, `CloudFront-Viewer-Country`). No answer within half a second, or no header yet:
  consent-first, so until the platform side is done the site behaves as it does today.

  ```js
  // The decision, once per page. Adapt it to the module's own structure and names.
  const CONSENT_FIRST = new Set(['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', // the EU
    'IS', 'LI', 'NO', 'GB', 'CH']);                                  // the rest of the EEA, the UK, Switzerland
  async function visitorRegion(waitMs = 500) {
    const stop = new AbortController();
    const timer = setTimeout(() => stop.abort(), waitMs);
    try {
      const res = await fetch(location.pathname, { method: 'HEAD', cache: 'no-store', signal: stop.signal });
      return (res.headers.get('X-Client-Region') || '').trim().toUpperCase() || null;
    } catch (e) { return null; } finally { clearTimeout(timer); }
  }
  async function decide() {
    const stored = storedChoice();                    // the visitor's own earlier choice, or null
    if (stored) return apply(stored);                 // a stored choice always wins
    const region = await visitorRegion();
    if (!region || CONSENT_FIRST.has(region)) return showBanner();               // ask first, as before
    apply(navigator.globalPrivacyControl === true ? 'denied' : 'granted');       // GPC opts out
  }
  ```

  Collecting by default is not a choice the visitor made: do not store it, decide again on the next page.
- **GPC.** `navigator.globalPrivacyControl === true` (the browser also sends `Sec-GPC: 1`) is an
  opt-out: in an opt-out region nothing non-essential runs, and the visitor is not asked to undo it.
  California's Attorney General requires businesses to honour it as a request to stop selling or sharing.
- **The opt-out link.** A footer link "Your privacy choices" that reopens the choice, on every page that
  can run analytics. The choice is stored in the visitor's own browser; that record is strictly necessary.
- **Consent Mode, with gtag's own commands only.** `gtag('consent', 'default', { … 'denied' … })` before
  any command that sends data (`config`, `event`); `region: [...]` takes ISO 3166-2 codes (`'ES'`,
  `'US-CA'`) and the more specific default wins; `wait_for_update` (milliseconds) holds the tags for a
  banner that loads late. `gtag('consent', 'update', { … })` as soon as the visitor chooses, and again on
  every later page from the stored choice. The four types that matter: `analytics_storage`, `ad_storage`,
  `ad_user_data`, `ad_personalization`. Never wrap, replace or patch `gtag` or `dataLayer`.
- **The Google tag is only added to, never taken away.** Every loader, `config` command and `gtag`
  definition stays; what changes is when they run.
- **Refusing is as easy as agreeing.** Accept and Reject side by side with the same weight, nothing
  pre-ticked, no scroll or close button that means yes, and withdrawing is as easy as agreeing (one click
  if agreeing took one).
- **A server log line, where a total is wanted.** If the host already logs every request (Cloud Run, App
  Engine, Vercel, Cloudflare), export those logs. Where the region or the source is wanted, the server
  writes one structured line per page it serves: page path, region, `ref` and `utm_*` from the address,
  the referring host, and whether the user agent is a known bot: no IP address, no full user agent.
- **One change.** The consent code, the footer link, the privacy policy's cookie section and the
  project's consent tests change together; a test that pinned the old behaviour is updated to pin the
  new one, never deleted.
- **Make the change the way your tools allow.** On the web, Tartini AI makes it as a draft correction:
  written in the code workspace, the project's tests run to their end, then saved. In Claude Code, edit
  locally; the developer opens the Pull Request and Tartini checks it.
