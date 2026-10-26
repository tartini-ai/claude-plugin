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
