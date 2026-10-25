---
description: Show this repository's Tartini AI project, what it has connected, the tracking on this branch, its metrics and its Measurement Plans. Reads only.
allowed-tools:
  - Bash(git remote get-url *)
  - Bash(git branch --show-current)
  - mcp__plugin_tartini_tartini__get_started
  - mcp__plugin_tartini_tartini__get_project_state
  - mcp__plugin_tartini_tartini__get_tracking_state
  - mcp__plugin_tartini_tartini__list_metrics
  - mcp__plugin_tartini_tartini__list_measurement_plans
---

Show where this repository stands in Tartini AI. Read only: change nothing and create nothing.

1. Run `git remote get-url origin` and `git branch --show-current`.
2. Call `get_started` with the remote. If it fails with a 401, say Claude Code is not signed in to Tartini AI (or its sign-in or key is no longer valid), how to fix it (the `setup` skill), and stop. If no project matches, say so and stop.
3. For the project, call `get_project_state`, `get_tracking_state` (with `branch` when this is not the default branch), `list_metrics` and `list_measurement_plans`.
4. Print, in this order:
   - **Project**: its name, and the tartini.ai link.
   - **Connected**: GitHub, Google Analytics and BigQuery, each connected or not, with the link to fix what is not.
   - **Tracking on this branch**: the events defined, the last check of the local change and its findings, the linked pull request and its state.
   - **Metrics**: each one's name, whether it is computed (its check passed) or not yet and why, and its latest value.
   - **Measurement Plans**: each one's title and version.
5. End with the one next step that matters most, in one sentence.
