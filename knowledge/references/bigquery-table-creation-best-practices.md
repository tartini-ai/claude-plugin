# BigQuery scheduled-table creation and update best practices

This is the normative physical-table contract for Tartini-managed BigQuery tables created or
maintained by a BigQuery Native Scheduled Query. The customer-side IAM runbook is
[`bigquery-permissions.md`](bigquery-permissions.md); the broader product boundaries remain canonical
in [`tables-product-design.md`](tables-product-design.md) and
[`tables-best-practices.md`](tables-best-practices.md).

> **Runtime migration note:** This deterministic BigQuery contract is runtime-independent and
> remains authoritative after OpenCode + OpenRouter replaces the agent runtime. The model cannot
> bypass its typed plan, validation, the deletion/backfill confirmations, provider execution or receipts.

Last verified against the linked Google documentation: **2026-08-11**.

> **Status: IMPLEMENTED.** `app/bigquery-managed-table-plan.js` validates the typed plan,
> `app/bigquery-incremental-sql.js` compiles the executable script, `app/bigquery.js`
> `createScheduledObject` runs the creation saga and its compensation, and
> `app/bigquery-native-schedules.js` creates a DML-only transfer config. The contract is proved
> offline in `app/test/bigquery-scheduled-table-contract.test.js` against a fake provider and a fixed
> clock; no live Google call has ever been made. **Existing scheduled tables are not migrated** —
> every path that would have attached the old SELECT + `WRITE_TRUNCATE` shape to a table created
> before this now returns `bigquery_scheduled_table_migration_required` and changes nothing.
>
> **Historical backfill (§14) is IMPLEMENTED.** `app/bigquery-backfill-plan.js` normalizes an
> inclusive `ds` range into exact historical logical run times and derives the backfill-ready verdict;
> `app/bigquery-backfill-store.js` holds the durable job and one row per provider run;
> `app/bigquery-backfill-execution.js` drives them one at a time over the SAME production
> TransferConfig, with a lease, crash recovery, stop-on-failure, retry and cancellation;
> `app/table-agent-tools.js` exposes the five agent primitives and the confirmation. Proved offline in
> `app/test/bigquery-backfill-plan.test.js`, `app/test/bigquery-backfill-execution.test.js` and
> `app/test/table-agent-backfill.test.js` against a fake provider and a fixed clock; no live Google
> call has ever been made.
>
> **Known boundaries of the current implementation.** A managed table's declared output schema is FLAT
> — a nested (`RECORD`/`REPEATED`) output column is refused rather than created from a shape nobody
> declared — and an update may add columns but not remove or retype one (§13). **A historical run
> Google has already accepted cannot be cancelled:** the Data Transfer Service exposes no cancel for a
> transfer run, so cancellation stops Tartini AI starting further runs and the accepted one is watched to
> its real end and reported honestly (§14.6). **`requestedTimeRange` is not used at all** — the
> sequential `requestedRunTime` path is the only execution strategy this release implements (§14.3).
> **The cost estimate is sampled** for a range longer than `bigquery.backfillEstimateRuns`: the runs
> that were not priced are listed as unpriced by name and the total says it was extrapolated.

## 1. Scope and precedence

This contract applies to new or updated **physical BigQuery tables** that Tartini AI owns and refreshes
through BigQuery Data Transfer Service (`dataSourceId: "scheduled_query"`), including business models
named with these prefixes:

```text
fct_*
agg_*
dim_*
snapshot_*
stg_*
```

It does not apply to:

- BigQuery source tables owned by the customer;
- logical BigQuery views, which store no rows and have no refresh schedule;
- one-time query results the user explicitly asked to keep unscheduled; or
- existing scheduled tables until they pass an explicit compatibility review and migration.

The name prefix expresses the table's business role. Tartini AI's internal object kind (`logging`,
`metric`, `derived`, `intermediate`, or `materialized`) expresses product behavior. They are
orthogonal: never infer permissions, ownership or the loading algorithm from a prefix alone.

When the user explicitly asks for a different cadence, run time, incremental window or loading
strategy, the OpenCode agent may customize it through the same validated typed plan and must state
the effective difference in the successful result. A later change to an existing standalone schedule
uses that tool's own validated contract (`update_schedule`). Unless the user explicitly overrides it, the following contract is mandatory.

## 2. Default physical contract

| Dimension | Required default |
|---|---|
| Execution owner | Google BigQuery Native Scheduled Query; no Tartini AI cron, timer or worker |
| Cadence | Daily |
| Requested run time | 02:00 UTC |
| Logical time | UTC — `DATE(@run_time, 'UTC')`, always, for every table |
| Partition column | `ds` |
| Partition field mode | top-level `DATE`, `REQUIRED` / `NOT NULL` |
| Physical partitioning | daily time-unit partitioning on `ds` |
| Partition meaning | the row's own event or effective date |
| Incremental window | T-3 through T-1, inclusive |
| Reconciliation | idempotent `MERGE` or atomic bounded-partition replacement |
| Table expiration | none |
| Partition expiration | none |
| First materialization | manual run of the same Scheduled Query that owns later refreshes |
| Source and target scans | both bounded to the incremental window |
| Backfill | required for every covered table; same TransferConfig and SQL, historical logical run times |

There is no separate default loading algorithm for `fct_*`, `agg_*`, `dim_*`, `snapshot_*`, or
`stg_*`. The prefix changes semantic role, not the baseline physical lifecycle.

## 3. `ds` is mandatory and means the row's own date

Every covered table has this schema field:

```sql
ds DATE NOT NULL
```

and is physically partitioned by that field:

```sql
PARTITION BY ds
```

`ds` is a BigQuery `DATE`; `YYYY-MM-DD` is only its display representation. Do not store it as
`STRING`, use ingestion-time partitioning as a substitute, or pick another physical partition field.

Derive `ds` from the event/effective date the row is about, not from load time:

```sql
order_date AS ds
payment_date AS ds
DATE(order_timestamp) AS ds
PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS ds   -- a GA4 export (§7)
```

Do not default `ds` to `CURRENT_DATE()`, `ingestion_date`, or `load_date` unless that value is the
actual date the user asked for.

**Two calendars: `ds` is on the same one as the window filter.** The RUN calendar — the logical run
date, the window and the schedule — is UTC for every table (§5, §8); Tartini AI names no other
timezone and a per-table reporting calendar is not part of the contract. `ds` is the date the source
itself carries, read the way the window filter reads the source:

