# Sources

Part of the ga4-bigquery-consent skill.

Checked on 2026-10-22.

- Google, consent mode: developers.google.com/tag-platform/security/concepts/consent-mode (basic and
  advanced); developers.google.com/tag-platform/security/guides/consent (default, update, region,
  wait_for_update); support.google.com/analytics/answer/9976101 (cookieless pings).
- Google, GA4: support.google.com/analytics/answer/11161109 (behavioural modelling thresholds);
  support.google.com/analytics/answer/12017362 (IP addresses); support.google.com/analytics/answer/7029846
  (export schema, `privacy_info`); support.google.com/analytics/answer/9358801 (cookieless pings in the
  export); support.google.com/analytics/answer/13644080 (a different `user_pseudo_id` per session).
- Google, policy: www.google.com/about/company/user-consent-policy/ (EEA, UK and Switzerland).
- Google Cloud: docs.cloud.google.com/logging/docs/export/bigquery (logs routed to BigQuery);
  docs.cloud.google.com/load-balancing/docs/https/custom-headers-global (`{client_region}`).
- Europe: EDPB Guidelines 05/2020 on consent; the EDPB Cookie Banner Taskforce report (2023); EDPB
  Guidelines 2/2023 on the technical scope of Article 5(3) ePrivacy; CNIL, "Sheet n°16: use analytics on
  your websites and applications" (www.cnil.fr/en/sheet-ndeg16-use-analytics-your-websites-and-applications).
- United Kingdom: the ICO's guidance on storage and access technologies (2026), and the Data (Use and
  Access) Act 2025, Schedule 12 (in force 5 February 2026).
- United States: oag.ca.gov/privacy/ccpa (opt-out of sale or sharing; GPC); 11 CCR §7025 (opt-out
  preference signals); w3c.github.io/gpc (`navigator.globalPrivacyControl`).
- Practice: Simo Ahava on Consent Mode v2; CookieFirst and CookieYes on basic versus advanced and
  geo-targeted banners; PostHog's and Plausible's cookieless designs; Mixpanel's IP-to-region enrichment;
  Fastly's and Vercel's log export.

Checked on 2026-10-26, for the platform script and the server's count:

- Google Cloud CLI 582.0.0, read for what it does: `compute backend-services update` replaces the whole list of
  custom headers it is given (`--custom-request-header`, `--custom-response-header`, each repeatable), and
  `logging sinks create` gives every sink its own writer identity. Its outputs were recorded read-only: a
  backend with no custom headers prints `null` in JSON, a tab in `value(a,b)` and one empty line with
  `--flatten`; a list prints `;`-joined in `value()` and one item a line with `--flatten`; a missing sink is
  exit 1 with `NOT_FOUND` on stderr; with bq 2.1.37 a missing dataset is exit 2 with `Not found: Dataset`
  on stdout, wrapped over lines, and a dataset-level grant shows in `access` as `READER` or `WRITER` with
  `userByEmail`.
- BigQuery: docs.cloud.google.com/bigquery/docs/reference/standard-sql/data-control-language (`GRANT ... ON
  SCHEMA`, a role on one dataset).
- Fetch Metadata: w3c.github.io/webappsec-fetch-metadata/ (`Sec-Fetch-Dest`: `document` for a top-level
  page, `iframe` for a frame); Chrome's prefetch and prerender requests carry `Sec-Purpose`.

Checked on 2026-10-26, for the consent-first list, GPC over a stored choice, withdrawing and the server's count:

- The EU's outermost regions: TFEU Article 349 (Guadeloupe, French Guiana, Martinique, Mayotte, Réunion,
  Saint-Martin, the Azores, Madeira and the Canary Islands; eur-lex.europa.eu/eli/treaty/tfeu_2016/art_349/oj)
  and the European Parliament's fact sheet on them (europarl.europa.eu/factsheets/en/sheet/100); European
  Council Decision 2010/718/EU (Saint-Barthélemy an overseas country and territory, outside the EU, from 1
  January 2012); Protocol No 2 on the Åland Islands to Finland's Act of Accession
  (eur-lex.europa.eu/eli/treaty/acc_1994/act_1/pro_2/sign): the Treaties apply there, and its derogations are
  on property, establishment and indirect tax.
- The codes: ISO 3166-1 alpha-2 (GP, GF, MQ, YT, RE, MF, AX); Unicode CLDR's region codes, which add IC (the
  Canary Islands) and EA (Ceuta and Melilla), and which Google Cloud's `{client_region}` gives
  (docs.cloud.google.com/load-balancing/docs/https/custom-headers-global).
- California: 11 CCR §7025(c)(3) (law.cornell.edu/regulations/california/11-CCR-7025): an opt-out preference
  signal that conflicts with a business-specific setting allowing sale or sharing is processed as an opt-out;
  the business may tell the consumer of the conflict and ask for consent, and once they consent it may ignore
  the signal. §7025(c)(6): a site may show that it honoured the signal.
- PostHog: posthog.com/docs/privacy/data-collection (`opt_out_capturing()` is kept in the browser, in a cookie
  or local storage; `opt_in_capturing()` undoes it).
- Node.js: nodejs.org/api/http.html (a response's `finish` event, once it has been handed to the system).

Checked on 2026-10-26, for framed pages, the Consent Mode types, revalidated pages and vendor calls:

- Google, consent types: developers.google.com/tag-platform/security/concepts/consent-mode (`analytics_storage`
  for analytics; `ad_storage`, `ad_user_data` and `ad_personalization` for advertising).
- The HTML Standard's web storage (html.spec.whatwg.org/multipage/webstorage.html) and MDN's "Window: storage
  event": a change to `localStorage` fires `storage` in the other documents that share it, not in the one that
  made it; a cookie fires no event.
- HTTP: RFC 9110 §15.4.5 (`304 Not Modified` answers a conditional GET and need carry no content type) and RFC
  9111 §5.2.2.4 (`no-cache`: a cache revalidates before every reuse).
- PostHog: posthog.com/docs/references/posthog-js (`opt_in_capturing()` captures an `$opt_in` event unless
  `captureEventName: false`; `has_opted_out_capturing()` says whether the visitor opted out).

Checked on 2026-10-26, for a tool loaded later and the export's dates:

- PostHog: posthog.com/docs/libraries/js/config (`loaded`: "A function to be called once the PostHog scripts
  have loaded successfully"); posthog.com/docs/libraries/js (the snippet's stub methods push each call onto a
  queue the library reads once it loads; a page with no stub has no `window.posthog` until its loader ran).
- Google Analytics: support.google.com/analytics/answer/9823238 ("Once the linkage is complete, data should start
  flowing to your BigQuery project within 24 hours") and answer/9358801 (it "exports all the raw, unsampled event
  data once per day from the previous day"); neither page describes exporting days from before the link.

Checked on 2026-10-27, for the rough cost a proposal names:

- Google Cloud Observability pricing (cloud.google.com/stackdriver/pricing): Cloud Logging does not charge to
  route log entries to a supported destination, the destination's own charges apply; log storage is $0.50 a GiB
  with the first 50 GiB a project a month free.
- BigQuery pricing (cloud.google.com/bigquery/pricing): streaming inserts $0.01 per 200 MB; active storage with
  the first 10 GiB a month free.

The two turns, a proposal first and the work after the person's yes, follow the approval gate coding agents put
before a plan is carried out: Claude Code's plan mode (code.claude.com/docs/en/common-workflows), Aider's
architect and editor modes (aider.chat/docs/usage/modes.html), GitHub's Spec Kit (github.com/github/spec-kit)
and Kiro's specs (kiro.dev/docs/specs).
