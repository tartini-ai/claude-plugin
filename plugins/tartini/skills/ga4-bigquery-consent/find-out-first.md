# Find out first

Part of the ga4-bigquery-consent skill.

Read these from the code and the data, in the turn of the request, before the proposal: both changes are
built from what you find here, and the yes turn does not look again. Ask the person only what neither can
answer. The code's answers come from one call to your exploration subagent (do-the-work.md), not from
reading the files yourself.

- **The consent mechanism.** None at all; a module of the site's own (a file whose name says consent,
  cookie or privacy, a banner in the markup); a consent manager (OneTrust, Cookiebot, Usercentrics,
  Didomi, Osano, Termly, CookieYes, iubenda, Quantcast, Klaro: their script host gives them away); Google
  Consent Mode (`gtag('consent', 'default', …)` in the code).
- **Where the Google tag starts relative to it.** Loaded only after a yes (Consent Mode "basic": no
  data at all is sent before consent, not even the consent state); loaded at once with consent denied by
  default (Consent Mode "advanced": while consent is denied, the tag sends cookieless pings, the consent
  state and measurements without cookies); loaded with no question at all. And how the site's own gate
  releases what waits for a category (a queue of loaders): only on a stored answer, or on any decision made
  for the page (write-the-change.md).
- **What the visitor can do.** Accept and Reject with equal weight; change their mind later; an opt-out
  link in the footer ("Your privacy choices"); whether `navigator.globalPrivacyControl` (GPC) is read.
- **Where the link will go.** Every place the site links its privacy policy as an item of a list of links (a
  footer's legal links, an account or settings menu, a sign-in page's links), with the list's separator and the
  markup of its items (element, classes, attributes, role); which of those the page's shell or menus draw after
  load; and the policy links inside running text and inside the consent banner, which get nothing beside them.
  And the layout's own fixed or sticky controls at every width (its media queries: a rail, a switcher, an
  assistant launcher) and its dialogs' z-index, which a fallback link must stay clear of and under.
- **Which pages frame which.** A page shown in a frame of another page of the same site (an app shell that
  changes page in place), whether both load the consent module, and where the choice is stored
  (`localStorage` or a cookie): that decides how the top page's decision and choices reach the framed page.
- **What the site promises.** The privacy policy's cookie section, every other public page that describes
  the old behaviour (the policy's other paragraphs, a subprocessor or vendor list, the terms, a cookie table),
  and the project's own tests that pin the consent behaviour and those sentences: a change to consent changes
  all of them, in the same change.
- **What else reads what you will change.** Code that sends only when `typeof window.gtag === 'function'`
  or reads `dataLayer`, and a tool that keeps an opt-out of its own (PostHog's, for example): the change
  must leave each of them right (write-the-change.md). For each tool method the change will call, what the
  version the site installs does (its source in the dependencies, or its docs): what it stores and sends. And
  when each tool loads relative to the consent module: a tool its tag loader loads later is reached where it
  starts, never by a call made before it exists.
- **Where the visitors are.** GA4 by country (the Data API, or the BigQuery export's `geo.country`), in
  users, never events. Say what it is: only visitors who were counted, so on a site that asks everyone it is
  the consenting few. Give the dates the data really covers, the first and last day it returned, never the
  window you queried (an export holds only the days since it was linked). Too little data is an answer too:
  with tens of users, give the counts and say they are too few to tell where visitors are, never "mostly";
  then ask the person whom the site is for.
- **Where the site runs.** The host and CDN decide where a visitor's country can come from (write-the-change.md).
  On Google Cloud, by search: the deploy script, and the backend service its load balancer sends the site to.
- **How the server answers a page.** The order in which it mounts its middleware, its page routes and its
  static files, the structured log line it already writes (where, and its fields), and how it caches its
  HTML (`ETag`, `Last-Modified`, `Cache-Control: no-cache`): a server that revalidates answers a repeat load
  of an unchanged page with a `304` (write-the-change.md).
- **BigQuery.** Whether GA4 exports to it (the `analytics_<property id>` dataset and its location), and
  whether server or CDN logs already land anywhere.
