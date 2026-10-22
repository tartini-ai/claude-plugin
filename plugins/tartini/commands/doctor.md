---
description: Health-check a site's analytics, such as the Google tag and Tartini Autocapture in the code, what GA4 received in the last 7 days, GA4 custom dimensions and the BigQuery export. It checks first and changes nothing, then you pick which fixes to make.
argument-hint: "[GA4 property id]"
allowed-tools:
  - Bash(git remote get-url *)
  - Bash(git branch --show-current)
  - mcp__plugin_tartini_tartini__get_started
  - mcp__plugin_tartini_tartini__get_project_state
  - mcp__plugin_tartini_tartini__get_tracking_state
  - mcp__plugin_tartini_tartini__read_guide
  - mcp__plugin_tartini_bigquery__list_dataset_ids
  - mcp__plugin_tartini_bigquery__list_table_ids
---

# Analytics doctor

Check first and change nothing. Then list every result with its fix, and ask the person which fixes to make. Make only those.

## 1. Check (read only)

Run every check. A check that cannot run is "not checked", with the reason. It is never a pass.

1. **Project.** Run `git remote get-url origin`, call `get_started` with it and choose the project as the `setup` skill says.
2. **Code**, with Tartini AI's checks. Call `get_tracking_state` (with `branch` when this is not the default branch) and note:
   - the Google tag, in the code and on the live site, and the baseline findings with their fixes;
   - Tartini Autocapture: verified, partial or absent, and its version;
   - the custom events the code sends.
3. **GA4**, with the person's own Google Analytics MCP (Google's `analytics-mcp`, which only reads), when it is added. The GA4 property id the person gave, if any: $ARGUMENTS. Without one, use the property the project has connected (from `get_started` or `get_project_state`), else look in `get_account_summaries`, and ask when more than one could be it. Then:
   - `run_report` for the last 7 days, dimension `eventName`, metric `eventCount`: is `page_view` there, and is any event whose name starts with `auto_`?
   - `get_custom_dimensions_and_metrics`: when Autocapture is installed or `auto_` events arrive, compare it with the custom dimensions and metrics Tartini Autocapture needs. Take that list from Tartini AI's Metrics guide (`read_guide({ domain: "metrics" })`), never from memory.
   - Without a Google Analytics MCP, mark these "not checked" and say how to add it (this plugin's README).
4. **BigQuery export**, with Google's BigQuery MCP (the Google Analytics MCP has no tool for this link). In the Google Cloud project the person names, or the one the project has connected, call `list_dataset_ids`: is there `analytics_<property id>`? Then `list_table_ids` on it: is there an `events_YYYYMMDD` table from the last few days, or an `events_intraday_` table? No dataset means the export is not linked. Only old tables means it is linked but not exporting.

## 2. Report

Print one line per check, in this order: project, Google tag, Autocapture, events in the code, `page_view` in GA4, `auto_` events in GA4, custom dimensions and metrics, BigQuery export. Each line says pass, problem or not checked; the evidence (names, counts, dates); and for a problem, its fix in one sentence.

Then ask once which of the problems to fix, listing them by number, and wait for the answer.

## 3. Fix only what the person picked

- In the code: through the `tracking` skill (the definitions in Tartini AI, the code in this repository, `check_tracking_change`, the person's own pull request). For consent, read the `ga4-bigquery-consent` skill first.
- In GA4 (custom definitions, the BigQuery link, Enhanced Measurement): the Google Analytics MCP only reads, so give the exact steps in GA4 Admin, and never say you made them.
- Change nothing the person did not pick.
