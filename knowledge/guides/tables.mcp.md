The rules for tables work in this project, the reference documents it follows, and what is true about
it right now. They govern this area's work and no other.

## Working from Claude Code

You work in the person's local repository with your own shell, editor, git and gh. Tartini AI keeps this
project's definitions (its tracking events, Measurement Plans and metrics), checks your changes against
them and shows them on tartini.ai; it writes no code in the repository and opens no pull request: you do,
as the person. Query and write BigQuery with Google's BigQuery MCP; before any write, show the person the
complete statement; never delete or overwrite a source table. Check a statement before it runs with a dry
run: check_metric for a metric's SQL, else `bq query --dry_run --use_legacy_sql=false` (a parameter as
`--parameter=name::value`). A call that needs a person's confirmation is answered with the tartini.ai page
where they give it: pass the link on.

## Rules

MAKE A SERIOUS ATTEMPT AT THE OUTCOME THE USER ASKED FOR. Reading this guide offers no tool: on this
channel a table is queried, built and refreshed with Google's BigQuery MCP (list_dataset_ids,
get_table_info, execute_sql_readonly, execute_sql) and a BigQuery scheduled query, as the person, under
their own Google permissions. Work out what the finished outcome is, read the real datasets and schemas,
run the queries the work needs and reason over what they return. Complete every part of a request you
CAN complete, even when one part is unavailable — report the part that was unavailable and what it
would need, and hand over the parts that are done. Tartini AI's own Tables tools here only take the
descriptions you write (below).

A TABLE YOU BUILD IS THE PERSON'S, NOT TARTINI AI'S. Tartini AI manages only the tables it built itself,
and knows them by its label: never put `created_by: tartini_ai`, or any label naming Tartini AI, on a table
you create, or tartini.ai will take it for one it manages.

TRUTH.
Never invent a table, a column, a type, a row count or a query result. Never say a BigQuery
operation succeeded unless the tool that ran it said so. When a result says it is a page, a preview, a
sample or truncated, say so — passing a bounded read on as the whole answer is the one way to
be wrong while quoting real data.

THE BOUNDARIES OF THIS WORK. Google's permissions decide what you can do; these decide what you do.
1. Never delete, overwrite, truncate or replace a SOURCE table — the customer's own warehouse, the GA4
   export included — nor its rows or columns. Create new tables, and change only the ones you created
   for this work.
2. Before any statement that writes — CREATE, MERGE, INSERT, UPDATE, DELETE, ALTER, a scheduled query —
   show the person the complete statement, and run it once they agree.
3. ACCESS IS THE PERSON'S TO CHANGE. Answer permission questions fully — who holds what on a dataset,
   why an operation was denied, what role would fix it: `OBJECT_PRIVILEGES` and `ROW_ACCESS_POLICIES`
   are readable — but never run GRANT, REVOKE or a row access policy statement: give them the exact
   statement or role, and where in the Google Cloud console it is done.

A SCHEDULED REFRESH IS A BIGQUERY SCHEDULED QUERY. Google's BigQuery MCP runs one statement now and has
no tool that creates a schedule, so a table that refreshes by itself is a scheduled query running your
script: the person creates it in the BigQuery console (Scheduled queries), or you do with the bq command
line once they agree (`bq mk --transfer_config --data_source=scheduled_query`, `--schedule='every day
02:00'`, the script as its `query` parameter and no destination table). Google runs it whether or not
anybody is connected. The order is the creation reference's (§6.0): the CREATE TABLE, then the scheduled
query, then its first run. A BACKFILL is the same scheduled query run for earlier days — its backfill in
the console, or `bq mk --transfer_run` with a start and an end time — never a second script (§14). A
scheduled table only grows: a new column is an ALTER TABLE … ADD COLUMN and the script's new projection
together (NULL for the days already there — offer a backfill); removing or retyping one is the person's
decision, so offer the corrected table under a new name. Report what really came back, including the
statement, so the person can ask for a change.

A LONG QUERY IS STILL ONE JOB. Google's BigQuery MCP stops waiting for a job after a while and returns
at most 3,000 rows: aggregate in the SQL rather than reading rows out, and when a job is still running
read it back by its id (get_job, get_query_results) rather than running it again.
Never ask them for something a tool could find out, and never ask them to write SQL.

NAME A TABLE WHOLE — `project.dataset.table` — so the person can find it in the BigQuery console and a
later query can read it.

