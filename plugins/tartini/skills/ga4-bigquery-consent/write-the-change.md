# How to write it

Part of the ga4-bigquery-consent skill.

- **The region comes from the edge.** The visitor's country is worked out from their IP address at the
  edge and reaches the page with no server code. The load balancer or CDN adds it to every response as a
  header, and the consent module reads it with one same-origin request before it decides. On Google Cloud
  the global external Application Load Balancer does it with one setting (`X-Client-Region: {client_region}` as a
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
    apply(!gpc);                                      // collect analytics by default, ads denied; GPC opts out
  }
  // apply(granted) sends the Consent Mode update and each tool's opt-in or opt-out, AND starts what the site's own
  // gate holds back for analytics on this page, without storing anything ("The gate the site already has", below).
  ```

  Collecting by default is not a choice the visitor made: do not store it, decide again on the next page.
  **Decide first, then show.** Nothing of the banner is drawn before `decide()` has its answer, so a visitor
  in a region that collects by default never sees it, not even for a moment; only a consent-first, unknown
  or late region shows it.
- **The gate the site already has.** A site often holds its tags back behind a gate of its own: loaders queued
  until their category is granted, then run. Before you write, read how that gate releases what waits. If it
  releases only on a STORED answer, collecting by default (which is never stored) releases nothing, and in every
  region that collects by default the tag never starts: fewer visitors counted than before, not more. So the
  default decision gives the gate its answer for this page without storing it (an in-memory decision the gate
  reads beside the stored one), and `apply()` runs what was waiting. The site's tests prove it: in a region that
  collects by default, with nothing stored, a loader registered through the gate runs, on the first page and on
  the next.
- **GPC.** `navigator.globalPrivacyControl === true` (the browser also sends `Sec-GPC: 1`) is an
  opt-out: in an opt-out region nothing non-essential runs, and the visitor is not asked to undo it.
  California's Attorney General requires businesses to honour it as a request to stop selling or sharing,
  and it beats a business's own setting that allows it (11 CCR §7025(c)(3)): there, GPC beats an Accept the
  visitor stored while GPC was off. A site may tell the visitor the two differ and offer the choice again; an
  Accept given with GPC on counts, so store `withGpc` with it. A Reject always wins.
- **The opt-out link.** "Your privacy choices", on every page that can run analytics, added by the consent
  module itself. First find every place the site already links its privacy policy as an item of a list of
  links (a footer's legal links, an account or settings menu, a sign-in page's links), and put the link beside
  each one as another item of that list, once per document: with the list's separator between them (the text
  or element its items are joined by), and the markup its items use (the element, classes, attributes, role
  and tab order a menu's keys rely on); a menu drawn later gets it when it is drawn. Never beside a policy link
  inside a sentence of running text (a paragraph of a legal page), and never inside UI the consent module draws
  itself (its own banner's policy link): a scan that matches every policy link, or rescans as the page changes,
  finds those too. The choice is stored in the visitor's own browser; that record is strictly necessary.
- **The fallback link.** Only a page that shows no such link, and on which none will appear, gets a small fixed
  link: first read which policy links the page's shell or menus draw after it loads (an account menu injected
  later), and draw the fallback only where none will come, or remove it when one does. It is styled to be seen,
  never an unstyled native button, clear of the page's own fixed or sticky controls at every width (read the
  layout's CSS and its media queries for them: a rail, a switcher, an assistant launcher), and under its dialogs
  (read their z-index).
- **A page framed by the same site.** A page shown in a frame of another page of the same site draws no
  link or banner of its own: the top page does, and the framed page applies what the top page's choice
  changes, so the visitor sees one control and gets one effect. A change to `localStorage` fires a
  `storage` event in every other document of the same origin, never in the one that wrote it: the framed
  page listens for the consent key and, on a Reject, sends the denied update and each tool's opt-out (on an
  Accept, the update and each opt-in). A choice kept in a cookie fires no event: the top page sends the frame
  a message (`postMessage` to its own origin) or reloads it. A Google tag already loaded may keep sending
  cookieless pings after a denied update, so the privacy policy says what Reject really stops, never "stops
  everything at once" unless the code does.
- **Showing the choice again, and withdrawing.** The link shows the choice again with the current one
  marked, and removes nothing: until the visitor picks, the page goes on as before, and the privacy policy
  says exactly that. The mark is one a sighted visitor sees (a label, or a style the stylesheet gives it),
  never only an ARIA attribute or a class nothing styles. Reject sends the denied update at once, stops each
  tool that runs on consent, and is stored. Accept turns back on everything a Reject turned off, a tool's
  own stored opt-out included (PostHog's `opt_out_capturing()` stays in the browser until
  `opt_in_capturing()`).
- **The banner's words, per region.** Where the site asks first, the banner asks for consent. Where it
  collects by default, the choice the link shows says that the site collects analytics by default and that
  the visitor can turn it off; it never says "consent", which those visitors never gave. The words follow the
  region whether or not a choice is stored: showing the choice again looks the region up, even where a stored
  choice let the page skip the lookup to decide. A visitor there with nothing stored sees the current state
  (analytics on) marked; with GPC on, the words say GPC turned analytics off.
- **Consent Mode, with gtag's own commands only.** `gtag('consent', 'default', { … 'denied' … })` before
  any command that sends data (`config`, `event`); `region: [...]` takes ISO 3166-2 codes (`'ES'`,
  `'US-CA'`) and the more specific default wins; `wait_for_update` (milliseconds) holds the tags for a
  banner that loads late. `gtag('consent', 'update', { … })` as soon as the visitor chooses, and again on
  every later page from the stored choice. The four types that matter, and the choice each follows:
  `analytics_storage` follows the analytics choice; `ad_storage`, `ad_user_data` and `ad_personalization`
  follow the marketing choice. Where the site collects analytics by default, the three ad types stay denied
  unless the visitor said yes to marketing, and a site that runs no advertising tag keeps them denied. Never
  wrap, replace or patch `gtag` or `dataLayer`.
- **A third-party call does what its installed version does.** Before calling a method that changes a
  tool's state (an opt-in, an opt-out, a reset), read what the version the site installs does, in its
  source or its docs: what it stores and what it sends. A call made on every page load is idempotent and
  sends nothing when nothing changed. PostHog's `opt_in_capturing()` captures an `$opt_in` event each time
  it runs, so: `if (posthog.has_opted_out_capturing()) posthog.opt_in_capturing({ captureEventName: false })`.
- **A tool loaded later gets the choice where it starts.** A call to a tool that is not on the page yet does
  nothing (a guard such as `if (window.tool)` skips it; only a vendor's own queueing stub, where the site uses
  one, replays it later). Read when each tool loads relative to the consent module: a tool its tag loader loads
  later is reached where it starts, so its loader reads the decision before it initialises the tool, or the
  tool's own loaded callback applies it. Then an Accept given on a page where the tool never loaded (after a
  stored Reject) turns it back on when it loads, on that page or a later one. The site's tests prove it in the
  real load order: the tool absent when the module runs, Accept after a stored Reject, the tool opted in once it
  loads.
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
  never gave. Say what "Your privacy choices" does, and where it is, as the code does it. Name what the
  server logs are for (a count of page loads that does not depend on consent), what a line holds, and how
  long the raw logs are kept. Change only the sentences the change makes untrue, and add new paragraphs
  beside the old ones: never replace a paragraph about something else.
- **Every sentence the change makes untrue.** The old behaviour is described in more places than the paragraph
  you edit: other paragraphs of the policy, a subprocessor or vendor list, the terms, a cookie table. Search
  every public page for its words ("before you accept", "only for visitors who accept", "none of these scripts
  runs", "nothing loads until you agree") and change each sentence the new code makes untrue, so no two pages
  give opposite answers; a test that pins one is updated to pin the new sentence. Say what Reject really stops:
  each tool's opt-out stops that tool, while a Google tag already loaded may keep sending cookieless pings until
  the next page.
- **Keep what a choice records.** What Accept and Reject store follows the site's own rules (Accept records only
  the categories the site uses, derived from what it runs); the change keeps a rule like that, and its test,
  as they are.
- **Notes for the person stay with the person.** "Common practice, not legal advice", your recommendations
  and your caveats go in your reply, never into a page visitors read, a policy included. So does deployment
  status ("until the region header exists, everyone is asked first"): a page says what the code does, and the
  reply says when it starts doing it.
- **The server's log line counts each page it sends, once.** The platform's own request logs count every
  request (frames, prefetches, the consent module's HEAD) and hold IP addresses, so the server writes one
  structured line for each page a visitor opens: only a GET of a top-level document (`Sec-Fetch-Dest:
  document`, or the header absent), never a frame (`Sec-Fetch-Dest: iframe`), a prefetch or prerender
  (`Sec-Purpose`), a HEAD or an asset. Write it when the response finishes (Node's `res.on('finish')`, or
  the framework's after-response hook). **A revalidated page is a page opened.** First read how the server
  caches its HTML: one that sends it with an `ETag` or `Last-Modified` and `Cache-Control: no-cache`
  answers every repeat load of an unchanged page with a `304` and no body. So count a 2xx response whose
  type is HTML, and a `304` to a request that says it is a top-level document (`Sec-Fetch-Dest: document`,
  since a 304 carries no type); never a 404, a redirect, a dot-file or an error page. Mount it before every
  route that answers a page, so the pages a route of their own answers before any static mount are counted
  too. A page shown in a frame of the same address is one visit, not two. Write it in the shape of the
  server's other structured log lines (their severity and message fields). The line holds the page path,
  the region (the `X-Client-Region` request header), `ref` and `utm_*` from the address, the referring
  host, and whether the user agent is a known bot: no IP address, no full user agent.
- **The consent change is one change.** The consent code, the link, the privacy policy and the
  project's consent tests change together; a test that pinned the old behaviour is updated to pin the new
  one, never deleted, and an assertion that is still true is never removed or loosened.
- **The acceptance tests come first, and run the real page.** Before the consent code, write the tests of the
  proposal's data scenarios, and the change is done when they pass: run, don't read. Each loads, in one fake
  page and in the page's real order, the site's REAL consent module, its tag loader and every vendor script
  they start, never the consent module alone, with fakes only at the edges: the region source (a header, no
  header, no answer in time, an error), the GPC flag, storage, and each tool's network. Each asserts what the
  Google tag receives (its commands, a `page_view` with `analytics_storage` granted) and what each vendor
  captures: a default region (both start on the first page, no banner), the opt-out link and GPC (nothing
  sent), a consent-first and an unknown region (nothing before a choice, Accept starts both, Reject keeps them
  off), and a framed page (it follows the top page's choice). Load them as the pages do and when: each loader
  that registers with the site's gate right after the consent module, and the region's answer at once and late
  (150 ms or more), since a decision that waits for the region must hold every gate closed meanwhile. Beside
  them, check what reaches the tag
  for: a consent-first region, a region that collects by default, an unknown region, a timeout, GPC, a stored
  choice, and a withdrawal then the next page. Also: the top page's Reject reaching a page of the same site
  framed in it that loaded the module (the denied update and each tool's opt-out there), with no link drawn
  in the framed page; a region that collects by default sending no `granted` ad type; and a page load with
  the choice unchanged making no tool call that sends an event. And the outcome, not only the signal: in a
  region that collects by default, with nothing stored, a loader registered through the site's gate runs, on
  the first page and the next; an Accept after a stored Reject turns a tool loaded later back on once it loads,
  in the real load order; the link added to a footer's list keeps the list's separator, and none is added beside
  a policy link inside a sentence or the banner. A Consent Mode update sent is not a tag started. A test that
  only matches the module's source text proves none of it.
- **The server's tests run the log line.** Request it as a browser would and check the lines it writes: a
  page, a `304` to a top-level document GET (counted), a `304` to anything else, a frame, a prefetch, a HEAD,
  an asset, a 404 and a redirect (none counted).
- **Make the change the way your tools allow.** On the web, Tartini AI makes it as a draft correction:
  written in the code workspace, the project's tests run to their end, then saved. In Claude Code, edit
  locally; the developer opens the Pull Request and Tartini checks it.
