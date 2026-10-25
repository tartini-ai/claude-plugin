# The BigQuery half

Part of the ga4-bigquery-consent skill.

- **What the GA4 export holds.** Only what GA4 received: with consent gated (basic), declining visitors
  send nothing at all. With Consent Mode advanced, Google exports their cookieless pings too, each session
  with a different `user_pseudo_id`, so they count as events and sessions, never as returning people;
  modelled data is never in the export. Every row says its consent state in `privacy_info`
  (`analytics_storage`, `ads_storage`: Yes, No or Unset); read your own rows by it before relying on any
  rule about identifiers.
- **Logs into BigQuery (Google Cloud).** A Cloud Logging sink routes the chosen log entries (the app's
  structured line, or the platform's request logs) into a BigQuery dataset in the same location as the GA4
  export, with partitioned tables. Give the raw dataset a partition expiration (30 days is common): it
  holds IP addresses. A scheduled query writes the daily aggregate (day, page, region, source, page
  loads, no IP) into a dataset of its own, and only that dataset is shared with the project's Tartini
  service account. Other hosts: Fastly streams logs to BigQuery natively; Vercel forwards them through Log
  Drains; Cloudflare and CloudFront write them to object storage, which BigQuery loads.
- **Two metrics.** Page loads, all visitors (`day`, `value` from the aggregate), and the consent rate:
  GA4 `page_view` events divided by the server's page loads, for the same days and pages. Filter bots
  before comparing, and say that the server count includes the site's own team.
