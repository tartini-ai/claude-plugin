# The BigQuery half

Part of the ga4-bigquery-consent skill.

- **What the GA4 export holds.** Only what GA4 received: with consent gated (basic), declining visitors
  send nothing at all. With Consent Mode advanced, Google exports their cookieless pings too, each session
  with a different `user_pseudo_id`, so they count as events and sessions, never as returning people;
  modelled data is never in the export. Every row says its consent state in `privacy_info`
  (`analytics_storage`, `ads_storage`: Yes, No or Unset); read your own rows by it before relying on any
  rule about identifiers.
- **Logs into BigQuery (Google Cloud).** A Cloud Logging sink routes the server's page-load lines into a raw
  dataset in the same location as the GA4 export, with partitioned tables whose partitions expire (30 days),
  and the project's Tartini service account may read that dataset alone: the line holds no IP address
  (platform-commands.md, whose script sets all of it). A sink of the platform's own request logs would hold IP
  addresses: then aggregate them (day, page, region, source, count) into a dataset of its own and share only
  that one. Other hosts: Fastly streams logs to BigQuery natively; Vercel forwards them through Log Drains;
  Cloudflare and CloudFront write them to object storage, which BigQuery loads.
- **Two metrics.** Page loads, all visitors (`day`, `value`, counted from the raw log lines), and the consent
  rate: GA4 `page_view` events divided by the server's page loads, for the same days and pages. Filter bots
  before comparing, and say that the server count includes the site's own team.
