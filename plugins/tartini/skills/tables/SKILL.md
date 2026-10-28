---
name: tables
description: Build or change a BigQuery table or view with Tartini AI's Tables guide, such as a daily table of sessions, sign ups or orders from the GA4 export, a view over other tables, a table that refreshes every day with a scheduled query, a new column or a backfill of earlier days. Use it whenever someone asks to create, change, refresh or schedule a table or a view in BigQuery, even if they never mention Tartini.
user-invocable: false
metadata:
  channels: mcp, plugin
---

# BigQuery tables with Tartini AI

Tartini AI keeps the rules for building tables in BigQuery (the grain, the `ds` column, the window a refresh reads, the MERGE, the schedule and its backfill) in the Tables guide on its server. You run the SQL with Google's BigQuery MCP, as the person, under their own Google permissions. The guide is the authority: where it and this skill differ, follow the guide.

1. Run `git remote get-url origin`, call `get_started` with it and choose the project (the `setup` skill covers anything missing).
2. Call `read_guide({ domain: "tables" })` and follow it.
3. Read the data with Google's BigQuery MCP: `list_dataset_ids`, `get_table_info` and `execute_sql_readonly`. Take every table, column and type from what they return, never from memory.
4. Write the SQL in the guide's order: `CREATE TABLE IF NOT EXISTS` with the table's schema, then the `MERGE` that fills it, then, for a table that refreshes, the scheduled query that runs that script every day.
5. Show the person every statement whole, and wait for their yes before any of it runs.
6. Run it with `execute_sql`, as the person. Label every table and view you create or change `assisted_by: tartini_ai`: `OPTIONS(labels=[("assisted_by", "tartini_ai")])` in a CREATE TABLE or a CREATE VIEW. On one that already exists, read its labels with `get_table_info` first and keep every one, since `ALTER TABLE ... SET OPTIONS(labels=...)` replaces the whole set. Never put `created_by: tartini_ai` on a table: that label is Tartini AI's own.
7. For a refresh, after their yes, create the scheduled query with `bq mk --transfer_config` as the guide says, or tell them how to create it in the BigQuery console (Scheduled queries).
8. Do the first run, and say what it really returned.
9. Name the table whole, `project.dataset.table`, so they can find it in the BigQuery console.

Never delete, overwrite or replace a source table, its rows or its columns: the person's own data and the GA4 export included. A table that Tartini AI itself manages and refreshes is made on tartini.ai, by Tartini AI: when that is what the person wants, say so.