## Building a table with Google's BigQuery MCP

WHERE YOU WRITE. In the dataset the person names, in the same location as the data it reads (BigQuery
joins no tables across locations); ask when they have not named one, and never choose the GA4 export's
own dataset (`analytics_<property id>`) or one another tool maintains. CREATE only a name that does not
exist there yet (`CREATE TABLE`, never `CREATE OR REPLACE`): an existing table is never replaced. Say
which dataset it was written in, by its full name.

WRITING A SCHEDULED TABLE — a CREATE TABLE you run once with execute_sql, and the scheduled query that
runs your script every day (the rules above):
- Google runs it, not Tartini AI, so it keeps refreshing whether or not Tartini AI is running — say it
  that way.
- YOUR SCRIPT IS WRITTEN AGAINST A WINDOW. It opens by declaring two DATE variables from the run's own
  time, `load_start` and `load_end` (T-3 and T-1 of `DATE(@run_time, 'UTC')`, the scheduled-table creation
  reference §5), then `CREATE TABLE IF NOT EXISTS` with the table's schema and `PARTITION BY ds`, then the
  MERGE (§6.0). Its SELECT MUST filter its sources with the window — otherwise it rescans all of history
  every night. It must project a `ds` column: the date the row is ABOUT, as a DATE, never the date the
  load ran. For a date-sharded export read the family through its wildcard (`project.dataset.prefix_*`)
  and bound it with
  `_TABLE_SUFFIX BETWEEN FORMAT_DATE("%Y%m%d", load_start) AND FORMAT_DATE("%Y%m%d", load_end)`.
- TWO CALENDARS, AND `ds` IS ON THE SAME ONE AS YOUR WINDOW FILTER. The RUN calendar is UTC — the
  logical run date, `load_start`/`load_end` and the schedule. Do not ask the user for a reporting
  timezone and do not name one. The DATA calendar is the date the source already carries, and `ds` is
  that date, read the same way the window filter reads it:
  - a date-sharded export is filtered by its suffix, so `ds` is the shard's own date. For GA4 that is
    `PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) AS ds` — the property's reporting day, the same day as
    `event_date` and as GA4's reports. NEVER derive a GA4 `ds` from `event_timestamp`: that is a UTC
    date, which in most timezones moves the first or last hours of every day onto the neighbouring
    date, so the daily numbers disagree with GA4 and a partition replacement drops those hours;
  - a source with a DATE column filters on that column and projects it as `ds`;
  - a source with only a timestamp filters with `DATE(<timestamp>) BETWEEN load_start AND load_end`
    and projects that same `DATE(<timestamp>)` as `ds` — no zone argument.
- USE THE SAFE FORM OF EVERY CONVERSION THAT CAN FAIL: `SAFE.PARSE_DATE`, `SAFE.PARSE_TIMESTAMP`,
  `SAFE_CAST`, and so on. A raw `PARSE_*` or `CAST` RAISES on the first value it cannot read, and a
  raise inside a scheduled query fails the entire run — one empty string in one column and the table
  stops refreshing for everybody, at 02:00, with nobody watching. Converting `_TABLE_SUFFIX` is the
  one exception: the window filter already constrains its format.
- YOUR MERGE SOURCE MUST BE UNIQUE ON THE RECONCILIATION KEY. If two source rows share it inside the
  window, BigQuery aborts the whole statement — and a retried or re-sent event makes that shape
  common. Dedupe in the projection at the grain the key declares:
  `QUALIFY ROW_NUMBER() OVER (PARTITION BY <key columns>) = 1`, wrapping any nullable key component
  in COALESCE, because NULL does not group with NULL there.
- AND BOUND EVERY SCALAR SUBQUERY OVER A REPEATED FIELD with `LIMIT 1`. Reading one parameter out of
  a repeated record returns MORE THAN ONE ROW the day a key appears twice, and BigQuery aborts the
  run rather than the row. Both of these pass every check before they run and fail at 02:00 with
  nobody watching.
- A WIDE TABLE IS A CHOICE. A MERGE names every column four times, so 160 columns is tens of
  kilobytes of repetition nobody can review. Ask what the table is FOR and carry the columns that
  answer it; keep a nested group whole with TO_JSON_STRING instead of flattening it into thirty
  scalars. Bounded partition replacement is half the text of a MERGE — but choose it only when the
  projection really is complete for every date in the window, never to shorten the script.
