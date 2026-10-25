# Analytics business semantics

The business facts Tartini AI relies on when it reads, models or reports analytics data. Each entry
states what a unit of data MEANS for the business, where its identity comes from, and what analysis
must therefore assume. These are facts and rules, not queries: any Table, model, Dashboard or
Assistant answer that touches the data honours them however it is written. SQL is one way of
executing a business meaning; the meaning comes first.

This file is deliberately small. It is not a semantic layer; add an entry when a business fact is
established, and state what is verified and what is not.

It is an AGENT REFERENCE: `app/agent-references.js` registers it as `analytics_semantics` and
`app/agent-system-prompt.js` puts it, whole, into every Tartini AI (`project_assist`) turn.
It never overrides what the user explicitly asked for, the real schema, or current IAM — but where a
request is silent, these are the defaults, and a departure from them is said out loud.

Two sentences carry the rest:

> **Tartini uses GA4. Tartini does not recreate GA4.** Google owns collection and transport; Tartini
> owns understanding, implementation, inspection and analytics semantics.
>
> **The tracking layer captures stable business identity; the Table and Dashboard layer interprets
> raw observations at the business grain.**

---

## Business grain first

Before writing SQL for a table, a widget or an answer, decide **what one row of the business fact
represents** — and write it down in the table description, the widget's About text or the answer.

- A purchase: one transaction (`transaction_id`).
- A subscription: one subscription (`subscription_id`), one invoice (`invoice_id`) for billing facts.
- A booking: one booking (`booking_id`).
- An interaction: one occurrence of the interaction, as the question defines it.
- Engagement: a session, a user or a page — whichever the question is about.

Never assume that **one GA4 raw event row = one business fact**. Choose the grain from the question,
then build the query so every row of its result is exactly one unit of that grain.

## GA4 raw event rows are observations, not business facts

A raw GA4 event row (the BigQuery export's `events_*`, or any table copied from it) is an
OBSERVATION: the browser reported something at a moment. The same business fact may be observed more
than once — a refreshed confirmation page, a second tab, the back button, a remount, a retried
network send — and an observation carries context (`event_timestamp`, session, batch and ingestion
metadata) that legitimately differs between two observations of the same fact.

So business metrics are computed at the business grain appropriate to the question:

| Raw observation | Canonicalize to | Then compute |
|---|---|---|
| `purchase` rows | one row per `transaction_id` | transaction count, revenue |
| `auto_click` / click rows | interaction occurrences, as the question defines "a use" | feature usage |
| `auto_page_engagement` rows | one page visit (session + page): SUM the seconds, MAX the depth | active time, scroll depth |
| `page_view` rows | sessions, users or pages (`ga_session_id` + `user_pseudo_id`, `user_pseudo_id`, page) | engagement |

Do not answer every metric with `COUNT(*)` or `SUM(...)` directly over raw rows. When the grain IS
the raw event ("how many `auto_click` events were sent"), say that the number counts events, not
people or uses.

## GA4's events and Tartini Autocapture's measure different things — never add them together

A site with Tartini Autocapture sends three events of its own beside GA4's (`auto_click`,
`auto_form_submit`, `auto_page_engagement`). Their names differ from Google's on purpose: both may be
present for one interaction, which is not double counting, and two different names are never summed
into one metric. Each question has one signal:

| Question | Signal |
|---|---|
| page views | GA4 `page_view` — Tartini never sends one |
| outbound links, file downloads, video | GA4's own `click`, `file_download`, `video_*` |
| how far down a page people really read | `auto_page_engagement.max_scroll_depth` (0–100); GA4 `scroll` is one 90%-threshold event, not a depth |
| how long people were really active on a page | `auto_page_engagement.engaged_time_seconds` — visible and focused time only |
| which forms were submitted | `auto_form_submit` (by `form_id`); GA4 `form_submit` may also exist and is never added to it |
| which UI controls are clicked most | `auto_click` (by `element_label` / `element_id` / `element_tag`) |
| did the checkout, sign-up or lead succeed | Phase 1: the closest GA4 or Autocapture signal (the confirmation page's `page_view`, a form's `auto_form_submit`), saying what it counts. `purchase`, `sign_up` or `generate_lead` only when the person asked for it or agreed to it as an advertising or acquisition plan's one conversion event; then never `auto_click` or `auto_form_submit` |

`auto_page_engagement` is sent once per stretch of activity (a route change, the page being hidden,
the page closing), so one visit to one page can have several rows: SUM `engaged_time_seconds` and take
the MAX of `max_scroll_depth` over the visit (`ga_session_id` + `user_pseudo_id` + `page_path`). A
stretch under one second is not sent. `auto_form_submit` says a submission was attempted, not that it
succeeded. None of these events carries a typed value, and `page_path` is a pathname with no query
string.

## Stable business identity beats browser and session identity

