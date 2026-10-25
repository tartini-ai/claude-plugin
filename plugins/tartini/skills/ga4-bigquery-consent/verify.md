# Verify

Part of the ga4-bigquery-consent skill.

- The region header: `curl -sI https://SITE/ | grep -i x-client-region` shows your own country.
- GA4 Realtime or DebugView: a visit from an opt-out region with no GPC appears; with GPC on it does not.
- From a consent-first region (or with the region header missing): the banner shows and nothing reaches
  Google before Accept.
- The server's log line appears for each page served, and the next day's aggregate row matches it.
- The project's own tests pass, including the updated consent tests.