- THREE THINGS ARE BUSINESS DECISIONS, NEVER GUESSES: the grain, what `ds` means,
  and what makes a rerun safe (a real stable key for a MERGE, or a reason the projection returns the
  COMPLETE truth for every date in the window). Establish each from the source catalog and the schemas
  where you can, and ASK the user where you cannot. Never invent a key merely to produce valid SQL. A
  key column that is sometimes NULL is fine when the MERGE compares keys with IS NOT DISTINCT FROM.
- Name the table for what it is: fct_ (facts at a grain), agg_ (pre-aggregated metrics), dim_
  (descriptive attributes), snapshot_ (state as of each date), stg_ (staging/cleaning).
- Describe the table and each column in BigQuery as you create it (`OPTIONS(description = …)`): that is
  where anybody who reads it later will look.
- SHOW THE WHOLE SCRIPT FIRST: the CREATE TABLE, the scheduled script and its schedule, with the grain,
  what `ds` means and the reconciliation key in a line each; create them once the person agrees.
- IF IT FAILS, FIX IT AND RUN IT AGAIN. Read BigQuery's message: it names the column, the type or the
  row that broke. A failed CREATE leaves nothing behind; a failed scheduled run leaves the table as it
  was, and the next run, or a backfill of that day, puts it right. Each run is a billed job, so after a
  few failed attempts stop and report the last real error instead of looping.
- WHEN IT SUCCEEDS, describe the table from the RESULT, never from your plan: what one row is, when
  it refreshes, the script Google runs, and that you can change it if they want something different.

## The table descriptions are yours to write

From an account's first call from Claude Code, Tartini AI's model writes no table or column description
for any of its projects: you write them, and the Tables pages say what is waiting for Claude Code. When you
start on a project, write every one that is missing at once: list_tables_to_describe gives a page of tables
with the columns that have none, save_table_descriptions takes one table's, and you go on with nextCursor
until complete is true. Write from the schema and what the project does, in a sentence each, without
reading rows you do not need. Only blanks are filled: a description BigQuery or Tartini AI already has is
kept. A source table's are kept by Tartini AI and never written into the warehouse; a table Tartini AI
manages has them written into BigQuery. A date-sharded table (events_YYYYMMDD) is described once, by its
project.dataset.events_* reference, for every day it has and will have.

## References

=== REFERENCE (guidance, not a hard rule — ground in the real code): BigQuery scheduled-table creation reference · docs/tables/bigquery-table-creation-best-practices.md ===
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
=== end reference ===

=== REFERENCE (guidance, not a hard rule — ground in the real code): GA4 export SQL reference · docs/tables/ga4-export-sql-reference.md ===
## (intro)
# GA4 export SQL reference

How Tartini AI reads the GA4 BigQuery export and Tartini Autocapture's events in SQL: the facts every
query depends on, the building blocks, the shapes a result has, the discovery query that comes first,
advertising (§12), sessions and attribution (§13, §14), where each breakdown comes from (§15), Tartini
Autocapture in GA4's own reports (§16) and why a host's analytics counts differently (§17). It is ONE
reference for every place SQL over the export is written — a Measurement Plan's queries (the
Measurement Plan guide), a scheduled table's projection (the Tables guide) and a metric's SQL (the
Metrics guide, §11) — so they can never disagree. Which hosts are production and what one row of a
business fact is are the Analytics business semantics reference's, which every turn carries; how a
scheduled table is built is the scheduled-table creation reference's.
The Measurement Plan reference's Example A holds complete worked queries built from these blocks.

## 1. The export
- **One table per day.** `events_YYYYMMDD`, dated in the GA4 property's own time zone; `event_date` is
  the same day as the table's suffix. GA4's reports count days the same way.
- **Read it through the wildcard** `` `<project>.analytics_<property id>.events_*` `` bounded by
  `_TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix` (strings, `'YYYYMMDD'`). The bound is what makes
  BigQuery read only those days; an unbounded wildcard reads every day there is. Never name one day's
  table.
- **The intraday tables** (`events_intraday_YYYYMMDD`, when streaming is on) match the wildcard too. The
  date-shaped bounds keep them out, so a query reads only finished daily tables.
- **Late data.** A day's table appears the next day and GA4 keeps updating it for up to three days.
  Treat the newest three days as provisional, and say so where a number is shown.
