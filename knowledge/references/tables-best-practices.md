# Tables Feature — Best Practices

Project-scoped, real-data Tables with a hard data-source gate. Canonical P0 product design:
[`tables-product-design.md`](tables-product-design.md). System summary:
[`../overall/DESIGN.md`](../overall/DESIGN.md) §13. Customer-side Google Cloud setup:
[`BigQuery Tables permissions and Project Admin checklist`](bigquery-permissions.md). Approved
creation/update contract for scheduled physical tables:
[`BigQuery scheduled-table creation and update best practices`](bigquery-table-creation-best-practices.md).
Approved BigQuery Saved Query/editor contract:
[`Query Workspace`](query-workspace-design.md).

> **Architecture status:** OpenCode + OpenRouter is implemented; see
> [`opencode-openrouter-runtime.md`](../overall/opencode-openrouter-runtime.md). Tables already uses
> the one control-plane core shared with Dashboard and Tracking. The canonical contract is
> [`unified-toastia-mcp.md`](../overall/unified-toastia-mcp.md). Do not narrow a Tables capability or
> merge its BigQuery policy into another domain while extracting shared mechanics.

> **Cloud-only status: IMPLEMENTED.** The shared source gate, the project-scoped Workspace UI and Assistant
> conversations are BigQuery-only. File-event sources, logging-table paths and fallbacks are removed;
> legacy rows are refused explicitly. See
> [`cloud-native-product-architecture.md`](../overall/cloud-native-product-architecture.md).
>
> **BigQuery warehouse execution is also IMPLEMENTED** (`app/bigquery.js` and its single-purpose
> modules), as the project's own keyless managed service account (`tdata-*`), which the customer's
> administrator authorizes in their own IAM console — no person's OAuth grant is held. A connected Cloud
> Project supports each read, SQL, managed-object and schedule operation that the service account's
> current IAM permits; Tables owns the object metadata and BigQuery owns the provider. Offline tests:
> `app/test/bigquery-*.test.js`.
>
> **Still NOT solved in current code:** `query_bigquery` is deliberately read-only while general writes require one concrete,
> fully qualified statement resolvable by `execute_bigquery_sql`; a
> managed object's provider name is immutable; the legacy Dashboard event-count path needs an
> event-name and timestamp column, while plan/query widgets use their own validated fields/results;
> and **no live Google/BigQuery call has ever been
> made** — every test injects a fake client.
>
> **Source-catalog grounding is IMPLEMENTED** in `app/bigquery-source-catalog.js`: UI and Assistant
> consume one latest-known Project catalog with exhaustive references and complete nested schemas.
>
> **Single-agent product architecture and OpenCode adapter: IMPLEMENTED.** The custom per-step
> planner and the second reply composer are gone. A Tables request is part of one Tartini AI
> (`project_assist`) turn, backed by the scoped Tables tool pack/gateway, a general BigQuery
> execution primitive and `publish_artifact`, which publishes a file the agent wrote with its own tools
> in its working directory (`tables.js` `assistantDomain`, `table-agent-gateway.js`,
> `table-agent-mcp.js`, `table-agent-artifacts.js`, `sandbox/turn-workspace.js`, `bigquery-boundary.js`,
> `bigquery-execution.js`).
>
> **The scheduled-table physical contract AND historical backfill are both IMPLEMENTED.** New
> scheduled tables use the contract in
> [`bigquery-table-creation-best-practices.md`](bigquery-table-creation-best-practices.md): Daily at
> 02:00 UTC, required `ds` partitioning, bounded idempotent incremental DML and no expiration. The
> target is explicitly created and read back before the first `MERGE`. A backfill replays that table's
> EXISTING production TransferConfig at historical logical run times — one at a time, behind its own
> confirmation, over a durable job that survives a restart. It writes no SQL of its own, creates no
> second config and runs on no local scheduler (§14).
>
> **Query Workspace is IMPLEMENTED.** `saved_queries`, `/queries.html`, the durable `QUERY`
> conversation item and the nullable `bigquery_jobs.query_id` link all exist, with offline tests.
> Saving is metadata and makes no provider call; running goes through the ONE existing read-only
> `runReadQuery`/`bigquery_jobs` path; opening or selecting a query executes nothing; and deleting a
> Saved Query clears its job links without deleting one job.

## Rule 1 — One BigQuery source authority; a workspace is not data

Every table create, sync, refresh, preview and export path asks the same
`resolveTableDataSource(projectId)`-equivalent authority. A GitHub workspace, host path or file is
never a row source.

The authority keeps credential configuration separate from row readiness:

```text
Cloud, no project `google` connection        → not_connected; rows/create blocked
Cloud, legacy/incomplete connection           → configured_not_ready; rows/create blocked
Cloud, account authorized but adapter failed  → configured_not_ready; execution blocked
Cloud, account ready + read only              → connected; reads/query as permitted, writes guided
Cloud, account ready + output write only      → connected; output operations as permitted, reads guided
Cloud, account ready + full IAM               → connected; rows/SQL/all table types/schedules allowed
```

For BigQuery, compute `canReadRows`, `canRunSql`, create/update/delete flags and
`canScheduleQueries` independently from current IAM. Never flip them as one bundle. Reads follow
source permissions; writes are constrained to the Output Dataset (the main dataset) and its
corresponding permissions — or to a dataset the person named, confirmed on a card every time, where
Tartini AI only creates new objects and changes only the ones it recorded there.

