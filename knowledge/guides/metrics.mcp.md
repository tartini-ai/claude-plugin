The rules for metrics work in this project, the reference documents it follows, and what is true about
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

A METRIC is a name, one plain sentence of what it counts, and ONE read-only SQL over this project's
data, checked by BigQuery and computed every day once that check passes; a defined metric is the project's agreed answer.
ANSWERING A QUESTION ABOUT A NUMBER, in this order: (1) if a defined metric answers it, use it
(list_metrics, get_metric_values) and say which metric you used; (2) if none does, say plainly that this
is not a defined metric, then write the SQL and run it (Google's BigQuery MCP, as the person's own account); (3) after
answering, offer to save it as a metric. A split the metric does not offer as a breakdown is the same:
answer it from the metric's definition with your own query, say it is not a defined breakdown, and save
nothing.
WRITING ONE: the daily SQL returns exactly `day DATE, value` (a funnel: `day DATE, step INT64, value`, steps
numbered from 1 with no gap, each step's value the sessions that reached it in order), one row a day,
reading its days through @start_suffix and @end_suffix; code binds the parameters a statement names
and never edits its text. Its breakdown SQL takes @dimension, one of the dimensions it lists, and
returns one row per value over the whole range. Count views, sessions and channels exactly as the GA4
export SQL reference §11 writes them — its channel CASE and its view rule are used whole, never
rewritten. A rate is in percentage points. A count or an amount returns a row for every day the GA4 export
holds (§11, "A day with no event is a 0"): a quiet day is a 0, a day not landed is no day; a rate is never
filled. Check with check_metric before you save, fix what it
reports, then save_metric. A version whose check passes is computed at once, starting with its last 90
days; nobody confirms it. One whose check fails, or that BigQuery could not check, is saved and NOT
computed (a changed metric keeps computing its last good version): say why and fix it. Never say a metric
is computed, or verified, unless a tool said so; `verified: false` means BigQuery could not be asked, so
say the SQL is not verified yet. Only the person deletes a metric, on its page.
NAMING ONE: its name is the plain business name a person says ("First visits", "Add to carts") and its
sentence says what it counts; neither names the environment. Every metric is the production site's number
already, because its SQL keeps only the production hosts, so a name never says "(production)" or "(prod)"
(save_metric refuses it) and the sentence never says "on the production site". Which hosts were counted
and what was left out is said in your reply.
When a metric has no number, say the reason its `reason` gives, in plain words. Nothing holds a metric
back while the tracking it counts is still in a pull request: save_metric and check_metric name each
event the merged code does not send yet and where it waits (a branch, a pull request). Say so, and that
the metric has no number for the days before that pull request is merged and deployed.
DEMO METRICS SHOW WHAT A MEASUREMENT PLAN'S METRICS WILL LOOK LIKE, before its launch has data. When the
person asks for a demo of a plan, read the plan with get_measurement_plan, then call create_demo_metrics
ONCE with its planId and one card for EVERY row of its Core metrics table, named exactly as the table
names them, in its order (a plan on the earlier template: the metrics its Metrics section lists). A card
is a line (a point a day for the last 30 days, ending yesterday) or, for the plan's workflow, a funnel
with its steps. Its numbers are ONE consistent sample: the same number wherever two cards meet (a
funnel's first step is that range's visitors), rates in percentage points, plausible for the product, no
target, and a return rate whose window has not passed yet null, never 0. They are drawn, labelled DEMO,
under the plan's Demo line on its page on tartini.ai, a line code writes as a new version of the plan:
you do not edit the plan for it, and you pass the page's link on. Tell the person plainly these are demo
numbers, not their data; never quote one as measured or answer from one, and never save one as a metric.
Demo cards copied from a screenshot are drawn only in a Tartini AI conversation on tartini.ai, which has
the result card they are drawn on. With data connected, define real metrics instead and list the tiles
you cannot ground.

## Using the Metrics tools

- To change a metric, read it with get_metric and pass its version as expectedVersion with only the
  fields that change; a stale version is answered with the current one: read it again.
- `dimensions` are keys of the fixed list, in the order the page shows them; a Google Ads dimension needs
  a breakdown SQL that reads a Google Ads table.
- `events` names the GA4 events the metric counts, so the page can say which one the code does not send.
- A funnel's `compareWith` is another funnel of this project with the same steps (the paid funnel beside
  the whole one); its numbers are read from what is stored, never queried again.
