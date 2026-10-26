# Find out first

Part of the ga4-bigquery-consent skill.

Read these from the code and the data. Ask the person only what neither can answer. The code's answers come
from one call to your exploration subagent (do-the-work.md), not from reading the files yourself.

- **The consent mechanism.** None at all; a module of the site's own (a file whose name says consent,
  cookie or privacy, a banner in the markup); a consent manager (OneTrust, Cookiebot, Usercentrics,
  Didomi, Osano, Termly, CookieYes, iubenda, Quantcast, Klaro: their script host gives them away); Google
  Consent Mode (`gtag('consent', 'default', …)` in the code).
- **Where the Google tag starts relative to it.** Loaded only after a yes (Consent Mode "basic": no
  data at all is sent before consent, not even the consent state); loaded at once with consent denied by
  default (Consent Mode "advanced": while consent is denied, the tag sends cookieless pings, the consent
  state and measurements without cookies); loaded with no question at all.
- **What the visitor can do.** Accept and Reject with equal weight; change their mind later; an opt-out
  link in the footer ("Your privacy choices"); whether `navigator.globalPrivacyControl` (GPC) is read.
- **What the site promises.** The privacy policy's cookie section, and the project's own tests that pin
  the consent behaviour: a change to consent changes both, in the same change.
- **Where the visitors are.** GA4 by country (the Data API, or the BigQuery export's `geo.country`). Say
  what it is: only visitors who were counted, so on a site that asks everyone it is the consenting few.
  Too little data is an answer too ("not enough to tell"); then ask the person whom the site is for.
- **Where the site runs.** The host and CDN decide where a visitor's country can come from (write-the-change.md).
  On Google Cloud, by search: the deploy script, and the backend service its load balancer sends the site to.
- **BigQuery.** Whether GA4 exports to it (the `analytics_<property id>` dataset and its location), and
  whether server or CDN logs already land anywhere.