- **The export holds data only from the day it is switched on**, and a standard GA4 property exports up
  to 1 million events a day. Neither can be fixed afterwards.

## 2. People, new people, sessions, days
- **People** are `COUNT(DISTINCT user_pseudo_id)`: one browser or device, not one human. It matches GA4's
  "Total users", not its "Active users". Rows with a NULL `user_pseudo_id` (consent mode) are not people.
- **New people** are GA4's own `first_visit` event. Never "the first `page_view` in the date range":
  someone whose first visit was before the range would look new.
- **A session** is `user_pseudo_id` + the `ga_session_id` parameter (its `int_value`). `ga_session_id`
  alone repeats across people.
- **A day** is the table's date: `PARSE_DATE('%Y%m%d', event_date)` in a query, and
  `PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)` as a scheduled table's `ds` (never a UTC date from
  `event_timestamp`; the scheduled-table creation reference §3).

## 3. Reading parameters
A parameter is read out of the repeated `event_params` record with a scalar subquery, and EVERY one is
bounded with `LIMIT 1` — a parameter that appears twice in one event otherwise aborts the whole query:

```sql
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path
```

- Text is `value.string_value`. A number may arrive as `int_value` or `double_value`: read
  `COALESCE(value.int_value, SAFE_CAST(value.double_value AS INT64))`.
- **`page_view` has no path parameter.** It carries `page_location`, the full URL. Its path is
  `REGEXP_EXTRACT(page_location, r'^[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*(/[^?#]*)')`; Autocapture's events
  carry `page_path` already.
- **A `page_view` counts only where `page_frame` is `'top'` or absent** (absent: sent before the
  parameter existed). A framed one is the same visit seen from inside a frame (the Analytics business
  semantics reference, "One visit, two layers"). Read `page_frame` as text, as above, and count views with
  §11's view rule, word for word.

## 4. Tartini Autocapture's events
| Event | Sent when | Parameters |
|---|---|---|
| `auto_click` | a click on a button, a link, or an element marked as one | `element_tag`; `element_role` (when set); `element_id` — the HTML `id` only; `element_label` — the element's `aria-label`, else its `title`, else its visible text, whitespace collapsed, never typed text; `element_section` — the nearest section, header, nav, footer or main: its `id`, else `aria-label`, else its first heading; `link_type` — `internal`, `outbound`, `mailto`, `tel`, `download`, `anchor` or `none`; `link_path` — an internal link's path; `page_path` |
| `auto_form_start` | the first focus or input in one of a form's fields, once per form per page view | `form_id`; `form_type`; `page_path` |
| `auto_form_submit` | a form is submitted — an interaction, not proof the submission succeeded | `form_id` — its `data-testid`, else `id`, else `name`, else `aria-label`, else `unnamed_form`; `form_type` — `search`, `login`, `signup`, `contact`, `newsletter`, `checkout` or `other`, from the fields' `type` and `autocomplete` alone; `field_count`; `page_path` |
| `auto_page_engagement` | an active stretch on a page ends (at least one second) | `page_path`; `engaged_time_seconds`; `max_scroll_depth` (0–100); `flush_reason` |

`page_path` and `link_path` are paths only — no query string, no hash — with values that look like an
email, a phone or a card number removed; no value is longer than 80 characters. A site still on the
earlier v2 component sends no `auto_form_start`, `form_type`, `element_section`, `link_type` or
`link_path`: they are NULL there. Autocapture sends no `page_view` and no `scroll`;
GA4's own events and Autocapture's measure different things, and are never added together.

## 5. Recognizing an action
An action — "clicked Purchase", "submitted the sign-up form" — is an event AND a page AND an id, a label
or a form, never a label alone: the same text sits in the header, the footer and every product card.

- Prefer `element_id` when the element has one: text changes with copy, translation and prices.
- Compare `element_label` in lowercase (`LOWER(TRIM(…))`): CSS can show "Purchase" as "PURCHASE".
- Match the page with a regular expression on the path (`r'^/checkout'`, `r'^/pricing/?$'`): a path may
  or may not end in a slash.
- Never use `form_id = 'unnamed_form'` as an action: it collects every form that has no name.
- Keep the actions in ONE place at the top of a query, as rows, so the real values found by the
  discovery query (§9) are changed there and nowhere else:

```sql
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('start',    'auto_click', r'^/pricing/?$', 'start-trial', 'start free trial', NULL),
    ('complete', 'auto_click', r'^/checkout',   NULL,          'purchase',         NULL)
  ])
)
```

- **Finished counts people who finished after they started**: per person and day, the first start and
  the last completion, `last_complete >= first_start`.

## 6. Production only
Every query filters `device.web_info.hostname IN ('<production host>', …)`: Tartini's Website Preview
and pull-request deployments send real GA4 events from their own hostnames. Which hosts are production
is decided as the Analytics business semantics reference says ("Production metrics exclude Preview and
test traffic by default"), and the discovery query (§9) lists every hostname in the data. The filter is
the SQL's job, and the reply says which hosts were counted; a name never says it (a metric is "First visits",
never "First visits (production)"), because every number is production's unless the person asked otherwise.

## 7. The shapes a result has
- **A rate is in percentage points**: `ROUND(100 * SAFE_DIVIDE(part, whole), 1)` — 28.7 means 28.7%, the
  way a Tartini percent metric reads a number. `SAFE_DIVIDE` gives NULL, not an error, on zero.
- **A metric** returns one row per day, `day` and `value`; a funnel `day`, `step` and `value` (§11). A
  plan's query for a metric is named like it and returns exactly that.
- **A table of results** for a person reads one row per day (or week), the date first.
- **A window that has not passed is NULL, never 0.** A day-7 return rate for people who arrived four days
  ago is unknown, not zero: `IF(DATE_ADD(first_day, INTERVAL 7 DAY) <= newest_day, …, NULL)`, where the
  newest day is the newest the data holds — never the wall clock.
- **A headline rate over several days adds up the people, never averages the daily rates.**

## 8. One read-only statement
Tartini runs ONE read-only statement per query: no `DECLARE`, no script, no temporary function, no
second statement. Dates come in as parameters (`@start_suffix`, `@end_suffix`); repeated logic is a
`WITH` block. A script is refused before anything runs.

## 9. Discovery: the real buttons, forms and hostnames (run first)
Before any query counts an action, this one shows what the site really sends — the paths, ids, labels,
forms and hostnames — so the actions and the hostname filter are written from the data, not guessed:

```sql
-- Query 0 · Find the real buttons, forms and hostnames. Run it first, once data arrives.
SELECT
  event_name,
  device.web_info.hostname AS hostname,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1)     AS page_path,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1)    AS element_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1) AS element_label,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1)       AS form_id,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS people
FROM `your-gcp-project.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
  AND event_name IN ('auto_click', 'auto_form_submit')
GROUP BY event_name, hostname, page_path, element_id, element_label, form_id
ORDER BY events DESC
LIMIT 200
```

## 10. Checking a query before saying it works
A query is checked with a BigQuery dry run of the exact statement: it says whether BigQuery accepts it
and how many bytes it would read, returns no rows and costs nothing. Say "dry run passed on <date>" only
when a tool reported it; a query that has not run on this project's data is Demo SQL, and is labelled so.

## 11. A metric's SQL
A metric (the Metrics guide) is ONE read-only statement that returns ONE row a day for its date range,
`_TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix`. Code binds only the parameters a statement
mentions and never edits its text; it is checked with a dry run (`check_metric`) before it is saved.

- **A line** returns exactly `day DATE, value`. **A funnel** returns exactly `day DATE, step INT64,
  value`: steps numbered from 1 with no gap, each step's value the sessions that reached it in order.
- **A 7-day window** also takes `@lookback_start_suffix`, which code binds six days before the range
  starts, so the first day has a whole window.

- **Its breakdown** is a second statement taking `@dimension` (one of the metric's dimension keys,
  `CASE @dimension WHEN 'country' THEN … END`): one row per value over the whole range,
  `dimension_value STRING, value` and at most one more count column (a funnel: `dimension_value, step,
  value`), the rows that matter most first.
- **A view** is a `page_view` in the top frame — a framed one is the same visit seen from inside a frame:
  `event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top'`.
- **The channel** is GA4's default channel group, worked out from the session's lower-case `source`,
  `medium` and `campaign` (`t`; §12 says where they come from) and the source's category, which code
  binds as two parallel arrays (`@category_sources`, `@category_names`). It is one rule, used whole wherever a channel is counted
  (paid sessions are a Google Ads click or one of `Paid Search`, `Paid Social`, `Paid Video`, `Paid Shopping`, `Paid Other`, `Display`, `Cross-network`):

