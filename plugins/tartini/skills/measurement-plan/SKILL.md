---
name: measurement-plan
description: Write, revise or read a Measurement Plan with Tartini AI, the document that says what a launch, a landing page, a checkout, an ad campaign or an experiment should measure, with its goal, core metrics, the tracking it needs and the BigQuery query behind each metric. Use it whenever someone asks what to measure, wants a tracking plan, an analytics plan, a KPI plan or success metrics for a feature or a launch, or asks to change, compare or implement an existing plan, even if they never say Measurement Plan.
user-invocable: false
---

# Measurement Plans with Tartini AI

A Measurement Plan is one document in a Tartini AI project. Its template and writing rules are in the Measurement Plan guide on Tartini AI's server: follow them over anything here.

1. Run `git remote get-url origin`, call `get_started` with it and choose the project. A plan is saved into a project: offer `create_project` when there is none, and create it only when the person agrees.
2. Call `read_guide({ domain: "measurement_plan" })` and follow it.
3. Read what exists first: `list_measurement_plans` and `get_measurement_plan`.
4. Gather the facts before you write: `get_tracking_state` for what the site already sends, Google's BigQuery MCP (`list_dataset_ids`, `get_table_info`, `execute_sql_readonly`) for the data there is, and your own web fetch for a public page.
5. A new plan: `draft_measurement_plan`. From Claude Code it is saved at once, so say it is saved only when its result says so. A change: `edit_measurement_plan_section` (one request is one version) or `update_measurement_plan`.
6. Implementing a plan: `check_implementation_readiness` for the capabilities it needs, then the `tracking` skill for its events and the `metrics` skill for its metrics.