| Source | Window filter | `ds` |
|---|---|---|
| GA4 `events_*` (date-sharded) | `_TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', load_start) AND …` | `PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)` |
| A `DATE` column | `order_date BETWEEN load_start AND load_end` | `order_date` |
| Only a timestamp | `DATE(created_at) BETWEEN load_start AND load_end` | `DATE(created_at)`, no zone argument |

A GA4 shard date is the property's reporting day: the same day as `event_date` and GA4's reports.
Never derive a GA4 `ds` from `event_timestamp`. That UTC date moves the edge hours of every day onto
the neighbouring date, outside the window: a partition replacement loses them for good, and every
day's numbers disagree with GA4.

At plan time, Tartini AI must record and show:

```text
ds source expression and semantics
table grain
stable reconciliation key or partition-replacement proof
```

## 4. Semantic table types and naming

Names are lower `snake_case`, begin with the appropriate semantic prefix, and remain bare object ids;
the server constructs the fully qualified destination from the connection's Output Dataset.

| Prefix | Business role | Typical examples | Required design question |
|---|---|---|---|
| `fct_` | Facts at an explicit analytical grain | `fct_events`, `fct_orders`, `fct_payments` | What does one row represent? |
| `agg_` | Reusable pre-aggregated metrics | `agg_daily_revenue`, `agg_campaign_performance` | Which dimensions and measures define one row? |
| `dim_` | Descriptive attributes used in joins, filters and labels | `dim_users`, `dim_products` | Is this descriptive state rather than a measured event? |
| `snapshot_` | Entity state as of each `ds` | `snapshot_subscription_status` | What is the entity and what does “as of `ds`” mean? |
| `stg_` | Intermediate cleaning, deduplication or schema alignment | `stg_ga4_events` | Which downstream model consumes it? |

`fct_users` is appropriate only when each row contains measurable user-level facts or activity. A
table made mainly of country, plan, industry or acquisition attributes should normally be
`dim_users`.

A `stg_*` table is intermediate in pipeline role, not disposable infrastructure. If Tartini AI manages
it under this contract, it still receives `ds`, partitioning, incremental reconciliation and no
expiration. The name is never evidence that a table may be deleted.

## 5. The default incremental window

For a logical run date T, every standard run reconciles exactly:

```text
T-3
T-2
T-1
```

Use provider logical time so normal runs, retries and backfills are deterministic. `@run_time` is the
authority, and it is read as **UTC — always, for every table**:

```sql
DECLARE logical_run_date DATE
DEFAULT DATE(@run_time, 'UTC');

DECLARE load_start DATE
DEFAULT DATE_SUB(logical_run_date, INTERVAL 3 DAY);

DECLARE load_end DATE
DEFAULT DATE_SUB(logical_run_date, INTERVAL 1 DAY);
```

The timezone argument is a constant, not a plan input: a managed table's window may not be derived on
one calendar while its neighbour's is derived on another. `@run_date` is equivalent and may be used.
Do not use `CURRENT_DATE()` or `CURRENT_TIMESTAMP()` for the window: a delayed run or historical
backfill would then process the wrong dates.

A `ds` on a different calendar from the filter that bounds the source is not "off by a day and
reconciled on the next run": its edge rows fall outside every later window (§3, §6.1).

The T-3 through T-1 window self-heals common late-arriving and late-updating data while leaving older
history unchanged. It is a default, not a claim that every source has the same lateness. An explicit
user request or proven source SLA may select another window, which must be stored and shown.

## 6. Approved idempotent reconciliation strategies

Every run must be safe to execute once, twice, after a retry, or as a historical backfill. A naked
`INSERT INTO ... SELECT ...` is not allowed when replaying a window can duplicate rows.

### 6.0 The physical target exists before any `MERGE`

`MERGE` mutates a target table; it does not define that table's schema, nullability, partitioning or
expiration contract. The first `MERGE` must therefore be preceded by a successful, one-time physical
create and a provider read-back. The invariant is:

```text
validate + authorize
→ CREATE TABLE with the explicit schema and PARTITION BY ds
→ read back and verify the physical contract
→ create the Scheduled Query whose SQL is MERGE / bounded replacement
→ startManualRuns
→ the first DML run
```

The equivalent SQL ordering is:

```sql
CREATE TABLE `<OUTPUT_PROJECT>.<OUTPUT_DATASET>.fct_example` (
  ds DATE NOT NULL,
  stable_id STRING,
  amount NUMERIC
)
PARTITION BY ds;

-- Only after the CREATE succeeds and its metadata is verified:
MERGE `<OUTPUT_PROJECT>.<OUTPUT_DATASET>.fct_example` AS T
USING (...) AS S
ON T.ds = S.ds
AND T.stable_id IS NOT DISTINCT FROM S.stable_id
AND T.ds BETWEEN load_start AND load_end
WHEN MATCHED THEN
  UPDATE SET amount = S.amount
WHEN NOT MATCHED THEN
  INSERT (ds, stable_id, amount)
  VALUES (S.ds, S.stable_id, S.amount);
```

Tartini AI's provider implementation may use BigQuery `tables.insert` instead of sending literal DDL;
that API call is the physical `CREATE TABLE` operation and must carry the same explicit schema and
partitioning. It must complete before the TransferConfig is created or any manual run can execute.
The recurring scheduled script must ALSO open with `CREATE TABLE IF NOT EXISTS`, declaring the same
schema, `PARTITION BY ds` and derived clustering. This idempotent DDL is the self-healing path when
somebody drops the destination: the next scheduled run recreates it and continues through the same
production DML. It does not prove an existing table is correct and never replaces the initial explicit
create/read-back. Creation, definition updates and backfill preflight must still read provider truth
and reject or migrate incompatible schema, partitioning, expiration, ownership or plan/config drift.

If the create fails, no schedule is created. If the read-back does not prove required `ds`, daily
partitioning and no expiration, no `MERGE` is allowed to run. The successful result shows the verified
create contract, execution order and exact provider script — evidence of what ran, beside the script
that was approved.

### 6.1 Keyed `MERGE`

Use `MERGE` when the table has a real stable logical key. The source query and merge condition must
both include the bounded `ds` window so BigQuery can prune source and target partitions.

The compiler also wraps the projection in `SELECT * FROM (…) WHERE ds BETWEEN load_start AND
load_end`, so a row dated outside the window (§3) is dropped rather than inserted again on every run.
A schedule compiled by an earlier version of the compiler runs the earlier unbounded script; a backfill
accepts exactly that script as the same loader (§14.1).

