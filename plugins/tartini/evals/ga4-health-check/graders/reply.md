---
type: llm
---

PASS if the final reply lists the results of the checks (the Google tag, Tartini Autocapture, page_view and auto_ events in GA4, the custom dimensions, the BigQuery export) with evidence such as counts or names, finds no problem with page_view or with the custom dimensions, and says nothing was changed or asks before changing anything.
FAIL if the reply says page_view is missing, says a custom dimension or metric is not registered, or says it changed code, GA4 settings or BigQuery.
