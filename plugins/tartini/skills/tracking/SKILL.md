---
name: tracking
description: Add, change, remove or list a website's analytics tracking, such as GA4 events and their parameters, Tartini Autocapture, page views and the Google tag, with Tartini AI keeping the event definitions and checking your local change before the pull request. Use it whenever someone asks to track a click, a sign up, a purchase, a form or any other user action, asks which events a site or project has or sends, wants GA4 or Google Analytics added or fixed in code, or changes code that sends analytics events, even if they never mention Tartini.
user-invocable: false
---

# Tracking with Tartini AI

Tartini AI keeps the tracking definitions and checks the change. You write the code in this repository and open the pull request yourself, as the person. How events are named, which parameters they carry and what never to send are in the Tracking guide on Tartini AI's server: read it before you change anything.

1. Run `git remote get-url origin` and `git branch --show-current`. Call `get_started` with the remote and choose the project (the `setup` skill covers anything missing).
2. Call `read_guide({ domain: "tracking" })` and follow it.
3. Call `get_tracking_state` (with `branch` when you are on a work branch) for what the code already sends, Tartini Autocapture's state and the Google tag. Answer "which events" questions from it, and say where each fact comes from.
4. To add or change tracking, work on a branch of your own, never the default branch (create one with git when needed). Confirm the definitions first with `create_tracking_event`, `update_tracking_event`, `remove_tracking_event` or `enable_autocapture`, each with `branch`. Then write the code from the definitions they return.
5. Run the project's whole test script to its end. Then check the change with `check_tracking_change`, built the way its description and the guide say, and fix every finding.
6. Commit, push and open the pull request with git and gh, then call `link_pull_request` with its number.
7. What GA4 really received is data: query the GA4 export with Google's BigQuery MCP (`execute_sql_readonly`), never guess it.
8. For a cookie banner, a consent manager or Google Consent Mode, read the `ga4-bigquery-consent` skill with `read_skill` first.