`canScheduleQueries` is a fact about a DIFFERENT Google API — the BigQuery Data Transfer Service —
and must never be derived from `canRunSql && canCreateTables`. Only a real transfer-config lifecycle
proves it, and it needs the Data Transfer API, the scheduled-query permissions and the delegation from
the customer's Data Transfer service agent to the project's service account
([bigquery-permissions.md](bigquery-permissions.md) checks 8, 10 and 12). So a connection can be
`ready` + `limited_access`: connected, fully usable, and unable to schedule until those are in place.
Connection state and access level are separate badges and one never overrides the other.

`google_analytics` is Analytics Admin configuration for Website Preview and never a Tables row
source. An active `google` connection record is necessary for Cloud Tables but is not proof rows can
be read.

## Rule 2 — All table facts are real (NO-MOCKS)

BigQuery rows and schema come from real provider responses under current IAM. Row counts, sizes,
projects, connection badges, timestamps,
conversation summaries and table changes are never copied from design screenshots or fixtures into
production.

## Rule 3 — No implicit file-backed table

Project creation, boot and Tracking approval create no placeholder table. Source objects come from
BigQuery catalog discovery; managed objects require an explicit validated action and real provider
receipt. The migration may delete obsolete system-generated metadata shells transactionally without
calling a provider delete or touching user-owned BigQuery resources.

## Rule 4 — Unsupported reads fail closed and preserve facts

`syncSchema`, `refreshTable`, preview and export use the same source authority. An unsupported source
never falls back to a file or workspace; it does not clear schema, set rows to
zero, advance refresh time or log a fake success. Present-but-blocked metric metadata remains visible
with a derived Source required state.

## Rule 5 — Creation is gated on the server

All direct UI, Assistant, Duplicate, and other table-row creation paths reuse one validated
table-creation service. The backend is the final authority. A Project without ready BigQuery
capability keeps HTTP 409 `data_source_required`; no rejected path changes metadata or conversation
counts.