```sql
MERGE `<OUTPUT_PROJECT>.<OUTPUT_DATASET>.fct_example` AS T
USING (
  SELECT
    business_date AS ds,
    stable_id,
    amount
  FROM `<SOURCE_PROJECT>.<SOURCE_DATASET>.source_table`
  WHERE business_date BETWEEN load_start AND load_end
) AS S
ON T.ds = S.ds
AND T.stable_id IS NOT DISTINCT FROM S.stable_id
AND T.ds BETWEEN load_start AND load_end
WHEN MATCHED THEN
  UPDATE SET amount = S.amount
WHEN NOT MATCHED THEN
  INSERT (ds, stable_id, amount)
  VALUES (S.ds, S.stable_id, S.amount);
```

The key is part of the table contract. Tartini AI must not invent a key merely to produce valid SQL.
If the catalog and user context cannot establish one, use bounded partition replacement only when
its completeness condition is provable; otherwise request clarification.

**Key comparison is NULL-safe, and `ds` comparison is not.** `NULL = NULL` is `UNKNOWN`, so a key
column that is ever `NULL` — an optional `stream_id`, an unset dimension — never matches the row it
identifies. The `MERGE` reads it as `NOT MATCHED` and inserts, so every run appends another copy of
the same row and the table looks like it is working. Compare every key column with
`IS NOT DISTINCT FROM`, which is GoogleSQL's own NULL-safe equality and is type-agnostic: no
`COALESCE` sentinel, no per-type special case. `ds` keeps plain `=` because it is `REQUIRED` and
because it is the column BigQuery prunes partitions on.

### 6.2 Atomic bounded-partition replacement

For aggregates, dimensions or snapshots whose source query returns the complete truth for every
date in the window, Tartini AI may replace those partitions atomically:

```sql
BEGIN TRANSACTION;

DELETE FROM `<OUTPUT_PROJECT>.<OUTPUT_DATASET>.agg_example`
WHERE ds BETWEEN load_start AND load_end;

INSERT INTO `<OUTPUT_PROJECT>.<OUTPUT_DATASET>.agg_example` (ds, dimension_key, metric_value)
SELECT ds, dimension_key, metric_value
FROM bounded_source
WHERE ds BETWEEN load_start AND load_end;

COMMIT TRANSACTION;
```

This strategy is valid only when the source is complete for the whole replacement window. If it is
an append-only delta feed, deleting a partition would lose previously loaded rows and is forbidden.

Both strategies mutate only the Tartini-owned destination inside the Output Dataset (or inside the
dataset the person named for it, where it was created new). They never delete, replace or update rows
in a source table.

## 7. GA4 self-healing pattern

GA4 daily export queries use a wildcard plus `_TABLE_SUFFIX`; never hard-code physical daily table
names such as `events_20260810`.

```sql
FROM `<GA4_PROJECT>.<GA4_DATASET>.events_*`
WHERE _TABLE_SUFFIX BETWEEN
  FORMAT_DATE('%Y%m%d', load_start)
  AND FORMAT_DATE('%Y%m%d', load_end)
  -- Production only: the project's website host(s), named before the table is planned.
  AND device.web_info.hostname IN ('<PRODUCTION_HOST>')
```

The hostname filter is part of the definition, so every scheduled run and every backfill applies it.
Which hosts are production, and when every host may be counted instead, is decided by Analytics
business semantics ("Production metrics exclude Preview and test traffic by default"). A table that
counts every host says so in its description.

Materialize the partition key from the suffix the filter bounds — the property's reporting day (§3):

```sql
PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS ds
```

Not a raw `PARSE_DATE` over `event_date` (refused, §10a), and never a date from `event_timestamp`.
The date-shaped bounds also keep `events_intraday_*` shards out.

Then reconcile with a stable key appropriate to the declared grain and also restrict the target to
`T-3` through `T-1`. A missing daily shard is not an error if the wildcard still resolves at least
one allowed source object; a later run naturally picks up a late shard while idempotency protects
rows already loaded.

The commonly shown tuple of `user_pseudo_id`, event timestamp and event name is only an example. It
is not universally unique. The plan must prove or obtain the actual logical key.

## 8. Schedule semantics

The default requested schedule is:

```text
cadence: daily
time: 02:00 UTC
```

The schedule must therefore be represented as a clock cadence such as `daily:02:00`, not the
interval-only `daily` value that compiles to `every 24 hours` from creation time — Google anchors an
interval to whenever the config happened to be created, so two identical tables would refresh at
different hours and neither at one anybody chose.

The Data Transfer Service has no timezone field and reads schedule times as UTC, so a UTC schedule is
the provider's own native form: `daily:02:00` compiles to `every day 02:00` with no conversion, and
there is no daylight-saving disclosure to make because UTC has none. Do not offer a per-table
schedule timezone.

Google also warns that an exactly-on-the-hour schedule can be triggered more than once. The product
default remains 02:00 under this contract, so idempotency is mandatory rather than optional. A future
decision to move the default off-hour must change this document, the UI copy, cadence defaults and
tests together.

If upstream data is not normally ready by 02:00, honor an explicit later time. Schedule changes patch
the same owned TransferConfig; they never create a second producer. Google remains the only scheduler
— this design adds no Tartini AI cron, timer, queue or worker.

## 9. Physical creation workflow

`create_scheduled_managed_object` must execute the following saga. No model response may bypass or
duplicate it.

**IT RUNS WHEN ASKED, AND THE SCRIPT COMES BACK TO SHOW.** Creating a table
destroys nothing and touches nothing that exists, and the failures that decide whether it works — a
type that will not assign, a source row that matches twice, a value that will not parse — appear only
when it runs, so holding a hundred lines of generated DML for a card put a decision in front of
somebody that they could not make about a statement that might not have worked. For a while it was
held anyway, on the argument that a failed, fully compensated create left no record of the submitted
script; that card also stopped every multi-step request halfway, and it is gone.

So every deterministic refusal happens in resolution, before anything is billed — the typed plan,
the known-source check, the compiled script's size, the bounded dry-run price — and then the saga
runs. On success the compiled script comes back on the result (`data.scheduled_query.sql`) as the
thing the user reads and can ask to change. On failure the saga compensates completely and BigQuery's
own message comes back through the correction channel, so the agent fixes the plan and calls again in
the same turn. Each attempt is a billed run, so FAILED attempts at one table are bounded per turn by
`ai.assistant.maxManagedTableAttempts` (3): the last is terminal, and a further build of that table is
refused before anything runs.

DESTRUCTION stops for its own reason — deleting a table, a dataset or a schedule — because "can this
be undone" is a question with a permanent answer. So does a backfill, because N billed runs is a
number a person should see (§14.5).