When the business already has an authoritative identity — `order_number`, `transaction_id`,
`subscription_id`, `booking_id`, `invoice_id` — analysis groups by it. A different tab, browser
session, page mount or `event_timestamp` does NOT make a second business object; counting one real
object several times because its observations differ in those fields is the mistake to avoid.

Browser and session identity (`user_pseudo_id`, `ga_session_id`, a tab) are the right grain only for
questions that are ABOUT browsing: sessions, visitors, engagement.

## Deduplicate by business key, never with `SELECT DISTINCT *`

`SELECT DISTINCT *` (or `DISTINCT` over every column) is NOT business-key deduplication. Two
observations of one transaction differ in `event_timestamp`, session and batch fields, so they are
distinct rows and both survive — the duplicate revenue stays. Deduplicate by partitioning or grouping
on the business identity:

```sql
-- The GRAIN, shown on a GA4 export. Not a universal recipe: see the next section before using it.
WITH purchase_observations AS (
  SELECT
    ecommerce.transaction_id AS transaction_id,
    event_timestamp,
    ecommerce.purchase_revenue AS revenue,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'currency' LIMIT 1) AS currency
  FROM `my-project.analytics_123456.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'purchase'
),
canonical_purchase AS (
  SELECT *
  FROM purchase_observations
  WHERE transaction_id IS NOT NULL AND transaction_id != ''
  QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY event_timestamp) = 1
)
SELECT COUNT(*) AS purchases, SUM(revenue) AS revenue
FROM canonical_purchase
```

Never compute revenue as `SUM(value)` straight over raw purchase rows.

## One visit, two layers: `page_frame` decides which row counts

A page shown inside another page of the same site (an iframe) and the page around it are two
documents, and each sends its own events. Every event of such a site carries `page_frame` —
`'top'` or `'framed'` (Tracking reference §8a) — so the two layers never produce rows a query cannot
tell apart. Count each measure from ONE layer:

| Measure | Rows that count |
|---|---|
| page views | `page_view` where `page_frame` is `'top'` or absent (events from before the parameter existed) — a framed `page_view` is the same visit seen from inside the frame |
| active time, scroll depth | the frame's rows when the visit has them (the content is there), else the top page's — never the two added |
| clicks, form submissions | every row: each happens in one layer only |

## Duplicate observations versus conflicting facts

Deduplicate identical or repeated observations; **do not hide conflicting business facts.**

Picking "the earliest row" per `transaction_id` is correct only when the rows agree on the business
fields. Before relying on it, check whether any transaction's observations disagree:

```sql
SELECT transaction_id,
       COUNT(*) AS observations,
       COUNT(DISTINCT TO_JSON_STRING(STRUCT(revenue, currency))) AS distinct_facts