**A BigQuery project has no manual create form, and must not grow one back.** Its create CTA opens the
Assistant (DESIGN §13.3a): one OpenCode turn uses the complete source catalog, prefers
`create_managed_object`, and reaches deterministic validation → `createWarehouseTable`. Deleting
that form deleted a SURFACE, not the service behind it —
`createWarehouseTable` and `/api/projects/:projectId/bigquery/objects` are unchanged, because Duplicate
and the object API still need them and every path must keep sharing one validated creation service.
Do not re-add a SQL textarea, an object-kind picker or a destination field to the workspace: a
destination the user or a model can type is exactly what the Output Dataset boundary exists to prevent.
(A dataset the PERSON names in the conversation is the one exception, and it is not a typed
destination: the tool's `dataset` is checked against live state and confirmed on a card that names it.)

## Rule 6 — Project-scoped Tables workspace (Redesign v2)

```text
/tables.html                                      canonical redirect to /projects.html (aggregate list retired)
/tables.html?project=<id>                         Project Workspace, the Tartini AI panel on the left (or inline setup if disconnected)
/tables.html?project=<id>&conversation=<id>       …the panel continuing that conversation
/table.html?id=<id>                               Existing table detail (managed)
/table.html?project=<id>&source=<bq reference>    Source table detail (no managed lifecycle); also the ONE
                                                  link form for any table a reply names — a Tartini
                                                  table moves to `?id=`, `…_*` opens its newest day
```

In Redesign v2 ([`../overall/project-workflow-redesign.md`](../overall/project-workflow-redesign.md)), the legacy bare
`/tables.html` aggregate Project List is **retired**; navigating to bare `/tables.html` canonically redirects to `/projects.html`.
Tables operates strictly in project-scoped workspace mode (`/tables.html?project=<id>`).
When BigQuery is disconnected, `/tables.html?project=<id>` displays the inline BigQuery setup assistant directly for that project
(never asking which project to connect). The Workspace and Connections' BigQuery card enter the same server-owned resumable flow.

Project Workspace fetches only that Project's tables with `GET /api/tables?projectId=`. It owns no
transcript or conversation of its own: Tartini AI is the panel on its left (the detail shell), as on
the table and Query Workspace pages, and its "Create a table or query with AI" only focuses that
panel's composer. The existing table detail remains the third level.

A connected warehouse Project's tables are mostly NOT rows in Tartini AI's managed-table database, so
the Workspace's table count is managed rows PLUS the canonical source-catalog count. That count is
a separate request (`GET …/source-tables/count`) because it cannot be produced synchronously; the
cell says it is counting until the answer arrives, and never prints the managed count alone as a
total. It reads the same latest-known catalog/state as the workspace. An incomplete catalog reports
"at least this many" or unknown; no number may be assumed or hardcoded.

GA4 destination/configuration badges are context only. They never substitute for BigQuery row-source
readiness.

## Rule 6a — BigQuery connection setup enables the real warehouse execution path

`google` (BigQuery) and `google_analytics` are separate services with separate state and business
logic. BigQuery is reached AS the project's keyless managed service account (`tdata-*`): setup names
that account, the customer's administrator grants it in their own IAM console, and a real
`projects.list` as the account proves the access — there is no consent screen and no person's refresh
token. Credentials never enter the browser, model, logs or connection metadata. The generic
pasted-credential route rejects `github`, `google`, and `google_analytics`.

Do not provide a Source Dataset picker or read allowlist. Paginated server discovery lets the user
choose one Output Dataset for write/query-destination capability; if none is accessible, preserve a
limited connection and show the permission/selection next step. Its project is query/billing and its
location governs WRITE jobs; a read runs where its data is, whatever the Output Dataset's location, and
data the account can read in another location than the Output Dataset is a warning, never a failure.
Before explicit final confirmation, verify identity,
service account permissions, dataset metadata, a low-cost/zero-scan query job, and create/delete of a unique
expiring temporary table where permitted. Treat each IAM denial as a false capability with guidance,
not a connection failure. Surface cleanup failure. Preserve legacy user OAuth connections as
blocked under `GOOGLE_DATA_AUTH_MODE=service_account_only` until migrated to managed service accounts.

A ready connection records only safe identity, Output Dataset and actual capability facts and
uses the production adapter. IAM probe failure makes only the affected capability unavailable; it
does not invalidate the connection or suppress permitted reads/writes. Never return fake/seeded rows.

Every specialized Tartini AI managed-object write—query destination, logging/metric/derived/intermediate
table, view, materialization or scheduled-query output—must remain in Output Dataset. Reads may
reference any current-IAM-readable source. The implemented general BigQuery gateway may target other
resolved IAM-authorized resources when a specialized primitive cannot satisfy the request, but it
must enforce the source destructive-effect boundary and resync any managed object it touches.
Validate targets, location and Query/Billing Project; dry-run/cost-bound where supported; persist
provider job ids and truthful terminal state.

Permission failures return `bigquery_permission_required` with blocked action/resource, exact
missing permissions, least-privilege role examples and Reverify. Suggest Data Viewer/equivalent for
source data, Job User/equivalent for Query/Billing Project jobs, and Data Editor/equivalent for
Output Dataset table lifecycle. Tartini AI never grants IAM itself. Recheck before every operation so
new grants start working and revoked permissions downgrade only affected capabilities.
A denied read is an error, never zero rows; a denied provider write creates no metadata shell and no
Assistant success receipt.

## Rule 6b — One description vocabulary, one schema grid, every table

Where a description came from is part of the description. Every column and table description carries
a `descriptionSource`: `bigquery` (the customer's warehouse team), `defined` (written into the
managed object's definition, or edited by the user), `toastia` (AI-generated) or `template`
(the generic placeholder — nobody's description, and therefore *missing*). It is derived in ONE place
per surface from facts already stored; never introduce a second, drifting attribution.

Both source and managed detail tabs render through one column grid, one description block and one
origin map, differing only where provider ownership does. **Generation is automatic, and there is no button.** Listing a warehouse project's source tables
starts a server-owned job that describes every undocumented table and column in that project; opening
one table starts the same project-wide job rather than describing only what is on screen. It is a job
because the work is minutes long: one per project at a time, a second trigger joins the running one,
progress is polled through a free status route (`GET …/source-descriptions`), and the expensive
listing is re-read exactly once when it finishes so the counts come from BigQuery rather than from
the job's tally. Generation fills blanks only: it
never rewrites an existing description, never writes back to BigQuery, and a person editing a
generated sentence takes the attribution back. A job that fails keeps its reason visible and keeps
whatever succeeded.

**Where a generated description GOES depends on who owns the table (Rule 6d), and "never writes back
to BigQuery" is the rule for the customer's SOURCE tables.** A table Tartini AI created is Tartini AI's,
and its descriptions belong in BigQuery.

## Rule 6c — UI and Assistant share one canonical BigQuery source catalog

Implemented in `app/bigquery-source-catalog.js`. There is exactly one provider-discovery
implementation and one Project-level latest-known metadata catalog:

```text
BigQuery
  → bigquery.listSourceTables({ projectId })        exhaustive, metadata + complete nested schema
  → refresh/reconcile the Project source catalog
      ├── GET …/source-tables            the workspace list  (refreshes, then reads)
      ├── GET …/source-tables/count      a project's count   (reads; builds one if there is none)
      ├── GET …/source-table             the detail page     (live single read, recorded back)
      └── assistantFacts().source_catalog the Assistant      (reads; builds one if there is none)
```

The refresh path reuses the managed-`bq_reference` filter, `sourceTableDetail()`, `sourceColumns()`
and `withDescriptions()` semantics, and never reimplements the project → dataset → table → metadata
walk in `tables.js`. Each record carries the Tartini AI Project id, the connection identity that
discovered it, the full BigQuery reference and its component ids, object type, location, friendly
name, row count, size, created/last-modified time, the provider description, the complete nested
schema, `metadata_complete` and `last_synced_at`. Unknown provider facts stay NULL — an unreported row
count is not an empty table. `bigquery_source_catalog_state` carries one refresh generation
(`running | complete | partial | failed`), `last_success_at`, the discovered count and redacted
problems.

**No product visibility ceiling.** Discovery follows `nextPageToken` to exhaustion and bounds nothing
by project, dataset or table count: a ceiling makes a real table unreachable to the Assistant, and no
fixed number answers "which tables do I have?". Bound RESOURCES instead — concurrency, timeouts,
stable ordering — and end a walk on a repeated page token as `bigquery_pagination_cycle`, which may
never be reported as completeness. Never replace a table ceiling with a column ceiling, a prompt-size
ceiling or a relevance allowlist.

**Refresh honesty.** Provider I/O never runs inside a Firestore transaction; simultaneous readers join
one in-process refresh; the finalizing transaction writes only while its `refresh_id` is still the
active generation, so a slow older refresh cannot overwrite a newer snapshot. Deletion is authorized
by evidence: a complete scan reconciles anything unseen, a partial scan deletes only inside a dataset
that finished listing itself, and a failed scan preserves the last successful catalog and is labelled
stale. A complete scan that genuinely finds nothing is a complete empty catalog. BigQuery descriptions
remain authoritative, Tartini-generated ones fill only provider blanks, and a refresh regenerates
nothing.

Source-catalog persistence does not turn source objects into Tartini-managed tables. They remain
`managed: false`, have no managed lifecycle id, expose no Delete/Refresh/Schedule/Duplicate action,
and refreshing their metadata logs no managed change. Within the Tartini AI Project, the Assistant reads
every catalog record and every nested field with no per-table allowlist, relevance gate or fixed
count. The single OpenCode turn may consume grounded context or retrieve catalog facts through real
gateway tools; there is no separate routing/planning/composer visibility split. Catalog access is not
execution authorization: every provider action rechecks current Google IAM, and any destructive
operation must resolve its real target, effect and container children before mutation. If resolution
is incomplete, do not execute or guess: return recoverable `execution_requires_normalization` (with
`boundary_target_unresolved` as an internal diagnostic) so the same agent turn can inspect, rewrite,
decompose or use a structured primitive.

## Rule 6d — For a managed BigQuery object, the provider owns its descriptions

**BigQuery is the authority for a managed object's table and column descriptions; the `tables` /
`table_columns` rows are a CACHE of it.** Every description change — creating an object, the
Assistant, `/enrich`, `/publish`, `objectService.update`, the table edit form — goes through the one
managed-metadata write in `app/tables.js`:

```text
writeManagedDescriptions()
→ bigquery.setObjectDescriptions()   one tables.patch
→ syncWarehouseTableMetadata()       read BACK what BigQuery now holds
→ mirrorManagedDescriptions()        the Firestore documents cache THAT, never the request
→ changelog / receipt                only after the provider confirmed
```

**Never write the Tartini AI mirror first.** A mirror write that runs ahead survives a provider failure and
leaves the interface showing a description the warehouse does not have. For the same reason a new
managed row starts with NO description even when the caller typed one: the sentence is carried to
BigQuery and arrives in the row by being read back.

**Two modes, because they are two intents** (`bigquery-contract.js` `DESCRIPTION_MODE`):

- `fill_missing` — AI generation. Writes only where the provider has nothing; a description somebody
  wrote is preserved exactly, and a documented field is never sent to the model at all.
- `replace_selected` — an explicit human edit. Replaces the fields it NAMES and only those, and may
  overwrite, because the user chose the words.

There is no third mode in the specialized managed-description primitive. The agent must not
approximate a requested mutation by silently changing modes; if a different provider-supported
metadata operation is genuinely required, it may use the general BigQuery gateway under its parsed
effect, IAM and receipt contracts.

Six invariants, none of them a name or dataset check:

1. **Ownership is structural.** `setObjectDescriptions` takes an object id and addresses the object by
   the reference its registry row recorded (`assertInsideOutput`, with the approval of a dataset other
   than the main one), so a customer SOURCE table is unreachable from it.
   Source-table descriptions stay in `bigquery_source_descriptions` and never travel to the provider.
2. **Only descriptions change.** The patch's schema is the one the provider returned to THAT call,
   with every name, type, mode and nested member unchanged; no partitioning, clustering or data key
   is in it. Never rebuild a provider schema from Tartini AI's simplified metadata projection, and never patch
   from a caller's snapshot — a schema that moved would be rebuilt stale.
3. **Address by full field path.** `event_params.value.string_value`, never a leaf name. A path the
   object does not have fails the WHOLE write (`bigquery_field_not_found`); a typo quietly skipped
   reads exactly like a successful edit.
4. **The object survives its documentation failing.** No rollback, no mirror write, no success claim:
   `descriptions_not_written` plus the real reason in the changelog, and a read-back failure reports
   `bigquery_read_back_unavailable` rather than mirroring the request text.
5. **A retry is one call.** The candidate set is recomputed from what the provider says now, so a
   second attempt writes only what the first did not.
6. **It is never a sweep.** Every entry point names ONE object; nothing backfills what already exists.

**No path may keep a persistence-only shortcut.** `/enrich` on a warehouse row runs `fill_missing`
(as a `table_description_request` background job, because it calls a model);
`/publish` sends a pending column edit as
`replace_selected` and leaves it pending if the provider refuses; a pending RENAME or DELETE on a
warehouse column is real and provider-backed (Rule 6f); `PATCH /api/tables/:id` refuses to rename a
managed OBJECT (its name IS the provider object id) and routes a description through the provider.

## Rule 6e — One tool per real write on an existing managed object

Changing an object that already exists is one TOOL per kind of write:
`refresh_managed_object`, `replace_managed_query` (a billed job each),
`set_managed_descriptions` (one `tables.patch`; the agent writes the words — without `replace: true`
they fill only the blanks), and
`rename_managed_column` / `delete_managed_column` (Rule 6f). They used to be ONE action
(`update_bigquery_object`) with an `operation` field, because a fixed six-name vocabulary could not
afford one entry per metadata operation; the registry has no such pressure.

**Never infer which write to perform from which fields happen to be set.**
`refresh: !proposal.sql` is what made a request to write descriptions run a billed
re-materialization and write nothing. A tool name cannot be misread that way.

**Managed columns reach `assistantFacts()` with `description` and `description_source`**, plus a
per-table tally and a stated `authority: 'bigquery'`. Without them the model cannot tell an
undocumented column from one documented only in Tartini AI's database, and will answer from the gap.

## Rule 6f — Schema evolution and datasets go through the provider, or not at all

**Renaming or removing a managed column changes the SELECT that produces the object.** A managed
object's columns ARE that query's output, so `rewriteManagedProjection()` reads the CURRENT schema
from `tables.get`, validates every named path against it, composes
`SELECT <kept, renamed where asked> FROM ( <stored SELECT> )`, and re-materializes through the
existing `objectService.update({ sql })` — a real billed job, read back and mirrored. Wrapping rather
than hand-editing the stored query is deliberate, and so is doing it at this level: an
`ALTER TABLE … DROP COLUMN` would be undone by the next refresh replaying the original query.

**Carry the descriptions across any re-materialization.** `WRITE_TRUNCATE` overwrites the schema and
a column description is part of it, so a refresh used to empty the object's data dictionary in
BigQuery while the mirror went on showing it. Read what the provider holds before the job and write
back what it no longer has afterwards, in `fill_missing` mode; a rewrite additionally says where each
field WENT, so a rename keeps its description and a removal takes its description with it.

**The specialized managed-projection tool refuses a field inside a RECORD by name**
(`warehouse_nested_field_change_unsupported`). Rewriting a struct expression safely needs a real SQL
parser. This is a limitation of that primitive, not a global Assistant hard boundary: a future
general provider statement may perform a deterministically parsed, IAM-authorized operation, but it
must read back and resync any touched managed object. Never write the Firestore document instead, which would
make the page disagree with the warehouse.

**A dataset's managed ownership is a durable record, never a name.** `managed_resources` says Tartini AI created
this dataset on this connection; that is what authorizes the specialized `drop_managed_dataset`, and
a customer dataset called `toastia_anything` is still theirs. That specialized drop is never a cascade — `deleteDataset` sends no
`deleteContents`, so BigQuery itself refuses a non-empty dataset — and before it runs,
`surveyManagedDataset` reads what is really inside: an unmanaged child refuses that specialized operation, a
listing that did not finish refuses it too (we cannot prove the dataset holds nothing of yours), and
managed children are removed one at a time through the ordinary provider-first delete. The deletion
is then read back.

The general BigQuery gateway is broader but not less safe: before any Dataset/Schema cascade it must
enumerate the real children and deny the entire statement before mutation if any child is a source
table resource. An incomplete/unresolvable enumeration cannot execute. A fully resolved cascade with
no source table is governed by the user's request, the deletion confirmation and Google IAM, not by
the managed-ownership registry.

**Dataset IAM is its own question.** `create_dataset` / `delete_dataset` are real actions with their
real Google permissions and least-privilege guidance — never `create_table` / `delete_table` under
another name. They carry no capability flag because there is no probe for them (probing would mean
creating and deleting a real dataset in the customer's project during setup), so the provider decides
at call time, exactly as `canReadRows` already does.

## Rule 6g — Managed-table work runs; only what cannot be undone waits

**No managed-table operation waits for the user to read its statement, and no count is a reason to
stop**. The user authorized the outcome; the server owns the scope, checks the
sources against the real catalog, validates and compiles the statement, dry-runs it where the tool
does, and Google enforces IAM and the customer's own BigQuery quotas (there is no byte cap of Tartini
AI's by default; an installation may configure `bigquery.maximumBytesBilled`).
A card holding a generated SELECT or MERGE
added no check those did not already make — and the failures that decide whether generated
incremental DML works appear only when it runs. The agent inspects, writes a readable statement,
runs it, and reports what really happened, showing the statement so the user can ask for a change.
On success the exact script in `TransferConfig.params.query` is returned byte-for-byte with the
physical and refresh contract; the Assistant shows it as the reference for what was actually built
or changed and must not claim success before that receipt.

The current tool behavior is:

| Tool | Before execution | After execution |
|---|---|---|
| `create_scheduled_managed_object` | deterministic plan/source/IAM/physical/cost validation; runs | exact provider script + created table/schedule/first-run contract |
| `update_scheduled_managed_table` | full-plan validation; additive schema classification; runs | exact patched provider script + changes; breaking removal/retype is refused |
| `create_managed_object` | reason checked against real scheduling capability; runs | provider receipt for the one-time table (`Refresh: None`) |
| `refresh_managed_object` / `replace_managed_query` | stored/new SELECT resolved; runs | rebuild receipt (a scheduled table runs ITS schedule) |
| `rename_managed_column` / `delete_managed_column` | top-level managed columns only; runs, however many | schema/rebuild receipt |
| `update_schedule` | cadence/pause/resume/name changes resolved; runs | patch to the same config |
| `set_managed_descriptions` | one schema patch, however many fields; the agent's own words fill only blanks unless `replace: true`; runs | description receipt |
| `create_schedule` | refuse a one-time/legacy table as `migration_required` | no provider mutation |
| `delete_schedule` / `delete_managed_object` / `drop_managed_dataset` | **deletion confirmation** — one card, the real count and every reference | destructive provider receipt |
| `start_scheduled_table_backfill` / `retry_scheduled_table_backfill` | **backfill confirmation** — run count, run times, coverage, cost | durable job receipt |

A create tool starts NO description generator: the table description the agent
gave is written as given, and the result names the columns still undocumented (`undocumented_columns`)
for the same agent to write with `set_managed_descriptions`. One model call per message.

**The billed-write retry fuse.** A scheduled create or update that fails comes back with BigQuery's
own message for the agent to correct in the same turn. FAILED billed attempts are counted per turn
and per table against `ai.assistant.maxManagedTableAttempts` (3): the last one is terminal, and once a
table's attempts are spent a further build of it is refused (`managed_table_attempts_exhausted`)
before anything runs. A success consumes nothing, and building several tables in one turn is
ordinary work.

**`effect.changes` carries what is different** (`refresh Daily → Weekly`, `remove column noise`, the
schedule a deletion takes with it) — "the schedule was updated" is not something anybody can check.

**Resolving an effect twice must mean the same thing.** A deletion or backfill card is released by
re-resolving the tool against state as it is THEN, from the arguments the tool itself normalized —
so a `resolveEffect` that reads only the shape a model produces will refuse, on release, the very
thing that was just approved. `update_schedule` and `update_scheduled_managed_table` both once did
exactly that (their fields land under `patch` / `plan`); both resolve either shape.

**Refuse the impossible at resolution.** A nested column path, a SQL statement over the size limit,
a connection that cannot schedule: each is checked in `resolveEffect`, before anything is billed.

## Rule 7 — The conversation is Tartini AI's

A Tables request is a turn of the project's one Tartini AI conversation (Conversation → Turns →
typed Items), which continues across Tracking, Tables, Dashboards and Measurement Plans; the
panel's **New conversation** starts another. There is no status column or Active/Completed/Draft workflow.
Conversation ids are verified against the project on every read and append. Titles/summaries are
derived from real messages with deterministic fallback, never canned examples. The old
`table_conversations` / `table_messages` rows are read-only history.

## Rule 7a — Conversation history is Tartini AI's

The Tables Conversations card and its search are deleted. A project's history is the main rail's
Recent conversations (a detail page's panel draws the same list in its "…" menu); an old Tables
transcript is listed there too, tagged Tables, and opens read-only (DESIGN §12.7k).

## Rule 8 — One OpenCode agent; Tartini AI is the boundary host

> **Implementation status: IMPLEMENTED.** The code contains no JSON next-tool planner loop and no
> second reply composer. They were replaced as one coherent change, and no compatibility planner was
> kept for old tests — the tests were rewritten around the real gateway instead.

One product turn has one intelligence layer:

```text
User
  → one Tartini AI turn             reasons, decomposes, calls tools, observes, answers
  → scoped Tartini AI MCP / Tables tools  project/turn scope, credentials, real services
  → deterministic hard boundary        source destructive effects + runtime isolation
  → BigQuery / Tartini AI / artifact host
  → server receipt
  → Agent final answer
```

`project-agent-runtime.js` hosts the turn and delegates it to the provider-neutral `AgentRuntime`;
the focused OpenCode adapter owns transport and runtime lifecycle. The Tables domain (`tables.js`
`assistantDomain`) builds the grounded facts its guide carries and the host-managed per-turn artifact
workspace (`table-agent-runtime.openTurnContext`), and turns the turn's Tables observations into
transcript items. The host collects tool activity, receipts, artifacts and usage, and coordinates
timeout/cancel. It must not implement
`planNextTool`, a JSON tool-call protocol, a `MAX_AGENT_STEPS` planner loop, a repeated-call planner
guard or a second model composer. A total turn time/cost/usage budget is still required; a host budget
is not a second agent.

### Preferred primitives are not user intents

Expose the current real Tables tool pack through the shared Tartini AI MCP registry/session. Generate the
concise `PREFERRED TARTINI AI PRODUCT PRIMITIVES` system reference from the registry's public schemas;
never maintain a second hardcoded tool-name list. Existing BigQuery tools are preferred
because they already preserve product ownership, metadata, descriptions, schedules and receipts.
They are not the finite set of outcomes a user may request.

No same-named tool means the agent decomposes the outcome and combines reasoning, catalog/schema reads,
queries, specialized mutations and workspace files. Unknown requests default to a serious attempt,
not `unsupported`. If one independent subtask lacks an integration, complete the others and report
only that delivery as `capability_unavailable`.

Keep `query_bigquery` as the clear bounded read-only primitive. It binds named parameters (`params`,
each typed STRING, INT64, FLOAT64 or BOOL), and with `dryRun: true` it CHECKS the exact statement instead
of running it — BigQuery's acceptance and the bytes it would read, no rows, nothing billed
(`data.dryRun`). It hands back a page (25 rows) with
the job's id and `nextOffset`; `read_query_results({ jobId, offset, limit })` reads the rest of that
SAME finished result from BigQuery by row offset (`bigquery-jobs.readResults`) — nothing runs or bills
again, and only a read job of this project is readable. Add a separate general
`execute_bigquery_sql` primitive for a provider-supported BigQuery operation that no specialized tool
covers. Specialized product mutation remains preferred. The generic primitive accepts one concrete,
boundary-verifiable GoogleSQL statement and a reason; explicit fully qualified targets or structured
tools are preferred over dynamic SQL, opaque procedures and complex scripts. Resolve the real
statement type/targets/effects/affected containers using reliable structured and provider metadata,
not regex guessing or a home-grown full ZetaSQL parser. Execute as the project's own managed service
account, wait for terminal provider state and return a real job/affected-row/target receipt. If it
touches a Tartini-managed object, read it back and resync local schema/descriptions/changelog. Never
infer success from SQL text.

### Exactly three product hard boundaries

1. **Never destructively delete/remove/replace existing rows, columns or the resource of a source
   Google BigQuery table.** This includes `DROP TABLE`, `DELETE FROM`, `TRUNCATE`, `MERGE ... DELETE`,
   `ALTER TABLE ... DROP COLUMN`, destructive `CREATE OR REPLACE`, provider `deleteTable`, Dataset/
   Schema cascade or an equivalent path. Server code resolves actual provider references and effects
   and, for a container cascade, enumerates all children before any mutation. Any destructive source
   effect denies the whole operation. `UPDATE`, `INSERT`, `ADD COLUMN`, `SET OPTIONS` and other
   non-destructive source changes are not broadly denied just because the table is a source; gateway
   capability, Google IAM and the provider decide whether they can run.
2. **The product Table Assistant runtime cannot modify Tartini AI itself.** It cannot read/write the
   application repository, registry, policy/boundary implementation, agent capabilities, system
   prompt source, OAuth/Vault/credential handling or security/tool-gateway code. This is enforced by
   process/filesystem/tool isolation, not prompt prose. A normal developer OpenCode session remains
   able to edit the repository; the product runtime is a different capability profile.
3. **Access is READ through Tartini AI and CHANGED in Google.** Reading permissions is fully supported:
   `INFORMATION_SCHEMA.OBJECT_PRIVILEGES`, `INFORMATION_SCHEMA.ROW_ACCESS_POLICIES` and the
   connection's capability report are ordinary reads, and answering "who can edit this dataset?" or
   "why was that denied?" is one of the more useful things this Assistant does. Writing them is
   refused: `GRANT`, `REVOKE` and row access policies throw `access_control_belongs_to_google`
   from statement resolution, before any classification, job or provider call. Tartini AI runs as ONE
   Google identity with whatever access that identity was given — an application able to widen its
   own access has no boundary at all — and IAM is in any case the customer's own control over their
   own data, belonging in their console, their audit log and their security review rather than in a
   chat turn. The refusal is not the end of the answer: it carries the exact statements or roles and
   a Google Cloud Console link for the project that owns the resource, and so does a
   `permission_required` denial. It is `boundary_denied`, **never**
   `execution_requires_normalization` — normalization means "write a concrete form", which for a
   `GRANT` reads as "try harder", and the form was never the problem.

Do not preserve broad policy denials for every source mutation, unmanaged mutation or IAM-shaped
request. Tartini AI hard-boundary denial, Google `permission_required`, absent external capability,
clarification and provider/tool failure are distinct outcomes. An unresolved destructive execution
form is not terminal capability truth: return recoverable `execution_requires_normalization`, keep
`boundary_target_unresolved` only as internal detail, and let the agent inspect, rewrite, decompose or
choose a structured primitive. After bounded recovery attempts it may truthfully say the current
execution form cannot be verified, but not that the user outcome is unsupported. Confirmation of an
irreversible effect is durable server state with compare-and-swap claim and re-resolution; it is a
safeguard, not proof that an unknown request is unsupported.

### Runtime and secret isolation

The OpenCode agent session gets a strict, turn-scoped gateway configuration and no ambient MCP,
plugins, connectors or skills. It never receives access/refresh tokens, service-account JSON, Vault
material, database secrets or provider SDK credentials; only the server-side gateway can call
BigQuery. The current `TABLE_ASSISTANT` profile explicitly denies shell, built-in filesystem,
external directories, arbitrary web and subagents, and allows only the scoped Tartini AI MCP. It may
become or reference the shared immutable `MCP_ASSISTANT` security definition; Tables identity and
policy remain in its turn prompt/tool pack, not in a copied permission map.

Use the official local MCP transport supported by the pinned OpenCode version; never expose it
publicly or inherit the host's MCP configuration. The gateway token is opaque, short-lived and bound
to one turn and Project. Tool schemas do not let
the agent claim `managed`, `source`, `safe`, `bounded` or a policy outcome; the server derives resource
identity and effects from canonical catalog/provider state.

### General workspace and artifacts

Do not add a second Artifact Agent or one business tool per file type. The agent writes a file for the
person with its OWN write tool, under `.tartini-files/` in its working directory (the
four `workspace_*` tools and the scratch directory behind them are gone), and `publish_artifact` takes
it from there: only a regular file under that directory, within the size bound, read from the sandbox
as a tar in memory — an absolute path, `..`, a link or anything outside it is refused by name. That
directory is never part of the code: opening the code workspace keeps it, the agent's code changes never
include it, and a repository path under it is not materialized. Arbitrary UTF-8 text formats may be
produced; an unknown extension is downloadable as `text/plain` rather than refused.

Writing that file needs no shell. `write` creates `.tartini-files/` and any folder under it, and the
files there are listed with `list` or `glob`; the turn's shell runs only read-only git and the
project's own scripts, so `ls`, `mkdir`, `cat >` or a conversion command is refused, and the refusal
costs a step (a CSV export once tried a shell command first).

Publishing validates and persists project/conversation ownership. Embedded HTML/SVG is sanitized,
uses a restrictive CSP/sandbox, loads no external resources, and never receives same-origin Tartini AI
privilege. Downloadable source may include HTML/JS, but is not executed as trusted application code.
The agent may claim an artifact only after the host returns a real published receipt/URL.

### Grounding, truth and partial completion

The turn retains `assistantFacts()` grounding: Project identity, connection/Output Dataset, managed
objects, full source catalog/schemas/descriptions, conversation history and provider/permission state.
Facts are evidence, not a capability allowlist. The complete catalog remains reachable through context
or real gateway reads with no fixed table/column/relevance visibility ceiling.

The server remains source of truth for every mutation receipt and artifact card. The agent writes the
final response directly from tool observations; do not run a second model that can contradict it. If
text and a structured receipt disagree, the receipt wins and the UI may append a canonical status
card. Never fabricate customer data, hide truncation, describe a bounded sample as a full export, or
claim a pending/failed provider operation succeeded.

Missing BigQuery capability blocks only dependent provider work and does not prevent independent
reasoning or artifact creation. BigQuery operations use current IAM. Specialized managed-object
writes remain Output-Dataset-bound; the general gateway may
attempt other resolved provider operations except destructive deletion/removal/replacement of
existing source rows, columns or table resources.

## Rule 9 — Data model and real previews

Firestore collections retain `tables`, `table_columns`, `table_events`, `schema_changes`,
`project_meta`, `table_conversations` and `table_messages` with their existing logical fields. The
agent may retain `table_agent_pending_actions` for structured
confirmation of an irreversible effect (tool, normalized args, resolved effect, status, expiry) and uses
`managed_resources` for the DATASET
ownership registry — Tartini AI created this dataset, on this connection). Both are keyed by
`project_id`, so the central manifest-driven Project-Delete sweep purges them without a new special case, and
neither holds a credential, a customer row or SQL text. BigQuery adds secret-free `bigquery_jobs` and
`bigquery_native_schedules`: provider job/result metadata, and the ownership of a Google BigQuery
Scheduled Query (its Data Transfer config name, the managed table it maintains, the requested
cadence/timezone and the compiled provider schedule) — never OAuth tokens. Cadence, next run and run
history belong to Google and are read from the provider; Tartini AI runs no schedule of its own. The Project source catalog
stores provider metadata/schema and is keyed for manifest-driven Project cleanup. Any query-result cache
or materialization uses its own explicit storage/lifecycle contract rather than being hidden in job,
schedule or source-catalog rows.

The single-agent implementation also persists server-owned turn/tool receipts, usage and published
artifact metadata with Project/conversation ownership and expiry/cleanup fields. Published artifact
bytes live in the private GCS object store; unpublished workspace files are ephemeral only. Never
store bytes in a prompt or tool-state document. Do not persist gateway
tokens or provider credentials. A crashed/expired turn closes its gateway and cleans un-published
workspace state without deleting already published artifacts.

For a source-ready raw table, `GET /api/tables/:id/preview?limit=&offset=` serves real newest-first
rows with server limit ≤50; export uses the same sample. Metric tables without an execution engine
show no row/size result rather than a fabricated zero-query result.

Dashboard widgets bind a BigQuery source or query under same-Project ownership and current IAM.
Missing/wrong-Project sources never fall back to another table. Plan execution and displayed Source
SQL share one compiler; query provenance is the exact statement executed. Manual and Dashboard-Assistant
edits use one draft/query service. Full contract:
[`../dashboards/dashboard-data-binding-and-provenance.md`](../dashboards/dashboard-data-binding-and-provenance.md).

## Rule 9a — No second scheduler or hidden data mart

Do not add a second SQL engine, Tartini-owned cron, Dashboard polling, WebSocket, invented real-time
push or hidden materialization. BigQuery native Scheduled Queries remain provider-owned and follow
the scheduled-table/backfill contract.

## Rule 9b — Saved Query is metadata; Query Workspace reuses the one read-query path

Follow [`query-workspace-design.md`](query-workspace-design.md). A Saved Query is a Project-scoped,
durable name + SQL definition with server-owned `toastia | user` provenance. Saving is not executing,
opening is not executing, running is not saving, and there is no autosave or auto-run. SQL drafts may
be persisted before they parse; the existing read-only classifier, dry run, cost policy and job
service decide whether an explicit Run may execute.

Do not build another BigQuery client, SQL classifier, permission matrix, job history or result store.
`app/queries.js` owns metadata CRUD and project scoping; execution re-resolves the Tables data source
and delegates to `bigquery.runReadQuery`. `bigquery_jobs.query_id` is only an optional validated link,
and deleting a query clears that link without deleting job history. Preserve provider `totalRows`
separately from bounded loaded rows, and never persist result rows.

The Assistant's exploratory `query_bigquery` result remains `data.query` and never becomes durable by
accident. Only an explicit internal `save_query` result (`data.savedQuery`) may create a Saved Query
and a durable `QUERY` conversation item. The server supplies Project and provenance and validates an
optional job link; the model/browser supplies neither authority. Save final reusable analytical SQL,
not probes, debug/intermediate statements, scheduled-table scripts or backfill internals.

Query Workspace is BigQuery-only and read-only at execution time. This is a surface boundary, not a
new restriction on the Table Assistant: supported BigQuery mutations continue through specialized
tools or the existing resolved general-execution gateway. A Project without BigQuery returns its
current connection/capability guidance; it does not switch workspaces or engines.

## Rule 10 — Adding or changing a table capability

Backend stays in `app/tables.js` via `mountTables({ app, repository, deps })`; frontend remains plain
HTML/CSS/JS in `tables.html` and `table.html`. Add a row source through the one source authority and
adapter, not per-route conditionals. Add a table type in backend plus detail schema/preview rendering.

Use generic offline fixtures and injected Google OAuth/BigQuery clients with a fixed clock. Never
connect a real Google account, query live BigQuery, or special-case a project/repository/event in
automated tests. Cover state/PKCE/TTL, discovery pagination, verified identity, output selection,
query/create/delete probes, cleanup failure, confirmation and rollback, explicit rejection of
file/path source fallback, no boot-created placeholder table, stable-id Dashboard binding, and
BigQuery SQL/object/schedule actions including read-only vs write-only capability splits, each permission
guide, Reverify, dry-run, output-boundary rejection, job failure, idempotency and disconnect blocking.
For source-catalog grounding, additionally cover shared UI/Assistant catalog access, persistence and
refresh of real metadata, every discovered reference, complete nested schema and column descriptions,
BigQuery-over-Tartini description precedence, partial-refresh honesty, absence of fixed table/column/
context visibility caps, no managed lifecycle leakage and SQL/create planning over real schemas.

For the single-agent implementation, use observable offline tests instead of old custom-planner shape tests:
one OpenCode agent turn can make multiple gateway calls and return its own final answer; the tool
reference changes with the real registry; unknown analysis/artifact requests do not need same-named
tools; partial completion survives a missing integration; host MCP and secrets are absent; repository
write, absolute/parent paths and symlink escapes fail; artifact ownership and HTML/SVG isolation hold;
source `DROP TABLE`, `DELETE FROM`, `TRUNCATE`, `MERGE ... DELETE`, `DROP COLUMN`, destructive
replacement, provider delete and Dataset/Schema cascade deny before mutation; source `UPDATE`,
`INSERT`, additive schema and metadata changes are not caught by a broad source deny; generic
non-source writes reach provider IAM; unresolved destructive plans fail closed and return recoverable
`execution_requires_normalization` so the agent can rewrite/decompose; touched managed objects resync;
and provider permission/
job failure yields truthful non-boundary receipts. Tests inject the OpenCode runtime, gateway, parser/
resolver and provider—never call live OpenCode/OpenRouter or Google.