1. **Build one typed plan.** Resolve semantic prefix, grain, explicit output schema, `ds` expression
   and meaning, reconciliation strategy/key, source references, window and schedule.
2. **Authorize current capability.** Recheck source reads, Query Job, Output Dataset table writes and
   Scheduled Query capability. A connected service account alone is insufficient.
3. **Validate sources and effects.** Resolve every reference against the complete source catalog,
   reject unresolved destructive source effects, and construct the destination only from the
   connection's Output Dataset.
4. **Validate the projection.** Require explicit columns and types; reject `SELECT *`; verify exactly
   one top-level `ds` of type `DATE` with no possible `NULL`; dry-run/estimate the bounded source
   projection before any provider mutation.
5. **Validate reconciliation.** Prove the stable key or the completeness requirement for bounded
   partition replacement. Ensure both source and target predicates include the window.
6. **Resolve the effect.** Build the destination, grain, key, `ds` semantics, T-3 through T-1 window,
   schedule, partitioning, expiration policy and estimated bytes as one structure, so the receipt and
   the reply describe the same table.
7. **Recheck current state.** IAM, the source catalog and a destination collision are checked against
   state as it is NOW, immediately before the first mutation.
8. **CREATE the empty physical table before any `MERGE`.** Issue the explicit `CREATE TABLE`
   operation (currently BigQuery `tables.insert`) with the declared schema, top-level required `ds`,
   daily time partitioning on `ds`, and no table or partition expiration. Read it back and prove the
   contract before continuing. Creating an empty shell writes no customer rows and does not create a
   second data producer.
9. **Create the Native Scheduled Query.** Its query is the server-generated DML. For a DDL or DML
   scheduled query, send **NO DESTINATION OF ANY KIND**: not `params.destination_table_name_template`,
   not `params.write_disposition`, not `params.partitioning_field`, and **not the top-level
   `destination_dataset_id`** either. The DML names and controls the already validated destination.
   The dataset is the one that is easy to miss, because it is not one of the three `params` and
   because the Data Transfer Service ACCEPTS the config that carries it — and then fails its FIRST
   RUN, parsing the query for the destination it was promised and finding none:
   `Dataset specified in the query ('') is not consistent with Destination dataset '<yours>'`.
   Do not substitute `default_dataset_id`: the compiler qualifies every identifier as
   `project.dataset.table`, so a default could only ever silently resolve a reference that should
   have been qualified. The capability probe (`probeScheduleLifecycle`) keeps its destination
   deliberately — it really is a `SELECT` with one, which is what that field is for. The script
   opens with `CREATE TABLE IF NOT EXISTS` for its own destination — the same schema, partitioning
   and clustering step 8 created — so a table somebody drops six months from now is rebuilt by the
   next run instead of failing every night. That is SELF-HEALING, not verification: step 8 still
   creates the table first, because a `CREATE ... IF NOT EXISTS` buried in a script Google runs at
   02:00 can verify nothing.
10. **Persist ownership immediately.** Record the provider config name and table mapping before any
    manual run so a crash cannot orphan an editable schedule.
11. **Run the schedule now.** The first rows come from `transferConfigs.startManualRuns` on this same
    config. Never perform an unrelated one-time materialization.
12. **Read back provider truth.** Verify table schema, `ds` partitioning, no expirations, schedule,
    run status, descriptions and metadata before writing the final managed-table receipt.

All preflight checks happen before mutation. After mutation begins, failures use explicit
compensation:

- if schedule creation fails, remove the empty table if Tartini AI created it and no run wrote rows;
- if ownership persistence fails, immediately delete the provider config before returning;
- if the first run fails, remove the config and empty table, and create no managed `tables` row;
- if cleanup fails, retain a recoverable ownership/cleanup record and report the orphan honestly;
- if the first run is still pending when the bounded watch ends, keep the owned schedule and report
  pending metadata, never zero rows or success.

## 10. Server-owned SQL composition

The Assistant may propose the business projection, but it must not freely compose a destination DDL
or DML string for the specialized creation path. A dedicated module should compile a typed
`ScheduledTablePlan` into the executable script:

```text
app/bigquery-managed-table-plan.js    plan validation and normalized contract
app/bigquery-incremental-sql.js       server-owned DML compiler
app/bigquery-native-schedules.js      provider TransferConfig lifecycle only
app/bigquery-jobs.js                  dry-run, cost and job primitives
app/table-agent-tools.js              product tool/effect, execution and receipt adapter
```

Do not put this logic in `server.js`, the route, the prompt, or only in the model. The compiler must:

- quote identifiers from validated components rather than interpolating raw paths;
- construct every write target from the Output Dataset, or from a dataset the person named that
  `bigquery.writeTargetFor` approved (never one that replaces an existing table there);
- accept only catalog-resolved source references;
- generate the `DECLARE` window and destination DML itself;
- emit an effect model that distinguishes source reads from managed-destination writes;
- enforce SQL-size, dry-run/cost and location rules; and
- return the exact script used by execution, the post-execution reference, persistence and later updates.

The create plan and recurring script stay distinct: the former is a one-time explicit physical
`CREATE TABLE`; the latter declares the window, then its own destination with
`CREATE TABLE IF NOT EXISTS`, then runs `MERGE` / bounded replacement.
The server preserves and renders their order even when the provider create is performed through the
Tables API rather than SQL DDL.

Because BigQuery allows DDL/DML in scheduled queries but disallows destination write preferences for
them, the existing SELECT + `WRITE_TRUNCATE` config shape cannot be partially reused. Treat the new
incremental compiler as one atomic execution path, not flags spread across the existing full-refresh
path.

## 10a. One bad value must not stop the table refreshing

`PARSE_DATE`, `PARSE_TIMESTAMP`, `PARSE_NUMERIC`, `PARSE_JSON` and `CAST` **raise** on any value they
cannot interpret. A raise inside a scheduled query fails the ENTIRE run: one empty
`first_purchase_date` for one user who never bought anything, and the table stops refreshing for
everybody — at 02:00, unattended, with the failure visible only in a provider log nobody is reading.

Every value conversion in a projection therefore uses its safe form:

```sql
SAFE.PARSE_DATE('%Y%m%d', occurrence_date)
SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', raw_ts)
SAFE_CAST(raw_amount AS NUMERIC)
```

`NULL` is the honest answer for a value that could not be read, and one unreadable field is not a
reason to lose every other field of every other row.

