---
name: ga4-bigquery-consent
description: Design how a website asks visitors for cookie consent and still measures its traffic with Google Analytics 4 and BigQuery. Read it before recommending or changing a cookie banner, a consent manager, Google Consent Mode, which visitors are counted, or a traffic total that does not depend on consent (server or CDN logs in BigQuery), and when a person asks why GA4 shows fewer visitors than they expect.
user-invocable: false
---

# GA4 + BigQuery and cookie consent

This practice lives on Tartini AI's server, so Claude Code and Tartini AI on the web read one version of it.

1. Call `read_skill({ name: "ga4-bigquery-consent" })` and follow the text it returns, whole.
2. If the call fails because Tartini AI is not connected, say so and use the `setup` skill. Do not design a consent set-up from memory instead.
