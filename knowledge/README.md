# Tartini AI knowledge

The domain guides and reference documents Tartini AI works from, published for reading. Every file is generated
from the source Tartini AI's server reads and is never edited here: a guide is byte for byte the text the server
sends, and a reference is the whole document the guides draw on.

These copies are for reading. Tartini AI on tartini.ai and Claude Code both read the guides live from the server
(Claude Code with `read_guide`), so a guide always matches the tools that server offers; nothing in this folder
is installed with the plugin. Each project's live facts are never published: a web guide marks where they go.
Tartini AI's skills are in [`plugins/tartini/skills/`](../plugins/tartini/skills/).

## Guides

| File | What it is |
| --- | --- |
| [guides/tracking.web.md](guides/tracking.web.md) | The Tracking guide, as Tartini AI reads it on tartini.ai (each project's live facts marked, not published) |
| [guides/tracking.mcp.md](guides/tracking.mcp.md) | The Tracking guide, as Claude Code reads it with read_guide |
| [guides/tables.web.md](guides/tables.web.md) | The Tables guide, as Tartini AI reads it on tartini.ai (each project's live facts marked, not published) |
| [guides/tables.mcp.md](guides/tables.mcp.md) | The Tables guide, as Claude Code reads it with read_guide |
| [guides/measurement_plan.web.md](guides/measurement_plan.web.md) | The Measurement Plan guide, as Tartini AI reads it on tartini.ai (each project's live facts marked, not published) |
| [guides/measurement_plan.mcp.md](guides/measurement_plan.mcp.md) | The Measurement Plan guide, as Claude Code reads it with read_guide |
| [guides/metrics.web.md](guides/metrics.web.md) | The Metrics guide, as Tartini AI reads it on tartini.ai (each project's live facts marked, not published) |
| [guides/metrics.mcp.md](guides/metrics.mcp.md) | The Metrics guide, as Claude Code reads it with read_guide |

## References

| File | What it is |
| --- | --- |
| [references/analytics-business-semantics.md](references/analytics-business-semantics.md) | Analytics business semantics (business grain, deduplication, environments). Read by every Tartini AI conversation, whole |
| [references/bigquery-table-creation-best-practices.md](references/bigquery-table-creation-best-practices.md) | BigQuery scheduled-table creation reference. Read by the Tables guide (web); the Tables guide (mcp) |
| [references/ga4-export-sql-reference.md](references/ga4-export-sql-reference.md) | GA4 export SQL reference. Read by the Tables guide (web); the Tables guide (mcp); the Measurement Plan guide (web); the Measurement Plan guide (mcp); the Metrics guide (web); the Metrics guide (mcp) |
| [references/measurement-plan-best-practices.md](references/measurement-plan-best-practices.md) | Measurement Plan best practices and document template. Read by the Measurement Plan guide (web); the Measurement Plan guide (mcp) |
| [references/measurement-plan-scenarios.md](references/measurement-plan-scenarios.md) | Measurement Plan scenarios and recipes. Read by the Measurement Plan guide (web); the Measurement Plan guide (mcp) |
| [references/metric-templates.md](references/metric-templates.md) | Metric templates. Read by the Measurement Plan guide (web); the Measurement Plan guide (mcp); the Metrics guide (web); the Metrics guide (mcp) |
| [references/onboarding-intents.md](references/onboarding-intents.md) | Onboarding reference (goals, the systems they need, setup plan steps). Read by every Tartini AI conversation, whole |
| [references/tables-best-practices.md](references/tables-best-practices.md) | Tables reference. Read by the Tables guide (web) |
| [references/tracking-events-best-practices.md](references/tracking-events-best-practices.md) | GA4 Event Logging reference. Read by the Tracking guide (web); the Tracking guide (mcp) |
| [references/tracking-recommendation-policy.md](references/tracking-recommendation-policy.md) | Tracking recommendation policy (GA4 foundation, Autocapture first, business outcomes). Read by the Tracking guide (web); the Tracking guide (mcp) |
| [references/website-preview-playbook.md](references/website-preview-playbook.md) | Website Preview reference (+ mistakes ledger). Read by the Tracking guide (web); the Tracking guide (mcp) |