**One exemption, and it is earned rather than assumed:** a conversion whose argument is the wildcard
pseudo-column `_TABLE_SUFFIX`. §7 already REQUIRES that suffix to be filtered with
`BETWEEN FORMAT_DATE('%Y%m%d', load_start) AND …`, so only values of that exact shape reach the
conversion. That matters because the shard suffix is usually what produces `ds`, and `ds` is
`REQUIRED`: a safe conversion returning `NULL` there would fail the load just as surely as a raise.

Where a safe conversion does feed `ds`, the plan must decide explicitly what happens to a row whose
date cannot be read — an explicit `WHERE … IS NOT NULL` in the projection is a choice the user can
see on the card. Silently dropping rows is not.

## 10b. A wide table makes the script four times longer than it looks

A `MERGE` names every column FOUR times: once in the script's own
`CREATE TABLE IF NOT EXISTS`, once in the projection, once in `WHEN MATCHED THEN UPDATE SET`, and
twice more in `WHEN NOT MATCHED THEN INSERT (…) VALUES (…)`. At 60 columns that is a long statement;
at 160 it is tens of kilobytes of mostly repetition, and the plan is refused before anything is
created.

**KNOW WHOSE LIMIT YOU HIT.** `bigquery_sql_too_large` is TARTINI AI'S refusal, from `assertSqlSize` at
`bigquery.maxSqlLength` — BigQuery's own ceiling by default (1,000,000
characters; GoogleSQL accepts about 1,024k of unresolved query text), configurable per installation. It
used to be 20,000, and a script that rule refused would usually have run. Raising the number is therefore a real option and the honest last resort; it is listed last
because a script that is four-fifths repetition is worse to read in a reply, worse to maintain and
worse to reason about, whoever reads it.

Prefer these, in this order. The first two are available today; the last two are not, and are named
so nobody plans around a capability that does not exist.

**1. Carry fewer columns (available today, and by far the biggest lever).** A GA4 export is mostly
nested, and flattening `device`, `geo`, `traffic_source`, `ecommerce` and `event_params` into 160
scalars is a modelling choice, not a requirement. Ask what the table is FOR. Columns the answer does
not need cost length four times over and schema churn every time the export gains a field.
`TO_JSON_STRING(<record>)` keeps a whole group as ONE column that BigQuery can still query
(`JSON_VALUE`), which is what the flat-schema boundary in §11 leaves available — and dropping thirty
scalars removes a hundred and twenty lines.

**2. Bounded partition replacement instead of `MERGE` (available today; §6.2).** It names the columns
twice rather than four times, so the same table is roughly half the text.

**Its correctness condition is unchanged and is not negotiable for length.** Replacement is valid only
when the projection returns the COMPLETE truth for every date in the window. A date-sharded daily
export read through its wildcard satisfies that — each shard is the whole day. An append-only delta
feed does not, and replacing a partition there loses rows already loaded. Shortening a script is a
tiebreaker between two strategies that are both correct; it is never a reason to choose one that is
not.

**3. Drop the in-script `CREATE TABLE IF NOT EXISTS` — NOT recommended.** It is the self-healing path
(§6.0): the physical table is created explicitly by the saga before anything is scheduled, and the
in-script declaration is what rebuilds it the night somebody drops it, instead of failing at 02:00
forever. Removing it buys the column list back once and trades away that recovery. If the script is
too long, take 1 and 2 first.

**4. A stored procedure — the right answer, and NOT IMPLEMENTED.** `CREATE PROCEDURE` once, and the
scheduled query becomes `CALL project.dataset.sp_name(@run_time)` — fifty characters, immune to any
text ceiling, with the logic versioned as its own object. Tartini AI does not create procedures today:
the managed-object kinds are `logging | metric | derived | intermediate | view | materialized`,
ownership is recorded per table, and the backfill preflight compares the compiled script against
`TransferConfig.params.query` — all four would have to change together. Do not describe it as a
current option; it is where this should go.

## 10c. Two runtime failures a syntactically valid script still has

Both pass every check a plan can make, and both fail at 02:00, unattended, on the customer's data.
Neither is about GA4 specifically — the export is simply where they are met first.

**A `MERGE` SOURCE MUST BE UNIQUE ON THE RECONCILIATION KEY.** If the source yields two rows with the
same key inside the window, BigQuery aborts the whole statement:

```text
UPDATE/MERGE must match at most one source row for each target row
```

This is not a rare shape. A client retry, a batch resent after a dropped connection or a duplicated
SDK dispatch puts the same event in an export twice, and a key that includes a nullable component
(`batch_event_index` is often `NULL`) does not separate them. So the projection dedupes itself, at the
grain the key declares:

```sql
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY _TABLE_SUFFIX, user_pseudo_id, event_timestamp, event_name, COALESCE(batch_event_index, -1)
) = 1
```

`COALESCE` on a nullable key component is required in the `PARTITION BY`: `NULL` does not group with
`NULL` there, which is the same NULL-safety the join condition solves with `IS NOT DISTINCT FROM`
(§6.1). The two are different mechanisms for the same hazard and both are needed — one keeps the
source from offering two rows, the other keeps the target from failing to recognize its own.

**A SCALAR SUBQUERY OVER A REPEATED FIELD MUST BE BOUNDED.** Reading one parameter out of a repeated
record is the ordinary GA4 idiom, and it is a scalar subquery:

```sql
(SELECT p.value.string_value FROM UNNEST(e.event_params) AS p WHERE p.key = 'page_location')
```

If a key ever appears twice in one event — two SDK plugins, a tag firing twice, a malformed payload —
that subquery returns two rows and BigQuery aborts:

```text
Scalar subquery produced more than one element
```

The projection must bound every one of them:

```sql
(SELECT p.value.string_value FROM UNNEST(e.event_params) AS p WHERE p.key = 'page_location' LIMIT 1)
```

`LIMIT 1` without an `ORDER BY` picks an arbitrary one of the duplicates, which is the right trade
here: a duplicated parameter has no defensible ordering, and the alternative is losing every column of
every row for all three days. Where one really is preferable — the last write, the non-null one — say
so with `ORDER BY`.

**Both are the same lesson.** A script that works on today's data and dies on tomorrow's is worse than
one that refuses at plan time, because it fails where nobody is looking. §10a says it about a raising
conversion; these two say it about cardinality.

## 11. Schema, quality and cost rules

Production projections use explicit columns and types:

```sql
SELECT
  user_id,
  event_name,
  ds,
  event_timestamp,
  amount
```

