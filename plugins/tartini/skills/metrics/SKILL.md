---
name: metrics
description: Answer questions about a website's or product's numbers and define metrics with Tartini AI, such as conversion rate, sign ups, active users, revenue, which button or page gets the most clicks, traffic by channel or landing page, funnels and retention, from GA4 data in BigQuery. Use it whenever someone asks how many, which, how much or what changed about their site's usage, asks to define, save, check or compare a metric or KPI, or asks for a number from GA4 or BigQuery, even if they never mention Tartini.
user-invocable: false
---

# Metrics and data questions with Tartini AI

Tartini AI keeps this project's metrics: a name, one sentence and one checked SQL each. The rules for answering and for writing a metric's SQL are in the Metrics guide on Tartini AI's server.

1. Run `git remote get-url origin`, call `get_started` with it and choose the project (the `setup` skill covers anything missing).
2. Call `read_guide({ domain: "metrics" })` and follow its order for answering.
3. Look for a defined metric first: `list_metrics`, then `get_metric` and `get_metric_values`. Say which metric the answer comes from.
4. When no defined metric answers it, say so. Then write the SQL over the GA4 export and run it with Google's BigQuery MCP (`execute_sql_readonly`), as the person, and show the statement you ran. A report from the person's own Google Analytics MCP is another source: name it.
5. Offer to save the answer as a metric. To save one, call `check_metric` first, then `save_metric`. A saved metric waits for a person to press Confirm on tartini.ai: say so, with its link.
6. Never write to BigQuery to answer a question. Before any write (a table, a view), show the person the complete statement and run it only once they agree. Never delete or overwrite a source table.