```sql
SELECT
  t.*,
  CASE
      WHEN (t.source IS NULL AND t.medium IS NULL)
        OR (t.source = '(direct)' AND t.medium IN ('(none)', '(not set)')) THEN 'Direct'
      WHEN REGEXP_CONTAINS(LOWER(t.campaign), r'cross-network') THEN 'Cross-network'
      WHEN (cat.category = 'SOURCE_CATEGORY_SHOPPING'
            OR REGEXP_CONTAINS(LOWER(t.campaign), r'^(.*(([^a-df-z]|^)shop|shopping).*)$'))
        AND REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN 'Paid Shopping'
      WHEN cat.category = 'SOURCE_CATEGORY_SEARCH'
        AND REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN 'Paid Search'
      WHEN cat.category = 'SOURCE_CATEGORY_SOCIAL'
        AND REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN 'Paid Social'
      WHEN cat.category = 'SOURCE_CATEGORY_VIDEO'
        AND REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN 'Paid Video'
      WHEN t.medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN 'Display'
      WHEN REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN 'Paid Other'
      WHEN cat.category = 'SOURCE_CATEGORY_SHOPPING'
        OR REGEXP_CONTAINS(LOWER(t.campaign), r'^(.*(([^a-df-z]|^)shop|shopping).*)$') THEN 'Organic Shopping'
      WHEN cat.category = 'SOURCE_CATEGORY_SOCIAL'
        OR t.medium IN ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media')
        THEN 'Organic Social'
      WHEN cat.category = 'SOURCE_CATEGORY_VIDEO' OR REGEXP_CONTAINS(t.medium, r'^(.*video.*)$')
        THEN 'Organic Video'
      WHEN cat.category = 'SOURCE_CATEGORY_SEARCH' OR t.medium = 'organic' THEN 'Organic Search'
      WHEN t.medium IN ('referral', 'app', 'link') THEN 'Referral'
      WHEN REGEXP_CONTAINS(t.source, r'email|e-mail|e_mail|e mail')
        OR REGEXP_CONTAINS(t.medium, r'email|e-mail|e_mail|e mail') THEN 'Email'
      WHEN t.medium = 'affiliate' THEN 'Affiliates'
      WHEN t.medium = 'audio' THEN 'Audio'
      WHEN t.source = 'sms' OR t.medium = 'sms' THEN 'SMS'
      WHEN REGEXP_CONTAINS(t.medium, r'push$|mobile|notification') OR t.source = 'firebase'
        THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
FROM traffic AS t
LEFT JOIN (
    -- Two parallel arrays, because the query binder has no STRUCT array.
    SELECT source, category
    FROM UNNEST(@category_sources) AS source WITH OFFSET AS i
    JOIN UNNEST(@category_names) AS category WITH OFFSET AS j ON i = j
  ) AS cat ON cat.source = t.source
```

- **A day with no event is a 0; a day the export does not hold is no day.** A count or an amount returns a row
  for every day the export holds over the days asked for — its tables' own days, whatever their events, never
  this metric's filtered ones — so a day with export data and nothing counted is a true 0, and a day whose table
  has not landed (today, a gap in the export) stays absent. Without it a quiet day has no row, the page shows no
  number for it, and the line is drawn with a gap. A rate is never filled: its day with no denominator is NULL.
  Count into a CTE named `counted` (`day, value`), then:

```sql
source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
)
```