- How the person SEES the Metrics page on tartini.ai (its days, list or cards, order, sizes, columns,
  hidden metrics) is theirs, set on that page or by asking Tartini AI there: there is no tool for it
  here, and it never changes a metric.

## Analysis

GA4'S OWN REPORTS. With Google's GA4 MCP added (pipx run analytics-mcp), run_report reads GA4's reports
through its Data API, as the person, and run_realtime_report its last 30 minutes. Ask for GA4's own
dimensions and metrics rather than rebuilding them: landingPage (the path of a session's first page),
sessionDefaultChannelGroup (the session's channel, as GA4's reports credit it), engagementRate and
sessionKeyEventRate (fractions: 0.287 is 28.7%, where a Tartini metric is in percentage points), beside
sessions, activeUsers and keyEvents. A parameter is in a report only once it is registered in GA4 as a
custom dimension or metric (`customEvent:<parameter>`); asked for before that, the request is refused.
get_custom_dimensions_and_metrics lists what is registered, and the GA4 export SQL reference §16 says what
Tartini Autocapture needs. GA4's reports estimate people and sessions and may hide small rows; the BigQuery
export holds every event, so the two are close, not equal: say which one a number comes from. A defined
metric still answers first (the order in the rules above).

THE EXPORT IN SQL. Sessions, landing pages and last non-direct attribution are the GA4 export SQL
reference §13; an address without click identifiers §14; which export field each breakdown reads §15;
the channel §11 and advertising §12; and why GA4's numbers differ from Vercel's and Cloudflare's §17.

## References

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

=== REFERENCE (guidance, not a hard rule — ground in the real code): Metric templates · docs/metrics/metric-templates.md ===
## (intro)
# Metric templates

Where an agent STARTS a metric: ten templates for every site,
thirteen more when the site runs ads, and a lead variant for a business with no purchase. A template is
a name, one sentence, a unit, a direction, a shape, the events and tables it needs, one read-only SQL
with a few placeholders, and its default breakdowns. It is a starting point: not a metric type, not a
question bank and not a verified answer. `app/metrics/metric-templates.js` holds the same templates as
data; its tests run every statement on sample rows in DuckDB through the real check. None of this SQL
has run on BigQuery.

## How the agent uses a template
1. **Pick** from the project's facts and the request (the tables under "Which templates"): version 1
   for every site; version 2 as well when the site runs ads, every row when it runs Google Ads (the
   Google Ads tag in the code, or GA4 linked to Google Ads) and only the rows marked *any paid* when its
   paid traffic comes from other platforms only; the lead variant when the business sells nothing on the
   site. Save the ones the person's question or plan needs, not all of them.
2. **Read** the template's own section, `read_guide({ domain, section: "<template name>" })`, and the
   shared blocks it names ("Shared GA4 block", "Shared breakdown blocks"). A statement is those blocks
   followed by the template's text, exactly as written: the template's text starts with `SELECT`, or
   with `, <name> AS (`, which continues the block's `WITH`. In the GA4 block's `channels` CTE, paste the
   SQL block of the GA4 export SQL reference §11, whole.
3. **Fill the placeholders** (Conventions) from what the project already knows: its BigQuery
   connection, its websites, the tracking inventory, the Google Ads transfer. Read a fact; never ask for
   one the system can read. Change nothing else.
4. **Check, then save.** `check_metric` dry-runs the SQL and the breakdown SQL as the project's own
   BigQuery account: whether BigQuery accepts them, their shape, the tables they read. Fix what it names,
   then `save_metric` with the name, definition, kind, unit, direction, a funnel's steps (each with the
   `event` it counts), the events,
   `sql`, and in the SAME call its `breakdownSql` and `dimensions`: one saved without them has no
   Breakdown card, and the result says so. A name the project has is never a second
   metric: the same kind and daily SQL is reused, anything else is `metric_name_taken`; tell the person.
   A metric whose check passes is computed at once, starting with
   its last 90 days; nobody confirms it. A template whose Google Ads table is not in BigQuery yet is saved
   and not computed, and its check says "Google Ads cost is not in BigQuery yet.".
5. **Paid conversion funnel** compares with the Conversion funnel: save that one first, then set
   `compareWith` to its id. Their steps have the same names, which is what lets them compare.
6. **The request wins.** Another window, page, event or split is a change to the SQL, written as the
   GA4 export SQL reference says and checked the same way. Say what was checked: a template's SQL has
   run on this project only when `check_metric` says so.