Avoid `SELECT *`, implicit string dates/numbers/timestamps, duplicate output names and silent lossy
casts. A schema update must classify changes as additive, compatible, or breaking before execution.

At minimum, managed tables expose or run checks for:

```text
row count for the processed window
duplicate reconciliation-key count
NULL key count
NULL ds count (must remain zero)
freshness / latest completed ds
partition completeness for T-3 through T-1
unexpected source or output schema changes
bytes processed, slot time, duration and affected partitions
```

A quality-check failure is distinct from a provider job failure. Do not erase a successful run or
silently publish suspect data; retain the run receipt and surface the failed assertion.

Before production execution, verify from the query plan or dry-run evidence that:

- the source scans only the required window;
- GA4 uses `events_*` plus `_TABLE_SUFFIX`;
- the target predicate restricts `ds`;
- no full-history rebuild or `SELECT *` remains;
- `ds` is a real required `DATE` and the table is physically partitioned by it; and
- estimated bytes remain within the project's configured limit.

## 12. No expiration and no full-refresh default

Normal managed tables have neither table expiration nor partition expiration. After creation, read
back BigQuery metadata and verify both are absent; a Dataset default must not silently introduce a
TTL. Tartini AI must explicitly clear an inherited table expiration where the provider permits it or
refuse creation with a precise configuration error.

Do not use these as the default refresh algorithm:

```text
WRITE_TRUNCATE
CREATE OR REPLACE TABLE
full-history rebuild
unbounded DELETE + INSERT
```

`CREATE OR REPLACE TABLE ... AS SELECT ... WHERE ds = ...` replaces the entire table, not only the
selected partition. It is never a partition-overwrite shortcut.

## 13. Updating an existing managed table

An update runs through the same plan/compiler/provider-first execution path as creation, and shows its
new script for the same reasons — with one more: this statement REPLACES the script Google has been
running every night, so which nights it changes and what it stops writing belong beside the old
definition rather than in a report afterwards. An update runs when it is called — there is no card —
and its result carries the old-to-new differences for SQL, grain, key, `ds`, window, schema and the UTC
schedule.

- SQL or schema changes re-run source resolution, effect analysis, type validation and cost checks.
- Cadence changes patch the same provider TransferConfig.
- Reconciliation-key or `ds` changes are breaking changes and require an explicit migration plan;
  never reinterpret existing rows in place silently.
- Additive columns may be applied only when the DML and physical schema are updated consistently.
- Removing or retyping a column is refused (below); the corrected table is built under a new name.
- A failed provider update leaves the prior working config and managed metadata intact.
- Provider truth is read back before local metadata changes are committed.

An update to a table created under this contract patches the SAME provider config's query in place:
the table keeps its rows, its partitions and its history, and the config keeps its identity, its
cadence and its run history. Adding a column is additive and lands as `NULLABLE`, because every row
that already exists has no value for it; the result says so, and a backfill (§14) fills those days.
Removing or retyping one is refused, naming exactly what would have changed — that data is gone and
everything reading it stops working, so it is the user's decision and not an "edit": offer the
corrected table under a new name. An update that fails leaves the previous script running, which means the
table goes on working while the plan is corrected.

Existing `WRITE_TRUNCATE` schedules are not converted: an update to one is refused
`scheduled_table_migration_required` and the existing schedule stays untouched. The way forward is a
new table built under this contract.

## 14. Backfill is required for every managed scheduled table

Every physical table covered by this document — `fct_*`, `agg_*`, `dim_*`, `snapshot_*`, and
`stg_*` — must be backfill-ready at creation. Backfill is not a separate loading algorithm. It means:

```text
the same owned production TransferConfig
+ the same production scheduled DML returned as the post-execution reference
+ historical logical @run_time values
```

Do not generate special backfill SQL, create a duplicate TransferConfig, change `ds` semantics, or
replace the T-3 through T-1 window with an ad hoc one-day query. Normal execution, retry and
historical repair remain one deterministic path. An unscheduled one-time table is outside this
contract and cannot be described as backfill-enabled.

### 14.1 Backfill-ready is a creation invariant

A scheduled table may be reported as `backfillReady=true` only when all of these are proven:

```text
the destination table was explicitly created before its first MERGE
the destination still exists and is owned by this managed table
ds is top-level DATE REQUIRED and is the physical DAY partition field
table and partition expiration are absent
the production SQL uses @run_time / @run_date rather than wall-clock time
the production SQL bounds source and target to the stored incremental window
the reconciliation strategy is idempotent under repeated and overlapping runs
the production TransferConfig exists and is owned by this table
the stored plan, compiled SQL and provider config have not drifted
  (the provider's script is what the current compiler, or its one earlier revision, makes of the plan)
```

This is a derived capability, not a checkbox set optimistically during creation. A legacy
`WRITE_TRUNCATE` schedule, an unpartitioned destination, an unknown plan, or configuration drift is
`migration_required`, not backfill-ready.

### 14.2 Logical time and effective coverage

Backfill requests are expressed to users as an inclusive `ds` range, but BigQuery Data Transfer runs
are addressed by historical logical run timestamps. Those are not interchangeable.

Under the current Tartini AI UTC contract, a requested inclusive range:

```text
startDs = D0
endDs   = Dn
```

normalizes to daily logical runs at 02:00 UTC from `D0 + 1 day` through `Dn + 1 day`, inclusive. Each
run still processes T-3 through T-1, so the effective touched coverage is `D0 - 2 days` through
`Dn`. Adjacent runs overlap by design and therefore depend on idempotency.

Example:

```text
Requested ds:          2026-08-04 through 2026-08-10 (inclusive)
Logical run dates:     2026-08-05 through 2026-08-11 at 02:00 UTC
Effective ds coverage: 2026-08-02 through 2026-08-10
Number of runs:        7
```

Confirmation, execution and progress must show all three facts: the requested `ds` range, the exact
logical run timestamps, and effective `ds` coverage. The server derives them from the persisted
plan and schedule. The browser sends user intent and never converts dates to provider timestamps.

All requested run timestamps must be in the past, as required by the provider. Empty ranges, future
runs, `startDs > endDs`, invalid dates and arithmetic overflow fail before confirmation. The range is
never silently truncated.

### 14.3 Use `startManualRuns`, one historical run at a time by default

Use the regional BigQuery Data Transfer endpoint on the existing config:

```text
POST projects/{project}/locations/{location}/transferConfigs/{config}:startManualRuns
```

The default execution strategy is:

```json
{
  "requestedRunTime": "<historical RFC 3339 logical run time>"
}
```