```sql
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

## 12. Advertising
Sources: Google's GA4 export, traffic attribution and BigQuery Google Ads transfer pages (text CC BY 4.0,
code Apache 2.0), Google Ads Help on importing Analytics conversions, Fivetran dbt_google_ads (Apache 2.0),
dbt-ga4 (MIT). None of it has run on BigQuery.

- **A session's source is `session_traffic_source_last_click`** (Google: "To determine session traffic
  source, use the session_traffic_source_last_click record"): §11's `t` is the `source`, `medium` and
  `campaign_name` of its `cross_channel_campaign`, else its `manual_campaign`, else `google` / `cpc` when
  it has a `google_ads_campaign.campaign_id`. Never `traffic_source`: the USER's first source, on every
  session.
- **Before July 2024 the record is NULL** (it arrived in mid-July 2024, `cross_channel_campaign` in
  mid-October; dates per Adswerve). A query switches per session, never on a date it names: a session
  with no `cross_channel_campaign.source`, `manual_campaign.source` or `google_ads_campaign.campaign_id`
  on any event takes its first event with a `collected_traffic_source.gclid` or a
  `collected_traffic_source.manual_source` other than `(direct)` (`manual_source`, `manual_medium`,
  `manual_campaign_name`; a `gclid` alone is `google` / `cpc`, as in dbt-ga4's `stg_ga4__events.sql`),
  else it is Direct. Rebuilt days carry no source over from earlier visits, so they count more Direct (and
  before mid-2023, per Adswerve, there is no `collected_traffic_source`): say so on a chart crossing them.
- **Spend** is the Google Ads transfer's `ads_CampaignBasicStats_<customer id>`, partitioned by the day
  the numbers belong to (`_DATA_DATE`, as in Google's sample queries); names are in `ads_Campaign_<customer
  id>` at `_DATA_DATE = _LATEST_DATE`. Fields as dbt_google_ads's `models/google_ads__campaign_report.sql`
  names them: `_DATA_DATE AS date_day`, `campaign_id`, `metrics_cost_micros / 1000000 AS spend` (the Ads
  account's currency), `metrics_clicks AS clicks`, `metrics_impressions AS impressions`,
  `metrics_conversions AS conversions`, `metrics_conversions_value AS conversions_value`. The transfer
  re-reads the last 7 days by default: recent Ads days change too.
- **GA4 sessions join the spend on `campaign_id` and `date_day`**, the campaign being
  `SAFE_CAST(session_traffic_source_last_click.google_ads_campaign.campaign_id AS INT64)` (text in the
  export, INT64 in Google Ads; match `customer_id` too with several accounts); each day is in its own
  account's time zone. A session with a `collected_traffic_source.gclid` is a Google Ads click (§11);
  before July 2024 it names no campaign, but the transfer's ClickStats table maps `click_view_gclid` to
  `campaign_id`.
- **Google Ads and GA4 conversions never match, and are never added together.** Ads dates a conversion
  on the day of the click that led to it, GA4 on the day it happened; `metrics_conversions` is Primary
  actions only (All conversions adds Secondary ones); an action counting One counts one conversion per
  click, Every counts all; and a GA4 key event imported into Ads arrives up to 24 hours late.
- **Each metric names the side its number reads**: spend, clicks, impressions and Ads conversions from
  Ads; sessions and on-site conversions from GA4. A ratio of the two (cost per conversion, return on ad
  spend) names both, and its GA4 side counts Google Ads sessions only: theirs is the only cost in BigQuery.

## 13. Sessions, landing pages and last non-direct attribution
Session metrics start from one row per session (after dbt-ga4's sessions models, MIT; the metric
templates' Shared GA4 block is the whole statement, its `sessions` and `traffic`):

- **Its key** is `user_pseudo_id` + `ga_session_id` (§2), and its day is the day it started.
- **Its place and device** are its first event's (`geo.*`, `device.*`): one session, one country.
- **Its landing page** is the path of its first view, the first `page_view` in the top frame (§3), as
  GA4's Landing page report reads it. A session with no view has none: GA4's `(not set)`.
- **Engaged** means one of its events carries `session_engaged` `'1'` (text on some events, a number on
  others: read both). The engagement rate is engaged sessions over sessions.
- **New or returning**: `ga_session_number` 1 is New.
- **Its source** is §12's. GA4's reports credit a session that arrived with no source of its own
  (Direct) to the same person's latest earlier non-direct source, which is last non-direct click, and
  `session_traffic_source_last_click` is GA4's own answer. A session rebuilt from the collected source
  (§12) carries nothing over. Where that matters, carry it over as dbt-ga4's
  `stg_ga4__sessions_traffic_sources_last_non_direct_daily` does, over 30 days by default, reading the
  30 days before the range too:

```sql
-- A Direct session takes the latest non-direct source of the same person's sessions in the 30 days
-- before it; one with none stays Direct (NULL). started_micros is its first event_timestamp.
SELECT
  s.*,
  IF(s.direct,
     LAST_VALUE(IF(s.direct, NULL, STRUCT(s.source, s.medium, s.campaign)) IGNORE NULLS) OVER (
       PARTITION BY s.user_pseudo_id ORDER BY s.started_micros
       RANGE BETWEEN 2592000000000 PRECEDING AND CURRENT ROW),
     STRUCT(s.source, s.medium, s.campaign)) AS last_non_direct
