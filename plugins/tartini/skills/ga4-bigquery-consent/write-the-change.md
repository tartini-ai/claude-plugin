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
  // The decision, once per page, before anything is shown. Adapt it to the module's own structure and names.
  const CONSENT_FIRST = new Set(['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', // the EU
    'GP', 'GF', 'MQ', 'YT', 'RE', 'MF', 'AX', 'IC', 'EA',           // places of the EU with codes of their own
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
    const gpc = navigator.globalPrivacyControl === true;
    const stored = storedChoice();                    // the visitor's own choice, { accepted, withGpc }, or null
    // A stored choice wins, except an Accept given while GPC was off, once GPC is on (below).
    if (stored && !(stored.accepted && gpc && !stored.withGpc)) return apply(stored.accepted);
    const region = await visitorRegion();             // nothing is shown before this answers
    if (!region || CONSENT_FIRST.has(region)) return stored ? apply(stored.accepted) : showBanner();
    apply(!gpc);                                      // collect by default; GPC opts out
  }
  ```

  Collecting by default is not a choice the visitor made: do not store it, decide again on the next page.
  **Decide first, then show.** Nothing of the banner is drawn before `decide()` has its answer, so a visitor
  in a region that collects by default never sees it, not even for a moment; only a consent-first, unknown
  or late region shows it.
- **GPC.** `navigator.globalPrivacyControl === true` (the browser also sends `Sec-GPC: 1`) is an
  opt-out: in an opt-out region nothing non-essential runs, and the visitor is not asked to undo it.
  California's Attorney General requires businesses to honour it as a request to stop selling or sharing,
  and it beats a business's own setting that allows it (11 CCR §7025(c)(3)): there, GPC beats an Accept the
  visitor stored while GPC was off. A site may tell the visitor the two differ and offer the choice again; an
  Accept given with GPC on counts, so store `withGpc` with it. A Reject always wins.
- **The opt-out link.** "Your privacy choices", on every page that can run analytics, added by the consent
  module itself: inside the footer's existing legal links (beside the privacy policy's link), with the same
  element and classes as its neighbours, once per document. A page with no footer gets a small fixed link,
  styled to be seen, never an unstyled native button. A page shown in a frame of another page of the same
  site draws no link or banner of its own: the top page does, and its choice takes effect in the framed page
  too, so the visitor sees one control and gets one effect. The choice is stored in the visitor's own
  browser; that record is strictly necessary.
- **Showing the choice again, and withdrawing.** The link shows the choice again with the current one
  marked, and removes nothing: until the visitor picks, the page goes on as before, and the privacy policy
  says exactly that. Reject sends the denied update at once, stops each tool that runs on consent, and is
  stored. Accept turns back on everything a Reject turned off, a tool's own stored opt-out included
  (PostHog's `opt_out_capturing()` stays in the browser until `opt_in_capturing()`).
- **Consent Mode, with gtag's own commands only.** `gtag('consent', 'default', { … 'denied' … })` before
  any command that sends data (`config`, `event`); `region: [...]` takes ISO 3166-2 codes (`'ES'`,
  `'US-CA'`) and the more specific default wins; `wait_for_update` (milliseconds) holds the tags for a
  banner that loads late. `gtag('consent', 'update', { … })` as soon as the visitor chooses, and again on
  every later page from the stored choice. The four types that matter: `analytics_storage`, `ad_storage`,
  `ad_user_data`, `ad_personalization`. Never wrap, replace or patch `gtag` or `dataLayer`.
- **A global other code reads is a signal.** Before you create or change one (`window.gtag`, `dataLayer`, a
  consent flag), read every reader of it: site code that sends only when `typeof window.gtag === 'function'`
  takes a new `window.gtag` as leave to send, before any choice and after a Reject. So define the stub the
  consent default needs locally (`function gtag() { dataLayer.push(arguments); }` inside the module), and
  leave `window.gtag` to be defined where the site defined it before.
- **The Google tag is only added to, never taken away.** Every loader, `config` command and `gtag`
  definition stays; what changes is when they run.
- **Refusing is as easy as agreeing.** Accept and Reject side by side with the same weight, nothing
  pre-ticked, no scroll or close button that means yes, and withdrawing is as easy as agreeing (one click
  if agreeing took one).
- **The privacy policy says what the code does, region by region.** Where the site asks first, analytics
  runs on the visitor's consent. Where it collects by default, say exactly that: analytics runs by default,
  the visitor can opt out at any time ("Your privacy choices") and GPC is honoured as an opt-out, and name the
  basis the site relies on (for example legitimate interests); never call it consent, which those visitors
  never gave. Say what "Your privacy choices" does as the code does it. Name what the server logs are for (a
  count of page loads that does not depend on consent), what a line holds, and how long the raw logs are
  kept. Change only the sentences the change makes untrue, and add new paragraphs beside the old ones: never
  replace a paragraph about something else.
- **Notes for the person stay with the person.** "Common practice, not legal advice", your recommendations
  and your caveats go in your reply, never into a page visitors read, a policy included.
- **The server's log line counts each page it sends, once.** The platform's own request logs count every
  request (frames, prefetches, the consent module's HEAD) and hold IP addresses, so the server writes one
  structured line for each page a visitor opens: only a GET of a top-level document (`Sec-Fetch-Dest:
  document`, or the header absent), never a frame (`Sec-Fetch-Dest: iframe`), a prefetch or prerender
  (`Sec-Purpose`), a HEAD or an asset. Write it when the response finishes (Node's `res.on('finish')`, or
  the framework's after-response hook), and only for a 2xx response whose type is HTML: never a 404, a
  redirect, a dot-file or an error page. Mount it before every route that answers a page, so the pages a
  route of their own answers before any static mount are counted too. A page shown in a frame of the same
  address is one visit, not two. Write it in the shape of the server's other structured log lines (their
  severity and message fields). The line holds the page path, the region (the `X-Client-Region` request
  header), `ref` and `utm_*` from the address, the referring host, and whether the user agent is a known
  bot: no IP address, no full user agent.
- **The consent change is one change.** The consent code, the footer link, the privacy policy and the
  project's consent tests change together; a test that pinned the old behaviour is updated to pin the new
  one, never deleted, and an assertion that is still true is never removed or loosened.
- **The consent tests run the module.** Load the consent module itself with a fake region source (a header,
  no header, no answer in time, an error), a fake GPC flag and fake storage, and check what reaches the tag
  for: a consent-first region, a region that collects by default, an unknown region, a timeout, GPC, a stored
  choice, and a withdrawal then the next page. A test that only matches the module's source text proves none
  of it.
- **Make the change the way your tools allow.** On the web, Tartini AI makes it as a draft correction:
  written in the code workspace, the project's tests run to their end, then saved. In Claude Code, edit
  locally; the developer opens the Pull Request and Tartini checks it.