FROM purchase_observations
WHERE transaction_id IS NOT NULL AND transaction_id != ''
GROUP BY transaction_id
HAVING distinct_facts > 1
```

When that returns rows — the same `transaction_id` with a different value, currency or items — the
agent does not silently choose one and continue. It:

1. says so, with the count and an example id;
2. looks for an authoritative source (an orders or payments table in the user's warehouse) and, when
   one exists, prefers it for the business value;
3. otherwise reports the conflict as a data-quality finding (a DQ note in the table description, a
   visible caveat on the widget, or both), and makes any figure that depends on the
   choice say which rule it used.

## Missing or invalid identity is a data-quality finding

A purchase whose `transaction_id` is missing, empty, a constant, or plainly unstable (a timestamp, a
random value, one id per page load) cannot be attributed to a transaction. It is never silently mixed
into canonical revenue and never counted as a separate transaction:

- count and report those rows separately ("N purchase events have no transaction id");
- validate against an authoritative order table where one exists;
- do not present a precise revenue figure the data cannot support.

## Production metrics exclude Preview and test traffic by default

Every number built from GA4 data describes PRODUCTION traffic unless the person asks otherwise:
revenue, conversion, active users and feature adoption, and just as much a daily event count, a
managed table, a saved query, a dashboard widget or a one-line answer. "It is only an event count" is
not an exception. (Found in practice: a 30-day event-count query and a daily event-count table each
counted a Tartini preview site and thirty-five pull-request previews as if they were the shop; fewer
than one event in seven came from production, and neither result said so.)

Where an event came from:

- **Hostname.** On a GA4 web stream's BigQuery export, `device.web_info.hostname` is the site the
  event was sent from. Production and a hosted preview (a pull-request deployment, a staging site)
  usually differ here. Tartini AI's own Website Preview is one such source: interactions in it are
  real events sent by the customer's own Google tag, and they carry the preview's hostname.
- **Stream.** When the customer sends preview or test traffic to a separate Data Stream, `stream_id`
  separates it more strictly than a hostname can.

Decide which values are production from **the customer's real configuration and data**, every time
GA4 data is counted:

1. **Name production first; it is an allow-list.** Production is the host of the project's website
   (`get_project_state` → `project.websites[].hostname`, the live address its Tracking was set up
   with), plus any host the person names as production. Every other host is left out. Never build a
   deny-list of test hosts instead: a hosted preview is created for every pull request and every
   deployment, so a list of known previews is out of date the day after it is written.
2. **Look before aggregating.** Once per turn, before the first query that counts events, read the
   hosts actually present over the same date range:
   `SELECT device.web_info.hostname AS hostname, COUNT(*) AS events FROM … GROUP BY 1 ORDER BY 2 DESC`.
3. **Filter in the definition.** `WHERE device.web_info.hostname IN ('<production host>', …)` belongs
   in the SQL itself: a managed table's definition (so every scheduled run and every backfill applies
   it), a widget's query, a saved query. A filter that lives only in one answer is lost on the next
   run.
4. **Say it.** The answer, the table description and the widget's About name the hosts counted and
   what was left out, in the result's own numbers: "Production only (<host>); left out <n> events
   from <k> other hosts." **A name never says it.** Production is every number's default, so the name
   and sentence of a metric (and of a plan's Core metrics row), a table, a saved query or a widget are
   the plain business name: "First visits", never "First visits (production)" or "first visits on the
   production site". `save_metric` refuses a metric name that says production.
5. **When production cannot be identified** (no website address, its host absent from the data, or
   several plausible hosts) say the environment is undetermined, show the hostname split, and ask the
   person which hosts are production in one multiple-choice question that names them. Do not guess.

Never hard-code a rule such as "a hostname containing `preview` is test traffic" and never assume
Tartini AI's own domains are the only non-production ones.

Count every host only in two cases, and label the result:

- the person explicitly asks for preview or test traffic;
- the question is about collection itself: does an event arrive, from where, which event names
  exist in the export, a check of a Preview or a pull-request deployment. Then give the production
  figure beside the total, or split the result by hostname.

Tartini AI does not add an `environment` parameter or any private marker to events to make this
possible; analysis uses the context GA4 already records.

---

## Purchase — the business grain is `transaction_id`

**Fact.** A GA4 `purchase` event reports ONE real business transaction, and its `transaction_id` is
that transaction's business identity. The grain of purchase data is the transaction, not the event
row: one real transaction may legitimately appear as more than one raw `purchase` row.

**Why there can be more than one row.** The page that reports a transaction — typically an order
confirmation page — can run again for the same transaction: a refresh, a new tab, a bookmark, the
back button, a remount. Tartini AI does NOT suppress those re-sends with browser storage
(localStorage, sessionStorage or cookies); they are the same transaction reported again, not a new
one. The implementation contract guarantees the identity instead: the same transaction always carries
the same `transaction_id`.

**Where the identity comes from.** The authoritative business record that confirmed the transaction —
for example the order or transaction number the server created and stored. It is stable, non-empty
and unique per transaction. It is never produced on the page (no random value, timestamp, UUID, or
anything tied to a mount, a session or a tab), never an empty string and never a constant. The
Candidate gate refuses those statically provable failures
(`ga4_transaction_id_not_a_business_identity`, DESIGN.md "GA4 Implementation Validation Contract",
check 9).

**What analysis must assume.**

- Raw `purchase` rows that share a `transaction_id` are ONE business transaction.
- Every downstream count, table, model and revenue figure built from raw purchase data deduplicates
  defensively by `transaction_id` before it counts transactions or sums revenue — whatever the
  collection path promises.
- A purchase row with an empty or missing `transaction_id` cannot be attributed to a transaction; it
  is reported as a data-quality finding, never silently merged with others or counted as a separate
  transaction.
- The same `transaction_id` reported with different values (amount, currency, items) is a
  data-quality finding to surface, not a second transaction.
- `transaction_id` maps to the persistent order identity, so an authoritative order table joined on
  it is the preferred check of GA4-derived revenue.

**Scope.** This is GA4 web `purchase` semantics. It is not a statement about other events, other
parameters or other analytics backends; each of those needs its own entry.

**Verified and not verified.**

| Statement | Status |
|---|---|
| GA4 deduplicates `purchase` events that carry the same `transaction_id` on **web** streams, not app streams; an empty `transaction_id` makes all such purchases one; the same id must not be reused across users | Google Analytics Help, "[GA4] Minimize duplicate key events with transaction IDs" (answer 12313109), read 2026-09-25. It describes reporting. |
| A refresh and a new tab of the same order confirmation report the SAME `transaction_id` | Verified on a Tartini-generated implementation: identical payloads, `transaction_id` = the persisted, unique `orders.order_number` |
| Whether the GA4 **BigQuery raw export** keeps one row or several for purchases that share a `transaction_id` | **NOT verified.** The help article does not say. Until a real GA4 web stream + BigQuery export experiment settles it, analysis must not assume either way — which is why the defensive deduplication above is unconditional. |
| `device.web_info.hostname` and `stream_id` are columns of the GA4 BigQuery export | Google's published export schema. Which of a customer's hostnames or streams is production is NOT a schema fact and is decided per project, as above. |