Trigger one run, persist its provider identity, wait for a terminal state, and only then trigger the
next. Default concurrency is **one active backfill run per managed table / TransferConfig**. This
prevents adjacent T-3 through T-1 windows from writing the same partitions concurrently and makes
cost, stop-on-failure and retry behavior deterministic.

`requestedTimeRange` is allowed only after the plan proves that overlapping concurrent writes are
safe and the user confirms the different execution policy. Its `startTime` is inclusive and
`endTime` is exclusive. Google delays subsequent runs by about 15 seconds, but that is not a
completion barrier; a query lasting longer may overlap the next run. Never map an inclusive user
`endDs` directly to the provider's exclusive `endTime`.

Do not build new code on deprecated `ScheduleTransferRuns` / `scheduleRuns`; use
`StartManualTransferRuns` / `startManualRuns`.

### 14.4 Server-normalized backfill plan

The product endpoint accepts intent such as:

```json
{
  "tableId": "<managed Tartini AI table id>",
  "startDs": "2026-08-04",
  "endDs": "2026-08-10"
}
```

It must not accept SQL, a caller-selected destination, TransferConfig name, provider project,
provider location or precomputed UTC timestamps. Tartini AI already owns those facts. A dedicated
server module resolves them into one immutable plan consumed by confirmation, execution, progress
and retry:

```js
{
  managedTableId,
  transferConfigName,
  planVersion,
  scheduleSqlDigest,
  requested: { startDs, endDs },
  incrementalWindow: { startOffsetDays: 3, endOffsetDays: 1 },
  execution: {
    runTimes,
    effectiveDsStart,
    effectiveDsEnd,
    concurrency: 1
  },
  estimate: { runCount, estimatedBytes, estimateStatus }
}
```

Exact field names follow codebase conventions, but normalization happens once on the server. Release
of a confirmed action re-resolves provider truth and compares the immutable plan/version/digest;
stale confirmation cannot launch a changed schedule.

Keep the orchestration out of `server.js`, `tables.js`, the browser and the model. Module ownership,
as implemented:

```text
app/bigquery-backfill-plan.js          date/run normalization, readiness rules and cost plan (pure)
app/bigquery-backfill-store.js         the durable job, its runs, leases and idempotency
app/bigquery-backfill-execution.js     sequential orchestration, recovery, progress, retry, cancel
app/bigquery.js                        the provider half: one historical run, and three reads
app/bigquery-native-schedules.js       owned TransferConfig/run provider primitives
app/table-agent-tools.js               the five agent primitives, the effect, the confirmation and the receipt
app/tables.js                          the coordinator that joins them, and the durable HTTP surface
```

The implemented product endpoint is the agent primitive `plan_scheduled_table_backfill`, and the
durable job is readable without any agent at
`GET /api/tables/projects/:projectId/backfills[/:jobId]`, with `retry` and `cancel` beside it. A
status read also CONTINUES an unfinished job — that, plus a resume at application start, is how the
work makes progress without a local scheduler.

### 14.5 Preflight and confirmation

Before confirmation, re-read the TransferConfig and destination table and verify every
backfill-ready invariant in §14.1. Also verify current IAM, that no run is active for the table, and
that the provider query/config still matches the stored plan. A mismatch returns a precise
`configuration_drift` or `migration_required` result and triggers nothing.

Backfill can multiply cost because N logical runs each scan a three-day source window. Show at least:

```text
managed table and owned Scheduled Query
requested inclusive ds range
exact historical logical run times
effective ds coverage
incremental window
number of runs
estimated bytes per run and total, or an honest unavailable reason
concurrency and chunking policy
execution owner: Google BigQuery Native Scheduled Query
```

The operation always requires confirmation, under its own reason —
`backfill_execution_requires_confirmation`. The user is not approving a statement: the script is the
one their table already runs every night. What is new is how many billed runs there will be and which
days they rewrite.