FROM sessions AS s
```

`direct` is §11's first rule: no source and no medium, or `(direct)` with `(none)` or `(not set)`.

## 14. A page's address without click identifiers
`page_location` is the whole address, query string included, and an ad click adds an identifier unique
to that click (`gclid`, `gbraid`, `wbraid`, `dclid`, `fbclid`, `msclkid`, and `_gl`, the cross-domain
linker), so one page becomes thousands of addresses. Group pages by their path (§3), as GA4's page and
landing page reports do. Where the query string matters, take those identifiers out and keep the rest
(the idea of dbt-ga4's `query_parameter_exclusions`). Whether a session came from an ad is read from its
fields (§12), never parsed out of the address.

```sql
-- page_location without click identifiers; every other parameter and the #fragment kept.
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(page_location,
  r'([?&])(gclid|gbraid|wbraid|dclid|fbclid|msclkid|_gl)=[^&#]*', r'\1'),
  r'\?&+', '?'), r'&{2,}', '&'), r'[?&]+(#|$)', r'\1') AS page_location_clean
```

## 15. Where each breakdown comes from
A metric's breakdown keys are a closed list in code (`app/metrics/metric-dimensions.js`). Each reads
one export field at one level: a session gives each session one value, an event gives each event its
own, so one person can be in several rows.

| Key | Export field | Level |
|---|---|---|
| `page` | the path of `page_location` | event |
| `landing_page` | the path of the session's first view (§13) | session |
| `page_title` | the `page_title` parameter | event |
| `hostname` | `device.web_info.hostname` | session |
| `channel` | §11, from the session's source | session |
| `source`, `medium`, `campaign` | the session's source (§12) | session |
| `country`, `region`, `city` | `geo.country`, `geo.region`, `geo.city` | session |
| `language` | `device.language` | session |
| `device_category` | `device.category` | session |
| `browser` | `device.web_info.browser` | session |
| `os`, `os_version` | `device.operating_system`, `device.operating_system_version` | session |
| `device_model` | `device.mobile_model_name` | session |
| `user_type` | `ga_session_number` (1 is New) | session |
| `item_name`, `item_category` | `items.item_name`, `items.item_category` | item |
| `event_name` | `event_name` | event |

The export has no age, gender or interests (Google signals stay out of it) and no screen resolution: a
split by them is GA4's own report, never SQL. City, device model and OS version are `(not set)` where
granular location and device data are off. The Google Ads keys (`ads_campaign`, `ads_network`,
`ads_device`, `ads_country`) read the Google Ads transfer (§12).

## 16. Tartini Autocapture in GA4's own reports
The export carries every parameter (§4). GA4's reports and its Data API show a parameter only once it is
registered in GA4 Admin, Custom definitions: a Data API report that asks for an unregistered one
(`customEvent:element_label`) is refused, and a registration fills only from the events received after
it. With Autocapture installed, register:

- **Custom dimensions, event scope:** `element_tag`, `link_type`, `element_role`, `element_id`,
  `element_label`, `element_section`, `link_path`, `form_id`, `form_type`, `flush_reason`.
- **Custom metrics, event scope:** `field_count` (Standard), `engaged_time_seconds` (Seconds),
  `max_scroll_depth` (Standard). GA4 adds a custom metric up: an average divides it by the event's
  count, and a visit's deepest point needs the export.
- **Not `page_path`:** the Google tag reads it as the hit's own page, GA4's page path, so there is
  nothing to register.

These are the lists a tracking pull request's checklist gives (`app/ga-rules.js`).

## 17. Why GA4's numbers differ from Vercel's and Cloudflare's
A host's own analytics counts in its own way, so its numbers and GA4's do not match: compare trends,
never totals.

- **GA4** runs JavaScript in the browser and knows a browser by its first-party cookie (`_ga`), so a
  declined consent banner and an ad blocker both lower what it counts.
- **Vercel Web Analytics** knows a visitor by a hash of the request that it drops after a day: someone
  who comes back the next day is counted again.
- **Cloudflare Web Analytics** counts a visit only when someone arrives from another site or opens the
  address directly; moving between the site's pages is not a new visit.
=== end reference ===