## Conventions
- **Shapes** (`metric-contract.js`): a line returns `day DATE, value`; a funnel `day DATE, step INT64,
  value`, steps 1 to 5, each the sessions that reached it in order. A breakdown takes `@dimension` and
  returns `dimension_value STRING, value` and at most one more count column (a funnel:
  `dimension_value, step, value`), the rows that matter most first.
- **Parameters** code binds where a statement names them: `@start_suffix` and `@end_suffix`
  (`'YYYYMMDD'`), `@lookback_start_suffix` (six days before the start, for the 7-day gap), `@dimension`,
  and `@category_sources` with `@category_names` (the channel). A fact of the project is a placeholder.
- **Units**: `percent` is percentage points (`100 * SAFE_DIVIDE(part, whole)`: 28.7 means 28.7%);
  `ratio` a plain ratio (3.2 means 3.2x); `currency` has no symbol (Google Ads cost is in the Ads
  account's currency, GA4's revenue in the site's). Direction `none` is drawn gray.
- **Two sides** (the GA4 export SQL reference §12): spend, clicks, impressions and Ads' own conversions
  come from the Google Ads transfer, everything else from the GA4 export; the two never agree day by day
  and are never added together. A ratio of both counts Google Ads sessions only: theirs is the only cost
  in BigQuery.
- **Sessions**: `user_pseudo_id` and `ga_session_id`, on the day they started. Source:
  `session_traffic_source_last_click`; a session with none (days before July 2024) takes its first
  collected source, else Direct (§12), so those days count more Direct. Channel: §11's rule, the same in
  every metric and breakdown. Paid: a Google Ads click (a Google Ads campaign or a gclid) or a paid
  channel. Organic search: the Organic Search channel.
- **Views**: a `page_view` in the top frame (§11). **Orders**: one per `transaction_id`, with its first
  purchase event's day, value and items. **Revenue**: `ecommerce.purchase_revenue`, minus
  `ecommerce.refund_value` of `refund` events. **Production only**: `{{production_hosts}}`.
- **Breakdown keys** (`metric-dimensions.js`): S is the session dimensions `landing_page`, `hostname`,
  `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`,
  `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type`; A is the Google Ads
  dimensions `ads_campaign`, `ads_network`, `ads_device`, `ads_country`. The page groups them itself.

| Placeholder | Filled with | Example |
|---|---|---|
| `{{events_table}}` | the export's wildcard, from the BigQuery connection | `flowers-prod.analytics_412870551.events_*` |
| `{{production_hosts}}` | the production hostnames, quoted, comma-separated | `'flowers.example.com'` |
| `{{product_path_re}}` | a raw regular expression on the page path | `r'^/products?/'` |
| `{{add_to_cart_step}}`, `{{checkout_step}}`; lead: `{{main_button_step}}`, `{{form_start_step}}`, `{{form_submit_step}}` | ONE condition over `events`, from what the code sends today | below |
| `{{conversion_event}}` | lead variant only: `'generate_lead'` or `'sign_up'`, the event the person agreed to | `'generate_lead'` |
| `{{ads_dataset}}`, `{{ads_customer_id}}` | the Google Ads transfer's dataset, and the customer ID in its table names (ten digits) | `flowers-prod.google_ads`, `1234567890` |

A step condition is an event the code sends (`event_name = 'begin_checkout'`), Autocapture's click on a
button by its label in lower case (`event_name = 'auto_click' AND LOWER(TRIM(element_label)) = 'add to
cart'`) or by its id (`event_name = 'auto_click' AND element_id = 'add-to-cart'`), or Autocapture's
submit of one form (`event_name = 'auto_form_submit' AND form_id = 'quote'`), with
`AND REGEXP_CONTAINS(page_path, r'…')` where the same label is on several pages. Never `auto_click` or
`auto_form_submit` alone, and never `unnamed_form`.

## Which templates
**Version 1: without ads** (every site; breakdown: its keys, then its extra column):

| Name | Definition | Unit | Direction | Shape | Breakdown |
|---|---|---|---|---|---|
| Active users | People who used the site that day. | count | up | line | `page`, `page_title`, S; views |
| New users | People on their first visit. | count | up | line | S without `user_type` |
| Returning users | People who had been here before. | count | up | line | `page`, `page_title`, S without `user_type`; views |
| Sessions | Visits to the site. | count | up | line | S |
| Engagement rate | Engaged sessions ÷ sessions: over 10 seconds, a key event, or 2+ pages. | percent | up | line | S; sessions |
| Organic search sessions | Visits from search results, not ads. | count | up | line | S without `channel`, `medium` |
| Purchases | Orders, each transaction_id counted once. | count | up | line | S, `item_name`, `item_category` |
| Revenue | Purchase value, minus refunds. | currency | up | line | S, `item_name`, `item_category` |
| Average order value | Purchase value ÷ purchases, before refunds. | currency | up | line | S; orders |
| Conversion funnel | Purchases ÷ sessions, with every step in between: in order, in the same session. | percent | up | funnel | S |

**Version 2: added when the site runs ads** (*Google Ads*: only when it runs Google Ads; *any paid*: any
paid traffic):

| Name | Definition | Unit | Direction | Shape | When | Breakdown |
|---|---|---|---|---|---|---|
| Ad spend | What Google Ads charged that day. | currency | none | line | Google Ads | A |
| Ad conversions | Orders placed in paid sessions, each order counted once. | count | up | line | any paid | S |
| Cost per conversion | Ad spend ÷ orders from Google Ads sessions. | currency | down | line | Google Ads | `ads_campaign`; conversions |
| Revenue from ads | Purchase value from paid sessions, minus refunds. | currency | up | line | any paid | S |
| Return on ad spend | Revenue from Google Ads sessions ÷ ad spend. | ratio | up | line | Google Ads | `ads_campaign`; spend |
| Paid conversion funnel | Purchases ÷ paid sessions, with every step in between: in order, in the same session. | percent | up | funnel | any paid | S |
| Paid sessions | Sessions from a Google Ads click or a paid channel. | count | up | line | any paid | S |
| Click-through rate | Ad clicks ÷ ad impressions. | percent | up | line | Google Ads | A; impressions |
| Cost per click | Ad spend ÷ ad clicks. | currency | down | line | Google Ads | A; clicks |
| Click-to-session rate | Google Ads sessions ÷ ad clicks; a drop means lost gclids or slow pages. | percent | up | line | Google Ads | `ads_campaign`; clicks |
| Paid engagement rate | Engaged paid sessions ÷ paid sessions. | percent | up | line | any paid | S; sessions |
| Conversion gap, Ads vs GA4 (7-day) | How far Google Ads' conversions are from GA4's orders from Google Ads sessions over 7 days: (Ads − GA4) ÷ GA4. | percent | down | line | Google Ads | none |
| Auto-tagging coverage | Google Ads sessions that carry a gclid. | percent | up | line | Google Ads | S; sessions |

**Lead variant** (a business with no purchase; `{{conversion_event}}` is `generate_lead` or `sign_up`;
each template's section has its lead SQL):

| Template | In the lead variant |
|---|---|
| Purchases | Leads (Sign-ups for `sign_up`): sessions with the conversion event, each once; S |
| Revenue, Average order value, Revenue from ads, Return on ad spend | removed, and with them the Items breakdowns |
| Conversion funnel, Paid conversion funnel | steps Sessions, Clicked the main button, Started the form, Submitted the form, Succeeded |
| Ad conversions, Cost per conversion, Conversion gap, Ads vs GA4 (7-day) | count converting sessions instead of orders |
| every other template | unchanged |

## Other sections of this reference (not included above: 31 of 35)
read_guide({ domain: "metrics", section: "<heading>" }) returns any of them whole.
- "Shared blocks" (179 characters)
- "Shared GA4 block" (9647 characters)
- "Shared breakdown blocks" (2504 characters)
- "Days with no event" (997 characters)
- "Version 1: without ads" (538 characters)
- "Active users" (1553 characters)
- "New users" (1580 characters)
- "Returning users" (2024 characters)
- "Sessions" (1064 characters)
- "Engagement rate" (964 characters)
- "Organic search sessions" (1261 characters)
- "Purchases" (2733 characters)
- "Revenue" (2174 characters)
- "Average order value" (830 characters)
- "Conversion funnel" (5078 characters)
- "Version 2: added when the site runs ads" (468 characters)
- "Ad spend" (2931 characters)
- "Ad conversions" (2401 characters)
- "Cost per conversion" (5453 characters)
- "Revenue from ads" (1681 characters)
- "Return on ad spend" (3032 characters)
- "Paid conversion funnel" (3840 characters)
- "Paid sessions" (1325 characters)
- "Click-through rate" (2901 characters)
- "Cost per click" (2761 characters)
- "Click-to-session rate" (2640 characters)
- "Paid engagement rate" (874 characters)
- "Conversion gap, Ads vs GA4 (7-day)" (3474 characters)
- "Auto-tagging coverage" (1163 characters)
- "Breakdowns: what GA4 offers, and what the export carries" (2270 characters)
- "Sources" (1591 characters)
=== end reference ===