Large ranges are split into bounded orchestration chunks after showing the whole plan; chunking
changes neither SQL nor logical run times. Product limits must be explicit and must refuse with
guidance rather than silently dropping dates: `bigquery.maxBackfillRuns` (10,000, a daily-partitioned
table's own partition ceiling; it was 400) refuses a longer range with the real
day count and the instruction to run consecutive ranges, and never backfills a prefix of what was asked
for. Within it, one approval covers the whole range and the runner executes it one run at a time.
`bigquery.maxSchedulesPerProject` is unset by default (no count of Tartini AI's; it was 25).

The cost preflight prices a bounded SAMPLE of the runs — the first, the last and evenly spaced days
between them, because a source whose volume grew over the period prices differently at each end. Every
run of the range is listed either way; an unpriced one carries `bytes: null`, and a total derived from
the sample is marked `extrapolated`. An estimate nothing could price is `unavailable` with its real
reason and a `null` total, never `0`.

### 14.6 Progress, failure, cancellation and retry

Persist a product backfill job plus each provider TransferRun. Per-run states use provider-backed
truth, normalized as:

```text
queued
pending
running
succeeded
failed
cancelled
```

The job reports totals, current logical run, succeeded/failed/pending counts, completed effective
coverage, first failure and last completed run. “Backfill started” is never a success receipt.

Sequential execution stops scheduling new runs after the first failure by default, preserves runs
that succeeded, marks the job `partially_failed`, and allows retry from the failed point. A retry may
re-run an already successful overlapping window; the production DML must make that safe. A backfill
run failure does **not** delete or disable the production TransferConfig and does not roll back
historical runs that already succeeded.

Cancellation stops future queued runs. It never deletes the scheduled table, its production config, or
a day that was already rebuilt, and it never disables the ordinary daily refresh. **A run Google has
already accepted is not cancelled** — the Data Transfer Service exposes no cancel for a transfer run,
so Tartini AI watches it to its real end and says so rather than marking it cancelled, which would be an
assertion about somebody else's system. If provider state cannot be read, expose `unknown` rather than
inventing completion.

**Recovery is asked, never assumed.** A run is written down as starting BEFORE the provider call and
its provider name the instant it exists, so a process that dies between them leaves a run that may or
may not be queued in Google. The next pass resolves it by asking the provider for a run at that exact
logical time: found means adopt it, absent means ask again, and unreadable means `unknown` and stop —
never a second run for a day Google already took.

### 14.7 Backfill acceptance tests

All tests inject the provider, clock and limits; no live Google request is allowed. Cover:

- every supported semantic prefix produces a backfill-ready normalized plan;
- the target `CREATE TABLE` operation completes and is read back before any first `MERGE` run;
- `CURRENT_DATE()` / `CURRENT_TIMESTAMP()` plans are not backfill-ready;
- inclusive `ds` ranges normalize to exact 02:00 UTC run timestamps and effective coverage;
- invalid, empty and future ranges fail before confirmation;
- `requestedRunTime` is used sequentially with concurrency one by default;
- the next provider run is not started until the prior run is terminal;
- range mode preserves inclusive-start/exclusive-end semantics and is never treated as serialization;
- the existing owned TransferConfig and byte-identical production SQL are reused;
- provider/config/table drift blocks all runs;
- confirmation release re-resolves plan, IAM, ownership and provider truth;
- failure stops future runs, preserves successes and supports idempotent retry;
- cancellation never deletes the table or production TransferConfig;
- per-run and overall progress never claim pending/unknown work succeeded; and
- legacy, unpartitioned or unplanned schedules report `migration_required`.

## 15. Acceptance tests

All automated tests inject fake Google clients and a fixed clock; they make no live Google call.

Required contract tests include:

- default plan resolves to Daily 02:00 UTC, and no plan input can name a timezone;
- a missing grain, `ds` expression or stable key refuses before mutation;
- all five semantic prefixes share the same default physical contract;
- explicit user overrides are persisted and shown, not silently normalized back to defaults;
- the one-time physical `CREATE TABLE` completes and is read back before the TransferConfig exists
  or its first `MERGE` can run;
- the physical table has required `ds`, daily field partitioning and no expirations;
- generated DML derives its window from `DATE(@run_time, 'UTC')` and covers T-3 through T-1 inclusively;
- both source and target predicates contain the bounded window, and a `MERGE` source is also bounded
  by `ds`, so a row whose `ds` falls outside the window is never inserted again on every run;
- a GA4 projection derives `ds` from the shard suffix it filters on, never from `event_timestamp`;
- reconciliation keys are compared NULL-safely, so a nullable key cannot duplicate a row on every run;
- a raising conversion (`PARSE_*`, `CAST`) outside the `_TABLE_SUFFIX` exemption refuses before mutation;
- a rerun and duplicate provider trigger produce the same logical result;
- GA4 source SQL uses a catalog-resolved wildcard and `_TABLE_SUFFIX`, never a hard-coded shard;
- a DML TransferConfig carries NO destination — not the three params, and not `destination_dataset_id`;
- a config that does carry one is refused by the provider on its FIRST RUN, and the offline provider
  reproduces that refusal rather than accepting the shape;
- destination construction cannot escape the Output Dataset;
- source destructive writes are refused before provider mutation;
- the script handed back after a successful create is byte-for-byte the config's `params.query`;
- the script declares its own destination with `CREATE TABLE IF NOT EXISTS`, partitioned and clustered;
- a correctable failure leaves nothing behind and is retried a bounded number of times, then reported;
- a failure no rewrite can fix (permission, billing, a dataset TTL) is terminal on the first attempt;
- an update patches the same config, adds columns, and refuses a removal or a retype;
- first rows come from the schedule's manual run, not a second producer;
- every partial failure exercises and verifies compensation/orphan reporting;
- updates patch one owned config and provider failure preserves the previous working state; and
- legacy full-refresh schedules stay unchanged until explicitly migrated;
- every new scheduled table is provably backfill-ready under §14; and
- no backfill is reported successful until every required historical TransferRun succeeds.

## 16. Final creation checklist

```text
SEMANTICS
[ ] Name has the correct fct_/agg_/dim_/snapshot_/stg_ business prefix
[ ] Grain is explicit
[ ] Stable key or complete-window replacement proof is explicit
[ ] ds expression and its meaning are explicit
[ ] ds is on the same calendar as the window filter (GA4: the shard date, never event_timestamp)

PHYSICAL TABLE
[ ] The explicit CREATE TABLE operation precedes every first MERGE
[ ] BigQuery read-back proves the target before the TransferConfig is created
[ ] ds is top-level DATE and REQUIRED
[ ] Daily physical partitioning is on ds
[ ] Table expiration is absent
[ ] Partition expiration is absent
[ ] Schema uses explicit columns and types

INCREMENTAL SQL
[ ] Uses @run_time / @run_date logical-time semantics, read as UTC
[ ] Every value conversion that can fail uses SAFE.* / SAFE_CAST
[ ] Reconciliation keys are compared with IS NOT DISTINCT FROM
[ ] Reconciles T-3 through T-1 by default
[ ] Source and target partitions are both pruned
[ ] Reruns and duplicate triggers are idempotent
[ ] GA4 uses events_* and _TABLE_SUFFIX when applicable
[ ] No WRITE_TRUNCATE, full-history rebuild or fake partition overwrite

SCHEDULE
[ ] Requested default is Daily at 02:00 UTC
[ ] The compiled provider schedule is stored and shown
[ ] The user is shown the exact DML that ran, as a reference they can ask to change
[ ] TransferConfig is owned and mapped before its first run
[ ] The first materialization is a manual run of that TransferConfig

BACKFILL
[ ] The same owned TransferConfig and production DML support historical logical run times
[ ] User ds range, logical run times and effective ds coverage are distinct and shown
[ ] Default execution is sequential requestedRunTime with concurrency 1 per table/config
[ ] Cost/run-count preflight, confirmation, per-run progress and retry are available
[ ] Provider drift or a legacy physical contract reports migration_required

TRUTHFUL RECEIPT
[ ] Provider schema, partitioning, expiration and schedule were read back
[ ] Run state and quality checks are reported independently
[ ] Pending is not reported as success or zero rows
```

## Official Google references

- [Scheduling queries](https://cloud.google.com/bigquery/docs/scheduling-queries)
- [Creating partitioned tables](https://cloud.google.com/bigquery/docs/creating-partitioned-tables)
- [Updating partitioned table data using DML](https://cloud.google.com/bigquery/docs/using-dml-with-partitioned-tables)
- [Querying partitioned tables](https://cloud.google.com/bigquery/docs/querying-partitioned-tables)
- [Troubleshoot scheduled-query duplicate runs](https://cloud.google.com/bigquery/docs/troubleshoot-queries#scheduled_query_triggers_duplicate_runs)
- [`transferConfigs.startManualRuns`](https://cloud.google.com/bigquery/docs/reference/datatransfer/rest/v1/projects.locations.transferConfigs/startManualRuns)
- [BigQuery Data Transfer RPC reference](https://cloud.google.com/bigquery/docs/reference/datatransfer/rpc/google.cloud.bigquery.datatransfer.v1)
