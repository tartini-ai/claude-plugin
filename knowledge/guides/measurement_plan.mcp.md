The rules for measurement_plan work in this project, the reference documents it follows, and what is true about
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

A Measurement Plan is ONE document per plan. FIRST RECOGNISE ITS SCENARIO from the request and the
product: a launch, a landing page, activation, checkout, a retention health check, acquisition, an
experiment or a small change (the scenarios reference below); write its key on the line under the
title (`Scenario: landing_page`) and write from its recipe. The template in the Measurement Plan best
practices reference is a launch: TL;DR, Core metrics and Metrics for the product manager and
leadership, then Tracking, BigQuery queries, Tables to build later and the Launch checklist for
Tartini AI, engineers and the data team; another scenario keeps the sections its recipe needs (a new
draft writes `## Metrics`; a saved plan with `## Dashboards` keeps it). Follow its structure and thinking and fit every detail to the
request: what the person asked for first, then what the project really has, then the template's
defaults — never Example A's names, numbers, pages, buttons or windows. Write it from what you can
really see: read the public pages the person names with your own web fetch — and only addresses a page
you read LINKS to, never one you guess (a guessed address that does not exist is a failed read and a
slower turn; a few pages are enough) — look at the screenshots they
attach, and read the project's tracking and data where they are connected.
BEFORE THE FIRST DRAFT OF A PLAN, ASK ON ONE QUESTION CARD — the question tool, all the questions on
one card; the same turn goes on with the answers. Look at the product first, so the options are its
own. Ask: (1) THE GOAL — the one main thing this plan should track, with two to four likely answers
from what you saw (daily active users, purchases, sign-ups, bookings…); (2) BESIDES THE GOAL, what
else they care about (they may choose several): the user journey from its first step to the goal (in a
shop, from viewing an item to buying it), performance — how fast pages load and how often errors
happen — and any other area this product suggests; (3) any other metric they already know they want;
(4) only when the scenario is not clear, which kind of plan this is, with the two or three likely ones.
Ask only what they have not said: leave out a question their message already answers, and ask nothing
when it answers all three or they asked for the plan without questions. Never ask what a tool can find
out. The answers decide the plan: the goal is the Goal row, a journey they chose is the Core workflow,
performance is a Quality row where a signal the plan uses can see it, and otherwise a line under the
table saying what it would need. Declined or left blank: choose sensibly and say what you assumed. A
change to a saved plan asks nothing first. Then write the WHOLE
document in one call to draft_measurement_plan, following the Measurement Plan best practices reference
and its template, and read it against the reference's "Before you save the draft" questions first;
when the check lists problems, fix every one and call again. Part 1 is plain words with no event,
parameter or SQL word; five to ten metrics, ideally about five; no target unless the person asks; the
goal is a rate. Part 2 is exact: every Core metrics row has its query, headed with the row's exact
name and returning `day` and `value` one row a day, labelled Demo SQL (a funnel returns `day`, `step`
and `value` and names its steps on a `Steps:` line under the heading); then its breakdown, headed with
the same name and " · breakdown", taking @dimension and returning `dimension_value` and `value` over the
range, with a `Dimensions:` line of the keys it answers (the plan reference A.6). Start them from the
metric templates and fill their placeholders from this project. THE QUERIES READ THIS PROJECT'S DATA:
when get_project_state shows its GA4 export linked (`ga4Export`), every query reads that dataset's
`events_*` and the hostnames of its `websites`, never a placeholder; with none linked a query keeps one
(`<project>.analytics_<property id>.events_*`) and says so in its first line and the Status. LOOK AT THE DATA
BEFORE YOU WRITE A QUERY: when that export has daily tables, run the plan's Query 0 (the data check) on its recent days first, with
Google's BigQuery MCP (execute_sql_readonly), and check every query you write with check_metric (a metric's query)
or `bq query --dry_run` (any other), fixing what it rejects. Write every path, event, button label or id, form and hostname from what Query 0
returned; an action it does not show stays "seen on the website" or "confirm with code", never a guess written as
a fact. The Status line and each query's first comment lines say the evidence THAT query really has: Query 0 ran
(its date, and how many days it read), dry run passed (its date), or not run and why. "Not run on your data yet"
is true only of a query nothing ran or checked. Saving the plan makes each row a
metric with that query and that breakdown. Say plainly what you could not see — a success that happens on a server, a
page behind a sign-in — and mark it "confirm with code" in the plan rather than guessing. Here
draft_measurement_plan saves the document as a new plan at once: say it is saved only when its result says so. To change a saved plan, read it with
get_measurement_plan first; prefer edit_measurement_plan_section, naming every part one request changes
(a metric's row, its query and its card) in ONE call so they become one version; use
update_measurement_plan only to rewrite the whole document, and always pass the version you read —
when it has changed since, read it again instead of repeating the call. A plan saved under the earlier
template is edited in its own shape unless the person asks to move it to the current one.

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

=== REFERENCE (guidance, not a hard rule — ground in the real code): Measurement Plan best practices and document template · docs/measurement/measurement-plan-best-practices.md ===
## (intro)
# Measurement Plan best practices and document template

This is the reference of the Measurement Plan guide: how Tartini AI writes and revises a Measurement
Plan, one Markdown document per launch, from the template in A.7. It is knowledge, not a rule engine.
The deterministic checks are `app/measurement-plan-markdown.js` (the document's structure) and
`app/ga-rules.js`; how GA4 export data is queried is the GA4 export SQL reference, which travels with
this guide.

**Follow the structure and the thinking; fit every detail to the request.** The order of precedence:

1. What the person asked for in this conversation.
2. The project's real state: the website, the events its code already sends, the data.
3. This document's defaults.

**Recognise the plan's scenario first**, and write from its recipe: the scenarios reference, which
travels with this guide, has the eight scenarios, what each needs and the metric tree. This template and
Example A are a launch; another scenario keeps the sections its recipe needs.

The template's headings and the few rules code checks (A.7, "What must stay") are fixed. Everything
else is chosen for THIS product: the goal, the workflow, the return window, the number of metrics, the
charts, the queries. Every name, number, page, button, window and chart in the template and the
examples is a placeholder or an illustration, never a default to copy. When the person drops a part
("no SQL", "only four metrics"), keep its heading and write `Not included at your request.` under it.

## A.0 Phase 1: Autocapture first
This is the product's rule for now and it governs everything below. A plan's
metrics — their demo cards and the real ones — and its Tracking are built from signals that need no
business instrumentation:

- **GA4's own events.** `page_view` with its page path answers "reached this page" — a confirmation,
  pricing or success page included — plus `session_start`, `first_visit`, `user_engagement`, and the
  Enhanced Measurement events where the stream setting is on.
- **Tartini Autocapture.** `auto_click` — which button or link was clicked, by its id or label, on
  which page; `auto_form_submit` — which form was submitted; `auto_page_engagement` — active seconds
  and scroll depth per page. A conversion rate is clicks on a named button over visitors of its page.
  When Autocapture is not installed, enabling it is the plan's first Tracking step.
- **The events the site's code already sends**, reused exactly as they are.

The Demo metric cards draw exactly those metrics, so every demo card is a number the production
metric can compute from real GA4 and Autocapture data; a metric the signals cannot compute gets no
card. No other event is recommended, listed or used — not in a metric, the Tracking table, the `Not needed`
line, a demo card or a suggestion for later — unless the person explicitly asks for that event (they
name it or a parameter on one, or ask which business events to add or what else to track beyond GA4 and
Autocapture). That includes adding a parameter to an existing event.
A request to "reuse what exists" or to "only suggest what is truly missing" is not a request for a
business event: what is missing is measured by the closest signal — an order placed is a `page_view`
of its confirmation page, a sign-up a `page_view` of the page that follows it or an `auto_form_submit`
of its form. The `Not needed` line names only events GA4 or Autocapture already send (GA4's `scroll`
where `auto_page_engagement` reads depth, GA4's `form_submit` beside `auto_form_submit`), never a
business event. An event that neither sends (`view_item`, `view_cart`, `add_to_cart`, `sign_up`, `purchase` …)
appears nowhere in the plan unless the site's code already sends it or the person asked for it. When a metric's
best signal is an approximation — a click on "Place order", a view of the confirmation page, a
submitted form — define the metric on that signal and say plainly what it counts; never propose an
event to close the gap.

**The one exception: an advertising or acquisition plan** (`Scenario: acquisition`) may recommend
ONE conversion event, the one the ads optimise for: `generate_lead`, `sign_up`, or `purchase` with
`transaction_id`, `value`, `currency` and `items`. Say in one sentence why (an ad platform optimises only
for an event it receives). It is written into the Draft only after the person agrees, and goes through the
Pull Request as usual. Every other plan keeps the rule above.

## A.1 Who reads which part
A plan has two parts, and they are written for different people.

**Part 1 — `TL;DR`, `Core metrics`, `Metrics` — is for the product manager and leadership.** Write
it as you would for a busy executive: plain words, short sentences, one idea each. No event or
parameter names, no table or column names, no SQL words, no jargon such as "signal", "instrument",
"cohort" or "attribution". Say "people who clicked Purchase", not "`auto_click` where `element_label`
is purchase". Data sources are said in words ("Clicks on 'Purchase'", "Google Analytics page views").

**Part 2 — `Tracking`, `BigQuery queries`, `Tables to build later`, `Launch checklist` — is for
Tartini AI, engineers and the data team.** Make it as specific as possible: exact event and parameter
names, page paths, button ids and labels, hostnames, and every query written out in full. Saving the
plan makes the project's metrics from exactly this part, and a later Tartini AI turn builds the tables
from it, so anything left vague here is guessed later. The line
`*Everything below is the implementation detail, for Tartini AI, engineers and the data team.*`
separates the two parts, after a `---` rule.

Write the content in the language of the conversation. The headings stay in English: code checks the
document and edits it section by section by its headings.

## A.2 Three questions, and the metrics that answer them
A launch (the template's scenario) is judged by three questions; another scenario asks its own (the
scenarios reference):

1. **Are people using it?** Do they start the main workflow, finish it, and does it work?
2. **Do the people who used it come back?**
3. **Did it bring the result we wanted?** This one is answered by the goal metric.

Before choosing any metric, understand the product: what it is, who it is for, the main workflow, the
moment people first get value, and how it makes money (the TL;DR's lines say all five). The metrics are
then reasoned for THIS product. Two products never get the same plan with the names changed, and
nothing below is a lookup table.

**The Core metrics table has one row per metric, and a `Role` column.** The roles:

| Role | What it measures | In the first version |
|---|---|---|
| Goal | The one result the launch is judged by. A rate: who ÷ who, over what time | Always exactly one |
| Core workflow | The main workflow: of the people who start it, the share who finish it (and, if it helps, the share who start) | Always; a funnel when people drop off between steps |
| Retention | Whether people come back, on the product's own rhythm | Always |
| Traffic | Page views, daily visitors and where they come from: is the launch getting attention | Usually one or two rows of context, never a launch's goal |
| Activation | Whether new people reach the first-value moment | Only when that moment differs from finishing the workflow |
| Revenue | Whether it makes money through the product | Only when it applies and a Phase 1 signal can count it |
| Quality | How often the path that can fail does fail | Only when there is a real failure path |
| Guardrail | What must not get worse while the goal is chased | In every experiment; elsewhere Quality says it |
| Other | A guardrail or a split that helps one decision | Rarely |

- **Five to ten metrics, ideally about five**, unless the person asks for more. Each one has to change a
  launch decision; if it would not, leave it out.
- **No targets** unless the person asks for them. A target set in advance is the person's call, not
  the template's.
- **The goal is a rate, never a count**: people who did the thing ÷ the people who could have, per day
  or per week. "Purchase clicks" moves with traffic; "the share of daily visitors who click Purchase"
  moves with the product.
- **Every row says who ÷ who, over what time**, and where the data comes from, in plain words.
- **Core workflow — started → finished.** "Started" and "finished" are actions that really happen — a
  page reached, a named button clicked, a form submitted (A.0) — and each is named for exactly what it
  counts. Finished counts people who finished after they started, on the same day or in the stated
  window.
- **Retention — on the product's real rhythm.** Work the window out from THIS product, never from an
  example: how many days usually pass between two real uses or purchases? Read the return at about that
  gap, and at two or three times it if one read is not enough (each window is its own metric). Something used every day: the next days
  (day 1, day 7). A tool used every week: weeks 1 and 4. A box billed every month: the next renewal, about
  day 30–35. Shoes, furniture or a camping trip, bought a few times a year: 60 and 90 days, or the next
  season — a 7-day "return" on those measures browsing, not coming back. Example A's day 7 belongs to
  its product and is never a default. Say why in one sentence under the table. A window that
  has not passed yet is blank, not zero.
- **The table's mix is this product's.** Example A has six rows — a goal, two Traffic rows, a two-step
  workflow and one return rate — because that fits its pricing page → trial → purchase path. Another
  product's table usually looks different: an Activation row when the first value is not the end of the
  workflow, a Quality row when there is a failure page, a Revenue row when a Phase 1 signal can count
  it, one Traffic row or none, a three-step funnel when that is the real path. Decide every row from the
  product; never keep A's rows and change their names.
- **Activation is usually not its own row.** The first-value moment is a line of the TL;DR. Add an
  Activation row only when that moment is not the end of the main workflow (the first design exported
  after a free sign-up, the first box delivered after checkout).
- **Quality** only when the product has a real failure path a Phase 1 signal can see (an error page
  after an upload). Never invent an error metric to fill the table.
- **Traffic is context.** Page views and daily visitors say whether the launch gets attention; they are
  never the goal, and they never stand in for the workflow.
- **No vanity metrics:** totals that only go up, time on site, or anything no decision reads.

Under the table, three plain lines: why this return window; what is not in this first version, and
why; and what a click or a page view can and cannot prove (a click on Purchase means someone tried to
buy, not that they paid).

The three kinds of metric, for reasoning: the **goal** moves slowly and is what the launch is judged
by; **drivers** move faster and explain it (the workflow, retention, activation); **guardrails** must
not get worse while chasing it (quality; or, for example, "eats into another product line"). They
usually become readable in this order: quality on launch day; the workflow in week 1; retention when
its window closes; the goal when enough time has passed for it to move.

## A.3 Goal metrics by product type — examples to reason from
The right goal depends on how the company makes money and where users get value. What follows are
examples to reason from, NOT a mapping from product type to metric: a product can play more than one
game, a feature's goal is narrower than its company's (A.4), and in Phase 1 every goal is read from
page views, button clicks and form submissions (A.0). Amplitude's North Star framework splits products
into three games:

- **Attention game:** value comes from time people choose to spend. Social, content, games, media.
- **Transaction game:** value comes from completed transactions. E-commerce, marketplaces, delivery,
  fintech.
- **Productivity game:** value comes from tasks done faster and better. SaaS, collaboration, developer
  tools, AI agents.

| Product type | Common goal metrics | Phase 1 reading | Common guardrails |
|---|---|---|---|
| E-commerce / retail | Conversion rate, revenue per visitor, repeat purchase | Share of visitors who reach the order confirmation page, or click "Place order" | Refund rate, page speed |
| Two-sided marketplace | Transactions, match rate | Share of searchers who reach the booking confirmation | Cancellation rate |
| Local services / delivery | Orders, order frequency | Share of visitors who reach the order confirmation | Delivery time |
| Social media | Active users, interactions per user | Share of visitors who submit a post form | Reports, blocks |
| Content / streaming | Time spent, returning readers | Share of readers with a long engaged visit; return rate | Churn |
| Games | Day-1 / day-7 return | Return rate on the game's rhythm | Payment complaints |
| B2B SaaS | Weekly active teams, trial-to-paid | Share of trial visitors who click "Upgrade" | Support load |
| Collaboration / productivity | Core tasks completed per week | Share of visitors who finish the core task | Performance |
| Developer tools / APIs | Active developers, time to first success | Share of sign-ups who reach the "first call succeeded" page | Error rate |
| Education / habit-forming | Lessons completed, streaks | Share of learners who finish a lesson; weekly return | Learning outcomes |
| AI assistants / agents | Weekly active users, task success | Share of visitors who download or copy a result | Wrong-answer reports |

The company examples behind this table (Airbnb nights booked, Snap daily users, Stripe payment volume)
come from those companies' public disclosures.

## A.4 Two rules
1. **The company North Star is not the feature goal.** Company metrics such as daily active users or
   gross merchandise value move too slowly for one feature to shift them in a few weeks. Pick a
   feature-level goal that is known to drive the North Star — for a new posting tool in a social app,
   the share of visitors who post with it.
2. **Attention products must avoid "more is always better."** Optimizing purely for time spent leads
   to clickbait and compulsive use. Pair an engagement goal with a quality guardrail.

## A.5 Writing the plan
- **Find out before you write.** Read the public pages the person names (with your own web fetch) and look
  at the screenshots they attach. With Tracking connected, `get_tracking_state` says what the code
  already sends and whether Autocapture is installed.
- **With BigQuery connected, look at the data before you write.** When the project's state says
  BigQuery is connected and the GA4 export is there with daily tables, query it with Google's BigQuery MCP
  (`execute_sql_readonly`), and then:
  1. run Query 0 (the GA4 export SQL reference) on the last 14 days of the export (every day it has,
     when it has fewer) BEFORE you write any other query, and build "How each action is recognized",
     the production hostnames and every `actions` row from what it returns: the real button labels, ids,
     forms and pages, each marked "seen in the data". Add `page_view` and its path to it when a metric
     counts a page, so the path is one the data has. An action the data does not show yet stays "seen
     on the website" or "confirm with code";
  2. write every query against the real dataset and hostnames, check each one with
     check_metric (a dry run as this project's own account; nothing is saved), fix what it rejects, and only then write
     `Status: dry run passed on <date>`. A query that was not checked says `not run yet — <why>`;
  3. say in each query's first comment lines what really happened to it (A.6, "The evidence each
     query states").
  With no BigQuery connection, or no export yet, the queries keep their placeholders and say so.
- **Before the first draft, ask on ONE question card** (the question tool: every question on one card,
  and the same turn goes on with the answers). Look at the product first, so the options are its own.
  The questions, and only these (a design partner wanted to be guided, not handed a finished
  plan):
  1. **The goal** — the one main thing this plan should track, with two to four likely answers from
     what you saw (daily active users, purchases, sign-ups, bookings…).
  2. **Besides the goal**, what else they care about, several allowed: the user journey from its first
     step to the goal (in a shop, from viewing an item to buying it), performance (how fast pages load,
     how often errors happen), and any other area this product suggests.
  3. **Any other metric** they already know they want.

  When the scenario is not clear from the request, ask one more question on the same card: which kind of
  plan this is, with the two or three likely scenarios (the scenarios reference).

  Ask only what they have not said: leave out a question their message already answers, and ask nothing
  when it answers all three or they asked for the plan without questions. Never ask for something a tool
  can find out. The answers decide the plan: the goal is the Goal row; a journey they chose is the Core
  workflow; performance is a Quality row where a signal the plan uses can see it (A.0), and otherwise a
  line under the table saying what it would need. Declined or left blank: choose sensibly and say what
  you assumed. A change to a saved plan asks nothing first.
- **Say what each fact is based on**, and give each action in "How each action is recognized" a
  confidence: seen on the website, seen in the data, inferred from screenshots, or confirm with code. A
  public page can prove a Google tag is loaded; screenshots cannot. Neither proves where a server-side
  success happens (a payment confirmed, an account created): mark it "confirm with code".
- **Before launch, not after.** Tracking added after launch loses the first days for good, and the GA4
  export to BigQuery holds data only from the day it is switched on. Both belong to the launch
  checklist.
- **Partial rollouts.** When a launch first goes to a share of people, the goal is best read as exposed
  minus control — but only if the site already records the group or the person asks to add it (A.0).
  Otherwise say in the TL;DR that the numbers cover everyone.
- **One plan per launch, named after it**: "[Launch name] · Measurement Plan". The events part is
  called Tracking, never "Logging", and the name is never shortened to "MP" (GA4 already has a
  Measurement ID and a Measurement Protocol).
- **A living document.** Every change is a new version, made by editing the parts that change
  (several sections in one edit when one request touches them). A plan saved under the earlier
  template (`## Launch brief` … `## Verification and owners`) stays valid and is edited in its own
  shape; it moves to this template only when the person asks.

## A.6 Demo SQL and the metrics
**Every query in a plan is Demo SQL until it has run on this project's data.** With the GA4 export
linked (`ga4Export` in the project's state), it reads that dataset's `events_*` and the project's own
hostnames; only what is not known yet is a placeholder (the dataset when no export is linked, a page, a
button's text), and every block says so in its first line (`-- DEMO SQL · Query 1 · …`). The `## BigQuery queries` section says
where it stands: `Status: not run yet — <why>`, or, once BigQuery is connected and the placeholders are
replaced, what really ran, each part from a tool's answer: `Status: Query 0 ran on <date> over <N> days;
dry run passed on <date>`. Never write that a query works unless a tool said so.

**The evidence each query states.** The label stays `DEMO SQL`: nobody has read the numbers yet. The
comment lines after it say what really happened to THAT query, in plain words with dates: Query 0 ran
(when, over how many days), the dry run passed (when), or not run and why (no BigQuery connection, no
export yet, or the dry run's refusal in BigQuery's words). The same two lines, for a project before and
after its export is linked; read them for what they say, and write your own from what your tools said:

```sql
-- No export yet (Example A): nothing has run, so the comment says so and names what to replace.
-- DEMO SQL · Query 1 · Purchase-click rate: one row per day (day, value), in percentage points.
-- Not run on your data yet. Replace the dataset, the hostnames, and the page and button text in `actions`.

-- The export linked, Query 0 run and every query dry-run: the comment says that, and where its values came from.
-- DEMO SQL · Query 1 · [the metric]: one row per day (day, value), in percentage points.
-- Dry run passed on [date]. Its page and button are what Query 0 found on [date] over [N] days: [path], "[label]".
```

A plan whose export is linked and whose queries still say "Not run on your data yet" has skipped Query 0
and the dry runs: run them, then write the plan.

**One query per metric, named like it.** Every Core metrics row has its query in `## BigQuery queries`,
headed with the row's exact name (`### Query 1 · Purchase-click rate`): one read-only statement that
returns `day` (a DATE) and `value`, one row per day between `@start_suffix` and `@end_suffix`; a funnel
returns `day`, `step` and `value`. Saving the plan makes each row a metric of the project and its query
that metric's SQL, computed every day once BigQuery's check of it passes. A rate is in percentage points (28.7 means
28.7%). Date a return rate by the day people come back (of the new people of N days earlier, the share
back that day): dated by the first visit, a day would stay blank for N days and is never computed again.
The metric templates are where a query starts.

**And its breakdown, named like it with ` · breakdown`.** Right after a row's query comes
`### Query 1 · Purchase-click rate · breakdown`: one read-only statement over the same days that takes
`@dimension` and returns one row per value of it over the whole range, `dimension_value` and `value` (at
most one more count column; a funnel `dimension_value`, `step` and `value`), the largest first. The line
under its heading names the keys it answers, from the closed list (the GA4 export SQL reference §15):
`Dimensions: source, country, device_category`. Choose the ones that fit the metric, as GA4's own reports
split: a page (`page`) where it counts pages, a source, a location and a device. `source`, `country` and
`device_category` are each one field of the event; `channel` and `landing_page` are worked out per
session (§11, §13; the metric templates' Shared breakdown blocks) and make the statement much longer, so
use them where the plan's question is about channels or landing pages. Write it from the metric's own
query: each row gets its value of `@dimension`, and it is grouped by that value instead of by day.
Saving the plan gives the metric this breakdown once BigQuery's check accepts it; one it refuses, or a key
not on the list, leaves the metric without a breakdown and changes nothing else.

**A funnel names its steps.** A row drawn as a funnel has a query returning `day`, `step` and `value`, and
the line under its heading names the steps in the order the query numbers them from 1, for example
`Steps: Viewed pricing → Clicked "Start free trial" → Clicked Purchase`. Saving the plan makes that row a
funnel metric with those steps. A step that counts one GA4 event may say which, after its name:
`Clicked Purchase (event: auto_click)`. Then a step the site's code does not send yet is named on the
metric's page. Only `event:` makes it an event; other brackets are part of the name.

**Metrics.** `## Metrics` says who reads them and how often, what they answer and how fresh they are —
honestly: the GA4 daily export arrives the next day and keeps changing for up to three days. Each metric
is a line of its days, its latest day shown with the change from the one before; a funnel shows its
steps. Once Tartini AI has drawn the plan's Demo metric cards, code ends the section with
`Demo: [<title>](<the plan's own link>#demo-metrics). Illustrative numbers drawn by Tartini AI from this plan and marked Demo.`

**Tables to build later.** The first metrics read the GA4 export directly. A table is suggested
only when the same queries will run every day and a definition has settled: a fact table of events at
one grain, a daily table per person. Each is a Tartini scheduled table: its `ds` is the GA4 reporting
day read from the shard (`PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)`), its projection is bounded by
`load_start` and `load_end`, and its full projection SQL is written as Demo SQL.

## A.7 The document template
The skeleton below is the structure every new plan follows. Square brackets are placeholders, not
example values. The headings are in English; the content is in the conversation's language.

````markdown
# [Launch name] · Measurement Plan
Scenario: [launch / landing_page / activation / checkout / retention_health / acquisition / experiment / small_change]

Project: [project] · Launch date: [YYYY-MM-DD, or "not set"] · Based on: [the pages, screenshots, code and data it was written from]

## TL;DR
[Two or three plain sentences: the one number this launch is judged by, the few numbers that explain it, and what the data can and cannot prove.]

- What we are launching: [one sentence]. Who gets it: [everyone / a share, the rest compared against them / a group].
- Who it is for: [the people].
- The main workflow: [step → step → step].
- When people first get value: [the moment].
- How it makes money: [purchase / subscription / booking / ads / "not directly: why"].
- How we will judge it: [the goal metric, in words].

## Core metrics
| Metric | Role | What it tells us | How it is calculated | Data source |
|---|---|---|---|---|
| [the goal, a rate] | Goal | [the question, in plain words] | [who ÷ who, over what time] | [in plain words] |
| [the main workflow, started → finished] | Core workflow | [the question] | [who ÷ who, over what time] | [in plain words] |
| [coming back, on the product's own rhythm] | Retention | [the question] | [who ÷ who, over what time] | [in plain words] |
| [only when it helps a decision] | [Traffic / Activation / Revenue / Quality / Other] | [the question] | [who ÷ who, over what time] | [in plain words] |

[Why this return window: one sentence.]
[Not in this first version: what, and why, in one sentence.]
[What a click or a page view can and cannot prove, in one sentence.]

## Metrics
Who reads them: [role, how often]. What they answer: [the decisions]. How fresh: [honestly].

| Metric | Chart | Split by |
|---|---|---|
| [a Core metrics row, its exact name] | [line / funnel] | [its breakdown's dimensions, in plain words: page, source, country, device…] |

[Once drawn — Demo: [the plan's demo metrics](link) — illustrative numbers drawn by Tartini AI from this plan and marked Demo.]

---

*Everything below is the implementation detail, for Tartini AI, engineers and the data team.*

## Tracking
[What is already collected. What to add first: Tartini Autocapture, when it is not installed.]

| Event | Source | Sent when | Parameters this plan reads |
|---|---|---|---|
| [event] | [GA4, automatic / Tartini Autocapture / Existing] | [when] | [parameters] |

### How each action is recognized
| Action | Event | Page path | Recognized by | Value | How sure |
|---|---|---|---|---|---|
| [action] | [event] | [regular expression] | [element_id / element_label / form_id] | [lowercase value] | [seen on the website / seen in the data / from screenshots / confirm with code] |

### Production hostnames
[The hosts that count; how previews are kept out.]

Not needed: [events GA4 or Autocapture send that this plan does not read, and why]. Privacy: [what is never sent]. GA4 setup: [custom dimensions and metrics, only for GA4's own reports]. How to check it works: [launch day, the next day].

## BigQuery queries
Every query below is **Demo SQL**: [what it was written from: this project's export and what Query 0 found, or placeholders where nothing is known yet].
Source: `[project].analytics_[property id].events_*` · Date range: `@start_suffix`, `@end_suffix` · Status: [Query 0 ran on YYYY-MM-DD over N days; dry run passed on YYYY-MM-DD / not run yet: why]

### Query 0 · Find the real buttons, forms and hostnames
```sql
-- DEMO SQL · Query 0 · … [ran on YYYY-MM-DD over N days / not run yet: why]
```

### Query 1 · [a Core metrics row, its exact name]
[A funnel only: Steps: [step 1] → [step 2] → [step 3]]
```sql
-- DEMO SQL · Query 1 · … one row per day: day, value
-- [dry run passed on YYYY-MM-DD / not run yet: why]
```

### Query 1 · [the same row's exact name] · breakdown
Dimensions: [the keys that fit it, e.g. `source`, `country`, `device_category`]
```sql
-- DEMO SQL · Query 1 · … breakdown: one row per value of @dimension over the range: dimension_value, value
-- [dry run passed on YYYY-MM-DD / not run yet: why]
```

## Tables to build later
[None for the first metrics, and why.] When the definitions have settled:

### Table 1 · [fct_… / agg_… / dim_…]
One row: […]. ds: […]. Refresh: […]. Columns: […].
```sql
-- DEMO SQL · the projection a Tartini scheduled table runs, between load_start and load_end
```

## Launch checklist
| When | Check | Owner |
|---|---|---|
| [before launch / launch day / next day / later] | [the check, specific] | [role] |

Design principle: if a metric does not change a launch decision, leave it out.
````

**What must stay, and what changes with the product or the request:**

| Section | What must stay (code checks the starred items) | What changes |
|---|---|---|
| `# [Launch name] · Measurement Plan` | ★ The title line; ★ `Scenario: <key>` under it (none: a launch); the one-line project / date / sources | The scenario |
| `## TL;DR` | The one number the launch is judged by; what the data can and cannot prove; plain words | Length, the brief lines' wording, the language |
| `## Core metrics` | ★ One table with a `Role` column; ★ exactly one Goal row; ★ the roles the scenario needs, for a launch at least one Core workflow row and one Retention row (a row that cannot be measured yet says `Not measured: <why>`); every row says who ÷ who, over what time; the data really exists | How many rows (five to ten, ideally about five); the return rhythm; whether Traffic, Activation, Revenue or Quality appear |
| `## Metrics` | Every card is a Core metrics row; who reads them and how fresh they are, said honestly (a plan saved before Metrics replaced Dashboards keeps `## Dashboards`) | The charts; what each is split by (its breakdown's dimensions) |
| `## Tracking` | Phase 1 (A.0); Autocapture first when it is not installed; every action = event + page + id, label or form; the production hostnames | Which actions; how sure each is |
| `## BigQuery queries` | Every Core metrics row has its query, named like it, returning `day` and `value` (a funnel's with its `Steps:` line), then its breakdown, named like it with ` · breakdown`, with its `Dimensions:` line, taking `@dimension` and returning `dimension_value` and `value`; every block says Demo SQL, and what really happened to it (Query 0 ran, dry run passed, or not run and why); one read-only statement each; dates as parameters; production hostnames only; `LIMIT 1` in every parameter subquery; a window not yet passed is NULL; rates in percentage points | How many queries; "Not included at your request" when the person wants no SQL |
| `## Tables to build later` | The metrics read the export directly first; a table needs a reason; its full projection SQL; `ds` is the GA4 reporting day | None, one or two tables |
| `## Launch checklist` | Export switched on before launch; Realtime checked on launch day; Query 0 and a dry run the next day; return rates read only after their window | The items, the owners (named by role) |

Another scenario keeps the sections its recipe needs; code checks each scenario's floor (the scenarios
reference). A plan never carries personal data: no email address, phone number or person's name. Owners
are named by role.

## A.8 Example A — a purchase flow (illustrative, not a real customer)
The complete plan below is an EXAMPLE of the template filled in for one product: a site that sells one
product, with a pricing page, a free trial button and a checkout. It was written before BigQuery was
connected, so its queries say they have not run; A.6 shows what they say once the export is linked and
Query 0 and the dry runs have run. Generalize its structure, its
plainness in Part 1 and its specificity in Part 2. Do not copy its names, numbers, pages, buttons,
return day or charts: the next product has its own.

````markdown
# New product launch · Measurement Plan
Scenario: launch

Project: example-store · Launch date: 2026-08-21 · Based on: the public website and the tracking already in place

## TL;DR
We will judge this launch by one number: the share of daily visitors who click Purchase. Five more numbers explain why it moves: page views, daily visitors, how many visitors start the main workflow, how many of them finish it, and how many new visitors come back a week later. A click on Purchase shows that someone wants to buy. It does not prove that a payment went through.

- What we are launching: the new product. Who gets it: everyone.
- Who it is for: first-time visitors deciding whether to buy.
- The main workflow: pricing page → "Start free trial" → checkout → "Purchase".
- When people first get value: when they finish the purchase flow.
- How it makes money: purchases.
- How we will judge it: the share of daily visitors who click Purchase.

## Core metrics
| Metric | Role | What it tells us | How it is calculated | Data source |
|---|---|---|---|---|
| Purchase-click rate | Goal | Are visitors trying to buy? | People who clicked Purchase ÷ daily visitors, each day | Clicks on "Purchase" |
| Page views | Traffic | Is the launch getting attention? | Pages viewed each day | Google Analytics page views |
| Daily visitors | Traffic | How many people come each day? | People who viewed at least one page that day | Google Analytics page views |
| Workflow start rate | Core workflow | Do visitors start the main workflow? | People who clicked "Start free trial" ÷ daily visitors, each day | Clicks on "Start free trial" |
| Workflow completion rate | Core workflow | Do people who start also finish? | People who clicked Purchase after "Start free trial" ÷ people who clicked "Start free trial", same day | Clicks on both buttons |
| Day-7 return rate | Retention | Do new visitors come back? | New visitors of 7 days earlier who visited again that day ÷ all new visitors of that earlier day, each day | First visits and page views |

Why day 7: people tend to compare for about a week before they buy, and come back to do it. Day 1 says little, and day 28 needs a month of data; either can be added later as its own metric.
Not in this first version: revenue and failed payments. Neither shows up in page views or button clicks.
About the Purchase click: it means someone tried to buy, not that they paid. If the website shows a "thank you" page after payment, counting visits to that page is closer to a real sale.

## Metrics
Who reads them: the product manager every morning for the first two weeks, and leadership once a week. What they answer: Is the launch reaching people? Do they finish the main workflow? Do new visitors come back? How fresh: updated once a day. Yesterday's numbers arrive the next afternoon, and the newest three days can still change a little.

| Metric | Chart | Split by |
|---|---|---|
| Purchase-click rate | Line, the latest day with its change from the day before | Source, country, device |
| Page views · Daily visitors | Lines | Page, source, country, device |
| Workflow start rate · Workflow completion rate | Lines | Source, device |
| Day-7 return rate | Line | Source, country, device |

Demo: [New product launch · Demo metrics](https://tartini.ai/measurement-plan.html?project=<the project's id>&plan=<the plan's id>#demo-metrics). Illustrative numbers drawn by Tartini AI from this plan and marked Demo.

---

*Everything below is the implementation detail, for Tartini AI, engineers and the data team.*

## Tracking
Already collected: Google Analytics 4 (GA4) is installed. It sends `page_view` on every page and `first_visit` on a person's first visit. Add first: Tartini Autocapture, one reviewed code change (a component loaded on every page). It sends three events through the site's own Google tag.

| Event | Source | Sent when | Parameters this plan reads |
|---|---|---|---|
| page_view | GA4, automatic | a page or route is viewed | page_location |
| first_visit | GA4, automatic | a person's first visit (per browser cookie) | — |
| auto_click | Tartini Autocapture | a click on a button, a link, or an element marked as one | page_path, element_id, element_label |
| auto_form_submit | Tartini Autocapture | a form is submitted (not proof that it succeeded) | not used by this plan |
| auto_page_engagement | Tartini Autocapture | an active stretch on a page ends | not used by this plan |

### How each action is recognized
| Action | Event | Page path | Recognized by | Value (lowercase) | How sure |
|---|---|---|---|---|---|
| Start the workflow | auto_click | `^/pricing/?$` | element_id, else element_label | `start-trial` · `start free trial` | Seen on the website |
| Purchase | auto_click | `^/checkout` | element_label | `purchase` | Seen on the website; confirm with Query 0 |

After the first day of data, run Query 0 and update this table and the `actions` rows in Queries 1, 4 and 5 and their breakdowns.

### Production hostnames
Count only `www.example.com` and `example.com`. Tartini's Website Preview and pull-request deployments send real GA4 events from other hostnames; Query 0 lists every hostname in the data. Every query filters on `device.web_info.hostname`.

Not needed: GA4's `scroll` (Autocapture already records scroll depth), and any new event or parameter (none was asked for). Privacy: Autocapture never reads what people type: it looks at an element's attributes, never its value, and sends the page path without the query string. GA4 setup: only for GA4's own reports, register element_label, element_id and form_id as event-scoped custom dimensions (not page_path: the Google tag sends it as GA4's own page path, so such a dimension stays empty), and engaged_time_seconds and max_scroll_depth as custom metrics; BigQuery needs none of this. How to check it works: on launch day, GA4 Realtime or DebugView shows page_view, first_visit, auto_click and auto_form_submit from the production hostname; the next day, Query 0 returns the real buttons, forms and hostnames.

## BigQuery queries
Every query below is **Demo SQL**: written before any data exists, with placeholders (`your-gcp-project.analytics_123456789`, the hostnames, the page paths and the button text), not yet run on this project's data. Once BigQuery is connected, Tartini AI replaces the placeholders, checks each query with a dry run and records the result here.
Source: `your-gcp-project.analytics_123456789.events_*`, the GA4 daily export (one table per day, dated in the property's time zone) · Date range: `@start_suffix`, `@end_suffix` ('YYYYMMDD', the metric's days) · Each metric's query returns `day` and `value`, one row per day, and its breakdown `dimension_value` and `value` over the range · Rates are percentage points (28.7 means 28.7%) · Status: not run yet — BigQuery is not connected.

### Query 0 · Find the real buttons, forms and hostnames (run first)
```sql
-- DEMO SQL · Query 0 · Find the real buttons, forms and hostnames. Run it first, once data arrives.
-- Not run on your data yet. Replace your-gcp-project.analytics_123456789 with the GA4 export dataset.
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

### Query 1 · Purchase-click rate
```sql
-- DEMO SQL · Query 1 · Purchase-click rate: one row per day (day, value), in percentage points.
-- Not run on your data yet. Replace the dataset, the hostnames, and the page and button text in `actions`.
WITH
actions AS (
  -- From "Tracking > How each action is recognized". Change these rows, not the query.
  -- A row matches its event, its page (a regular expression on the path) AND its button id, text or form id.
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('complete', 'auto_click', r'^/checkout', NULL, 'purchase', NULL)
  ])
),
ev AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    event_name,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1) AS page_frame,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name IN ('page_view', 'auto_click')
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')  -- production only, never previews
),
visitors AS (
  -- A view counts only in the top frame (the GA4 export SQL reference, §11).
  SELECT day, COUNT(DISTINCT user_pseudo_id) AS people
  FROM ev
  WHERE event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top'
  GROUP BY day
),
clicked AS (
  SELECT e.day, COUNT(DISTINCT e.user_pseudo_id) AS people
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.day
)
SELECT v.day, ROUND(100 * SAFE_DIVIDE(IFNULL(c.people, 0), v.people), 1) AS value
FROM visitors AS v
LEFT JOIN clicked AS c USING (day)
ORDER BY v.day
```

### Query 1 · Purchase-click rate · breakdown
Dimensions: `source`, `country`, `device_category`
```sql
-- DEMO SQL · Query 1 · Purchase-click rate · breakdown: one row per value of @dimension over the range
-- (dimension_value, value in percentage points, visitors). Not run on your data yet. Replace as in Query 1.
WITH
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('complete', 'auto_click', r'^/checkout', NULL, 'purchase', NULL)
  ])
),
ev AS (
  SELECT
    -- Each event's value of @dimension (the GA4 export SQL reference §12, §15); "(not set)" when it has none.
    IFNULL(NULLIF(CASE @dimension
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'country' THEN geo.country
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)') AS dimension_value,
    event_name,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1) AS page_frame,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name IN ('page_view', 'auto_click')
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
),
visitors AS (
  SELECT dimension_value, COUNT(DISTINCT user_pseudo_id) AS people
  FROM ev
  WHERE event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top'
  GROUP BY dimension_value
),
clicked AS (
  SELECT e.dimension_value, COUNT(DISTINCT e.user_pseudo_id) AS people
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.dimension_value
)
SELECT v.dimension_value, ROUND(100 * SAFE_DIVIDE(IFNULL(c.people, 0), v.people), 1) AS value, v.people AS visitors
FROM visitors AS v
LEFT JOIN clicked AS c USING (dimension_value)
ORDER BY visitors DESC
```

### Query 2 · Page views
```sql
-- DEMO SQL · Query 2 · Page views: one row per day (day, value).
-- Not run on your data yet. Replace the dataset and the hostnames.
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  COUNT(*) AS value
FROM `your-gcp-project.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
  AND event_name = 'page_view'
  -- A view counts only in the top frame (the GA4 export SQL reference, §11).
  AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
  AND device.web_info.hostname IN ('www.example.com', 'example.com')
GROUP BY day
ORDER BY day
```

### Query 2 · Page views · breakdown
Dimensions: `page`, `source`, `country`, `device_category`
```sql
-- DEMO SQL · Query 2 · Page views · breakdown: one row per value of @dimension over the range (dimension_value, value).
-- Not run on your data yet. Replace the dataset and the hostnames.
WITH ev AS (
  SELECT
    -- Each view's value of @dimension: its page's path (§3), else as in Query 1's breakdown.
    IFNULL(NULLIF(CASE @dimension
      WHEN 'page' THEN REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location' LIMIT 1),
        r'^[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*(/[^?#]*)')
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'country' THEN geo.country
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)') AS dimension_value
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'page_view'
    AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
)
SELECT dimension_value, COUNT(*) AS value
FROM ev
GROUP BY dimension_value
ORDER BY value DESC
```

### Query 3 · Daily visitors
```sql
-- DEMO SQL · Query 3 · Daily visitors: people who viewed at least one page that day (day, value).
-- Not run on your data yet. Replace the dataset and the hostnames.
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  COUNT(DISTINCT user_pseudo_id) AS value
FROM `your-gcp-project.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
  AND event_name = 'page_view'
  AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
  AND user_pseudo_id IS NOT NULL
  AND device.web_info.hostname IN ('www.example.com', 'example.com')
GROUP BY day
ORDER BY day
```

### Query 3 · Daily visitors · breakdown
Dimensions: `page`, `source`, `country`, `device_category`
```sql
-- DEMO SQL · Query 3 · Daily visitors · breakdown: people who viewed a page in the range, per value of @dimension
-- (dimension_value, value); one person can be in several rows. Not run on your data yet. Replace as in Query 3.
WITH ev AS (
  SELECT
    user_pseudo_id,
    IFNULL(NULLIF(CASE @dimension
      WHEN 'page' THEN REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location' LIMIT 1),
        r'^[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*(/[^?#]*)')
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'country' THEN geo.country
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)') AS dimension_value
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'page_view'
    AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
)
SELECT dimension_value, COUNT(DISTINCT user_pseudo_id) AS value
FROM ev
GROUP BY dimension_value
ORDER BY value DESC
```

### Query 4 · Workflow start rate
```sql
-- DEMO SQL · Query 4 · Workflow start rate: one row per day (day, value), in percentage points.
-- Not run on your data yet. Replace the dataset, the hostnames, and the page and button text in `actions`.
WITH
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('start', 'auto_click', r'^/pricing/?$', 'start-trial', 'start free trial', NULL)
  ])
),
ev AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    event_name,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1) AS page_frame,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name IN ('page_view', 'auto_click')
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
),
visitors AS (
  SELECT day, COUNT(DISTINCT user_pseudo_id) AS people
  FROM ev
  WHERE event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top'
  GROUP BY day
),
started AS (
  SELECT e.day, COUNT(DISTINCT e.user_pseudo_id) AS people
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.day
)
SELECT v.day, ROUND(100 * SAFE_DIVIDE(IFNULL(s.people, 0), v.people), 1) AS value
FROM visitors AS v
LEFT JOIN started AS s USING (day)
ORDER BY v.day
```

### Query 4 · Workflow start rate · breakdown
Dimensions: `source`, `device_category`
```sql
-- DEMO SQL · Query 4 · Workflow start rate · breakdown: one row per value of @dimension over the range
-- (dimension_value, value in percentage points, visitors). Not run on your data yet. Replace as in Query 4.
WITH
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('start', 'auto_click', r'^/pricing/?$', 'start-trial', 'start free trial', NULL)
  ])
),
ev AS (
  SELECT
    IFNULL(NULLIF(CASE @dimension
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)') AS dimension_value,
    event_name,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1) AS page_frame,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name IN ('page_view', 'auto_click')
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
),
visitors AS (
  SELECT dimension_value, COUNT(DISTINCT user_pseudo_id) AS people
  FROM ev
  WHERE event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top'
  GROUP BY dimension_value
),
started AS (
  SELECT e.dimension_value, COUNT(DISTINCT e.user_pseudo_id) AS people
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.dimension_value
)
SELECT v.dimension_value, ROUND(100 * SAFE_DIVIDE(IFNULL(s.people, 0), v.people), 1) AS value, v.people AS visitors
FROM visitors AS v
LEFT JOIN started AS s USING (dimension_value)
ORDER BY visitors DESC
```

### Query 5 · Workflow completion rate
```sql
-- DEMO SQL · Query 5 · Workflow completion rate: of the people who started, the share who clicked Purchase
-- after it on the same day. One row per day (day, value), in percentage points.
-- Not run on your data yet. Replace the dataset, the hostnames, and the pages and button text in `actions`.
WITH
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('start',    'auto_click', r'^/pricing/?$', 'start-trial', 'start free trial', NULL),
    ('complete', 'auto_click', r'^/checkout',   NULL,          'purchase',         NULL)
  ])
),
ev AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    event_name,
    event_timestamp,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'auto_click'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
),
per_person AS (
  SELECT e.day, e.user_pseudo_id,
         MIN(IF(a.action = 'start', e.event_timestamp, NULL))    AS first_start,
         MAX(IF(a.action = 'complete', e.event_timestamp, NULL)) AS last_complete
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.day, e.user_pseudo_id
)
SELECT day,
       ROUND(100 * SAFE_DIVIDE(COUNTIF(last_complete >= first_start), COUNTIF(first_start IS NOT NULL)), 1) AS value
FROM per_person
GROUP BY day
ORDER BY day
```

### Query 5 · Workflow completion rate · breakdown
Dimensions: `source`, `device_category`
```sql
-- DEMO SQL · Query 5 · Workflow completion rate · breakdown: of the people who started on a day, the share
-- who clicked Purchase after it that day, over the range, per value of @dimension (dimension_value, value in
-- percentage points, started). Not run on your data yet. Replace as in Query 5.
WITH
actions AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<action STRING, event_name STRING, path_re STRING,
                                    element_id STRING, element_label STRING, form_id STRING>>[
    ('start',    'auto_click', r'^/pricing/?$', 'start-trial', 'start free trial', NULL),
    ('complete', 'auto_click', r'^/checkout',   NULL,          'purchase',         NULL)
  ])
),
ev AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    IFNULL(NULLIF(CASE @dimension
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)') AS dimension_value,
    event_name,
    event_timestamp,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1) AS page_path,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'auto_click'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
),
per_person AS (
  SELECT e.day, e.dimension_value, e.user_pseudo_id,
         MIN(IF(a.action = 'start', e.event_timestamp, NULL))    AS first_start,
         MAX(IF(a.action = 'complete', e.event_timestamp, NULL)) AS last_complete
  FROM ev AS e
  JOIN actions AS a
    ON e.event_name = a.event_name
   AND REGEXP_CONTAINS(IFNULL(e.page_path, ''), a.path_re)
   AND (e.element_id = a.element_id OR e.element_label = a.element_label OR e.form_id = a.form_id)
  GROUP BY e.day, e.dimension_value, e.user_pseudo_id
)
SELECT dimension_value,
       ROUND(100 * SAFE_DIVIDE(COUNTIF(last_complete >= first_start), COUNTIF(first_start IS NOT NULL)), 1) AS value,
       COUNTIF(first_start IS NOT NULL) AS started
FROM per_person
GROUP BY dimension_value
ORDER BY started DESC
```

### Query 6 · Day-7 return rate
```sql
-- DEMO SQL · Query 6 · Day-7 return rate: for each day, of the new visitors of 7 days earlier (GA4's own
-- first_visit), the share who viewed a page that day. One row per day (day, value), in percentage points.
-- Dated by the day people come back, so each day's number is final once its data is.
-- Not run on your data yet. Replace the dataset and the hostnames.
WITH
first_visits AS (
  SELECT user_pseudo_id, MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(PARSE_DATE('%Y%m%d', @start_suffix), INTERVAL 7 DAY))
        AND FORMAT_DATE('%Y%m%d', DATE_SUB(PARSE_DATE('%Y%m%d', @end_suffix), INTERVAL 7 DAY))
    AND event_name = 'first_visit'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
  GROUP BY user_pseudo_id
),
visits AS (
  SELECT DISTINCT user_pseudo_id, PARSE_DATE('%Y%m%d', event_date) AS day
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'page_view'
    AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
)
SELECT
  DATE_ADD(f.first_day, INTERVAL 7 DAY) AS day,
  ROUND(100 * COUNTIF(v.user_pseudo_id IS NOT NULL) / COUNT(*), 1) AS value
FROM first_visits AS f
LEFT JOIN visits AS v
  ON v.user_pseudo_id = f.user_pseudo_id AND v.day = DATE_ADD(f.first_day, INTERVAL 7 DAY)
GROUP BY day
ORDER BY day
```

### Query 6 · Day-7 return rate · breakdown
Dimensions: `source`, `country`, `device_category`
```sql
-- DEMO SQL · Query 6 · Day-7 return rate · breakdown: of the new visitors whose day 7 is in the range, the
-- share back that day, per value of @dimension at their first visit (dimension_value, value in percentage
-- points, new_visitors). Not run on your data yet. Replace the dataset and the hostnames.
WITH
first_visits AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day,
    ANY_VALUE(IFNULL(NULLIF(CASE @dimension
      WHEN 'source' THEN LOWER(COALESCE(session_traffic_source_last_click.cross_channel_campaign.source,
        session_traffic_source_last_click.manual_campaign.source,
        IF(session_traffic_source_last_click.google_ads_campaign.campaign_id IS NULL, NULL, 'google')))
      WHEN 'country' THEN geo.country
      WHEN 'device_category' THEN device.category
    END, ''), '(not set)')) AS dimension_value
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(PARSE_DATE('%Y%m%d', @start_suffix), INTERVAL 7 DAY))
        AND FORMAT_DATE('%Y%m%d', DATE_SUB(PARSE_DATE('%Y%m%d', @end_suffix), INTERVAL 7 DAY))
    AND event_name = 'first_visit'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
  GROUP BY user_pseudo_id
),
visits AS (
  SELECT DISTINCT user_pseudo_id, PARSE_DATE('%Y%m%d', event_date) AS day
  FROM `your-gcp-project.analytics_123456789.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND event_name = 'page_view'
    AND IFNULL((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1), 'top') = 'top'
    AND user_pseudo_id IS NOT NULL
    AND device.web_info.hostname IN ('www.example.com', 'example.com')
)
SELECT
  f.dimension_value,
  ROUND(100 * COUNTIF(v.user_pseudo_id IS NOT NULL) / COUNT(*), 1) AS value,
  COUNT(*) AS new_visitors
FROM first_visits AS f
LEFT JOIN visits AS v
  ON v.user_pseudo_id = f.user_pseudo_id AND v.day = DATE_ADD(f.first_day, INTERVAL 7 DAY)
GROUP BY f.dimension_value
ORDER BY new_visitors DESC
```

## Tables to build later
None for the first metrics: every query above reads the GA4 export directly. Build these when the definitions have settled and the same queries run every day. Both are Tartini scheduled tables: Google BigQuery refreshes them daily, re-reading the last three days each time (GA4 still adds late events to them), partitioned by `ds`.

### Table 1 · fct_events
One row: one GA4 event on the production hostnames. ds: the GA4 reporting day, read from the export's table name with `PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)` (the same day as `event_date`), never a UTC date from `event_timestamp`. Refresh: replace the days in the refresh window; each GA4 daily table holds every event of its day. Columns: ds DATE (required), event_ts TIMESTAMP, event_name, user_pseudo_id, session_id INT64, hostname, page_path, element_id, element_label, form_id (STRING), engaged_time_seconds, max_scroll_depth (INT64). `page_path` comes from Autocapture, or from `page_location` for GA4's own `page_view`, which has no path parameter.
```sql
-- DEMO SQL · Table fct_events · one row per GA4 event on the production hostnames.
-- ds = the GA4 reporting day (the property's time zone), read from the shard name.
-- Tartini declares load_start and load_end (days T-3 to T-1) for every daily run.
SELECT
  PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS ds,
  TIMESTAMP_MICROS(event_timestamp) AS event_ts,
  event_name,
  user_pseudo_id,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id' LIMIT 1) AS session_id,
  device.web_info.hostname AS hostname,
  COALESCE(
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_path' LIMIT 1),
    REGEXP_EXTRACT(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location' LIMIT 1),
      r'^[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*(/[^?#]*)')
  ) AS page_path,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
  LOWER(TRIM((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1))) AS element_label,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id,
  (SELECT COALESCE(value.int_value, SAFE_CAST(value.double_value AS INT64))
     FROM UNNEST(event_params) WHERE key = 'engaged_time_seconds' LIMIT 1) AS engaged_time_seconds,
  (SELECT COALESCE(value.int_value, SAFE_CAST(value.double_value AS INT64))
     FROM UNNEST(event_params) WHERE key = 'max_scroll_depth' LIMIT 1) AS max_scroll_depth
FROM `your-gcp-project.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', load_start) AND FORMAT_DATE('%Y%m%d', load_end)
  AND device.web_info.hostname IN ('www.example.com', 'example.com')
```

### Table 2 · fct_user_days
One row: one visitor on one day with a visit. `first_visit` is true on the visitor's first day. Refresh: replace the days in the refresh window; the projection aggregates whole daily tables. Any return window (day N, week N) is computed when the table is read, so a window that has not passed is never stored as "did not return".
```sql
-- DEMO SQL · Table fct_user_days · one row per visitor per day with a visit on the production hostnames.
-- first_visit = true on the visitor's first day (GA4's own first_visit event).
-- Any return window (day N, week N) is computed when the table is read, so nothing here is fixed to 1/7/28.
SELECT
  PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS ds,
  user_pseudo_id,
  LOGICAL_OR(event_name = 'first_visit') AS first_visit,
  COUNTIF(event_name = 'page_view') AS pageviews
FROM `your-gcp-project.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', load_start) AND FORMAT_DATE('%Y%m%d', load_end)
  AND event_name IN ('first_visit', 'page_view')
  AND user_pseudo_id IS NOT NULL
  AND device.web_info.hostname IN ('www.example.com', 'example.com')
GROUP BY ds, user_pseudo_id
```

When the tables exist, Queries 1–6 can read them instead of the export, keeping `day` and `value`.

## Launch checklist
| When | Check | Owner |
|---|---|---|
| Before launch | Turn on the GA4 → BigQuery daily export. It holds data only from the day it is turned on; a standard GA4 property exports up to 1 million events a day. | Engineering |
| Before launch | Merge Tartini Autocapture and confirm it loads on every page. | Engineering |
| Launch day | GA4 Realtime or DebugView shows page_view, first_visit, auto_click and auto_form_submit from the production hostname. | Engineering |
| Next day | Run Query 0. Update "How each action is recognized" and the `actions` rows in Queries 1, 4 and 5 and their breakdowns to the real values. | Data |
| Next day | Dry-run Queries 1–6 and their breakdowns, and record the result under BigQuery queries; each metric whose check passes is computed from then on. | Tartini AI |
| Every read | Treat the newest three days as provisional: GA4 keeps updating a day's table for up to three days. | Data |
| From day 8 | The day-7 return rate starts a week after launch: before that, no new visitor's day 7 has come. | Product manager |
| Always | A Purchase click is a click: never report it as revenue or a paid order. | Product manager |

Design principle: if a metric does not change a launch decision, leave it out.
````

## A.9 Example B — what changes for a different product
The same structure for a deliberately different product: a free AI avatar generator (upload a photo,
get avatars, download one). Only the differences are listed; read them as the kind of change every new
product needs.

| | Example A: a purchase flow | Example B: a free AI avatar generator |
|---|---|---|
| Goal | Share of daily visitors who click Purchase | Share of weekly visitors who download at least one avatar (a click on "Download" on the results page) |
| Core workflow | "Start free trial" → "Purchase" | Upload a photo (a submitted form) → the results page → "Download" |
| Quality | Not a row: no failure is visible on the website | Generation failure rate: views of the error page ÷ uploads |
| Retention | Day 7 | Week 1 and week 4, each its own metric: people change avatars on a weekly rhythm |
| Revenue | Not a row | Not a row: a free beta |
| Number of metrics | Six | Five |
| Split by | Source, country, device | Source, device |
| Tables to build later | `fct_events`, `fct_user_days` once the definitions settle | None: the export answers every question for now |

What carries over: the TL;DR's one number and what it cannot prove, the Role column, a funnel of the
main workflow, a return rate on the product's own rhythm, every metric with its complete query, the
production hostnames, the launch checklist. Both are launches; another scenario changes more (the
scenarios reference). What does not carry over: every name, button, page, window and number.

## A.10 Before you save the draft
Read the draft once against these questions, and fix what fails before calling `draft_measurement_plan`:

1. Could a busy executive read Part 1 without meeting an event name, a parameter or a SQL word?
2. Is there exactly one goal, and is it a rate? Are there five to ten metrics, ideally about five? Is
   there no target the person did not ask for?
3. Does the return window follow this product's rhythm, and does the plan say why?
4. Is every action recognized by event + page + id, label or form, on the production hostnames — and
   is nothing in it a business event nobody asked for (A.0; an acquisition plan may propose its one
   conversion event)?
5. Does every Core metrics row have its query, named exactly like it, returning `day` and `value`,
   labelled Demo SQL, one read-only statement, with `LIMIT 1` in every parameter subquery and rates in
   percentage points? And its breakdown, `… · breakdown`, with a `Dimensions:` line of keys from the
   list, taking `@dimension`? Does a funnel's query name its `Steps:`?
6. Put your Core metrics table next to Example A's. If it is A's six rows in A's order with new names,
   A's return day (7, for a product nobody comes back to within a week), or A's table titles
   (`fct_events`, `fct_user_days`), you copied Example A: rebuild those parts from this product. Every
   name, page, button, window and title is this product's own.
7. Does the plan say what it could not see, and mark it "confirm with code"?
8. With BigQuery connected: did Query 0 run before the other queries were written, do the actions come
   from what it returned, did every query pass a dry run before the status says so, and does each
   query's first comment say what really happened to it?
9. Is the scenario under the title the right one, and does the plan hold what its recipe suggests?

## A.11 Sources
The method combines classic sources: **Lean Analytics** (Croll, Yoskovitz, 2013) for metrics by
business model and one metric that matters; **The North Star Playbook** (Amplitude) for the three
games and feature-level inputs; **Trustworthy Online Controlled Experiments** (Kohavi, Tang, Xu, 2020)
for goal, driver and guardrail and for control groups; **Google's HEART framework** (Rodden et al.,
2010) for adoption, task success and retention; **Avinash Kaushik's Digital Marketing & Measurement
Model** for objectives to KPIs. The document shape follows a product launch plan written by the
product team, adapted to Phase 1 and to Tartini AI's Demo metric cards.
=== end reference ===

=== REFERENCE (guidance, not a hard rule — ground in the real code): Measurement Plan scenarios and recipes · docs/measurement/measurement-plan-scenarios.md ===
## (intro)
# Measurement Plan scenarios and recipes

This is the second reference of the Measurement Plan guide. The plan reference says
how a plan is written and holds the template; this one says WHICH KIND of plan it is and what that kind
needs. A plan is not always a launch: a landing page has no "coming back", an experiment needs its
guardrails and its duration, a small change needs only its tracking.

The order of precedence is the plan reference's: what the person asked for, then the project's real
state, then these recipes. A recipe is an example to reason from, never a lookup table: two products of
the same scenario still get different plans, and a product that fits two scenarios takes the one its
goal belongs to and says the other in its TL;DR. Phase 1 (plan reference A.0) governs every recipe, with
the one exception stated under Acquisition.

## Recognise the scenario first
Before writing, decide which of these eight the request is, from what the person said and what you can
see (the site, the code, the data). When it is genuinely unclear, ask it as one more question on the one
question card (plan reference A.5), with two or three likely answers; the person may change it at any
time. Write the key on the line under the title:

```markdown
# Spring landing page · Measurement Plan
Scenario: landing_page
```

| Key | The scenario | Its tell |
|---|---|---|
| `launch` | A product or feature launch | Something new ships and people should use it and come back |
| `landing_page` | A landing page or lead capture | One page whose job is a sign-up, a form or a waiting list |
| `activation` | New-user activation | People sign up but do not reach the moment the product first helps them |
| `checkout` | Checkout and e-commerce | Products, a cart, a payment |
| `retention_health` | A retention health check of an existing product | Nothing is launching: is the product keeping its people? |
| `acquisition` | Marketing and acquisition | Ads, campaigns or channels bring people, and the question is which ones work |
| `experiment` | An A/B experiment | Two or more versions are compared on purpose |
| `small_change` | A small change | One button, one form, one fix: a whole plan would be noise |

A plan with no Scenario line is a launch (every plan saved before scenarios existed is one). A plan saved
under the earlier template has no scenario at all and is edited in its own shape.

How big the plan is follows what changed (an idea from Amplitude's open `diff-intake` skill, MIT): a
refactor or a rollback needs no plan, only a line that the tracking still works; a bug fix or a small
improvement is a `small_change`; a performance change is a `small_change` with a speed or error
guardrail, or an `experiment` when it is rolled out to a share of people; a new feature or product is a
`launch` or an `activation` plan.

## What every plan needs, and what is a module
Every plan except a small change has three things, and code checks them: a goal in one or two sentences
(`## TL;DR`), one main metric that is a rate (exactly one `Goal` row in `## Core metrics`), and its
tracking (`## Tracking`). Everything else is a MODULE the scenario adds: a funnel, retention, revenue,
source and campaign, an experiment, quality, the Metrics section, the BigQuery queries, tables to build
later, a launch checklist.

What code checks, per scenario (`app/measurement-plan-markdown.js` `SCENARIO_RULES`; structure only,
never which metric a product needs):

| Scenario | Sections code requires | Core metrics roles code requires |
|---|---|---|
| `launch` | every template heading: TL;DR, Core metrics, Metrics, Tracking, BigQuery queries, Tables to build later, Launch checklist | Goal, Core workflow, Retention |
| `landing_page` | TL;DR, Core metrics, Tracking | Goal, Core workflow, Traffic |
| `activation` | TL;DR, Core metrics, Tracking | Goal, Core workflow |
| `checkout` | TL;DR, Core metrics, Tracking | Goal, Core workflow, Revenue |
| `retention_health` | TL;DR, Core metrics, Tracking | Goal, Retention |
| `acquisition` | TL;DR, Core metrics, Tracking | Goal, Traffic |
| `experiment` | TL;DR, Core metrics, Tracking, Experiment (with a `Duration:` line) | Goal, Guardrail |
| `small_change` | Tracking only; no Core metrics table | none |

"Required" is the floor, not the plan: write every module the recipe below suggests unless the person
asked for less. A plan for anything but a small change normally keeps `## Metrics`, `## BigQuery queries`
and `## Launch checklist`, because they are what the person checks and what becomes the project's
metrics. `## Metrics` opens by answering four questions (after Amplitude's `create-dashboard`, MIT): who
reads it, which decision it helps, how often, and how fresh the numbers are. Headings and role words stay in English; the content is in the conversation's language.

## The metric tree
Lay the metrics out as a tree (an idea from Amplitude's and Mixpanel's metric trees; the words are ours):

- **The goal** on top: the one rate the plan is judged by, the `Goal` row.
- **Drivers** under it: the faster numbers that explain it: the workflow's steps (`Core workflow`),
  activation, retention, traffic by source.
- **Guardrails** beside it: what must not get worse while the goal is chased: errors, page speed,
  refunds, unsubscribes (`Quality`, or `Guardrail` in an experiment).

Every metric says who ÷ who, over what time, and where the data comes from, in plain words. Saving the
plan makes each Core metrics row a metric of the project; a `### Query N · <the metric's name>`
in `## BigQuery queries` that returns `day` and `value`, one row per day, over `@start_suffix` and
`@end_suffix`, becomes its SQL, computed every day once its check passes (a funnel's names its steps on a
`Steps:` line). The `### Query N · <the metric's name> · breakdown` after it, with its `Dimensions:` line,
becomes its breakdown (the plan reference A.6). The metric templates (the Metrics reference this guide
also carries) are where such a query starts. A recipe's **Dimensions** are what its breakdowns split by,
as keys of the closed list (device is `device_category`, first page `landing_page`, product category
`item_category`, new or returning `user_type`); a split the list does not have (a sign-up week, an
experiment's group) is a question for Tartini AI, not a key.

## Events: four kinds, three priorities
Sort the candidate signals into four kinds, and order them by priority (after Amplitude's open
`discover-event-surfaces` skill, MIT):

1. **Business outcomes**: the result itself: an order, a lead, a sign-up.
2. **User journey**: the steps on the way: a product page seen, the form started, checkout begun.
3. **Feature success**: the feature did its job: a file exported, a search that returned results.
4. **Failure and stuck**: what went wrong: an error page, a form abandoned, a payment declined.

Three priorities: **P1** is needed for the goal and its funnel, **P2** explains a driver, **P3** is nice
to have. A funnel's first and last step are always P1; the steps between are added by the flow's length,
none for a two-step flow and up to three for a long one. Less is more: a plan that lists every possible
signal reads none of them well. A small change usually needs one or two P1 signals.

In Phase 1 each of these is read from GA4's own events, Tartini Autocapture and the events the code
already sends (plan reference A.0): an order is a view of its confirmation page, a lead an
`auto_form_submit` of its form or a view of its thank-you page, a stuck step an error page's view. GA4's
recommended events (Google's documentation, text CC BY 4.0: `generate_lead`, `sign_up`, `begin_checkout`,
`purchase` …) are the names to use when the person asks for a business event.

## Choosing the metric templates
The metric templates come in two versions: without ads (all traffic), and the rows added when the site
runs ads; and a lead variant for a business with no purchase. Choose from the facts, never by default:

- **Google Ads runs** (the person says so, the site loads the Ads tag, landing pages carry `gclid`, or the
  export shows paid search): use the version with ads, and add one checklist step, "Link Google Ads to
  BigQuery (the Data Transfer Service)", before any Ads metric can be read.
- **Paid traffic from other platforms only**: use the version with ads without its Google Ads rows (spend,
  Ads conversions, cost per conversion, the conversion gap, auto-tagging).
- **No paid traffic**: the version without ads.
- **No purchase** (leads, sign-ups, bookings by form): the lead variant: `generate_lead` or `sign_up`, or
  their Phase 1 reading, in place of `purchase`; no revenue, no average order value, no return on ad spend.

A template is a starting point: fill its placeholders from this project (the export, its pages, its
buttons, its conversion event), check it, and say what it counts.

## The recipes
Each recipe: the main metric (the Goal row) to choose from, the drivers and guardrails, the signals, the
dimensions people usually split by, the modules to write and the usual mistakes.

### launch: a product or feature launch
The plan reference's template and Example A are this recipe, whole.

- **Goal**: the share of the target people who finish the core action, per day or week.
- **Drivers**: the workflow funnel (started → finished), return on the product's own rhythm, activation
  when first value comes later than finishing. **Guardrails**: the failure path, if one is visible.
- **Signals**: the pages and buttons of the main workflow (Autocapture), the first visit.
- **Dimensions**: source, country, device (first page and channel when the person asks for them).
- **Modules**: all of the template.
- **Mistakes**: judging a launch by page views; a 7-day return for something bought twice a year.

### landing_page: a landing page or lead capture
- **Goal**: the share of visitors who submit the form or sign up (submitted ÷ visitors of the page).
- **Drivers**: visitors by channel and campaign (the `Traffic` row), the funnel from the page to the main
  button to the form started to the form submitted to the thank-you page (`Core workflow`).
  **Guardrails**: page speed, form errors. No retention row: a landing page has nobody coming back yet.
- **Signals**: the page's `page_view`, `auto_click` on the main button, `auto_form_submit`, the
  thank-you page's view. A submit is the browser's event, not proof the lead was stored: say so.
- **Dimensions**: channel, campaign (UTM), first page (the landing page), device.
- **Modules**: Metrics, BigQuery queries, Launch checklist; usually no tables.
- **Mistakes**: counting form submits as leads; reading the source of the session rather than of the
  visit that landed (the GA4 export SQL reference says which field).

### activation: new-user activation
- **Goal**: the share of new people who reach the first-value moment within N days of signing up, N set
  from the product (a day for a tool used daily, a week for one used weekly).
- **Drivers**: each step's conversion from sign-up to first value, and the time it takes (`Core
  workflow`, with its window said). **Guardrails**: the failure path of the step that most often stops
  people.
- **Signals**: the sign-up's thank-you page or form, the page or button that IS the first value (an
  export, a first report, a first booking).
- **Dimensions**: sign-up week, first channel, device.
- **Modules**: Metrics, BigQuery queries, Launch checklist.
- **Mistakes**: calling a sign-up activation; a window copied from another product.

### checkout: checkout and e-commerce
- **Goal**: the share of visitors who complete a purchase (purchases ÷ visitors or sessions, per day).
- **Drivers**: the funnel: product page, add to cart, checkout begun, purchase (`Core workflow`), revenue
  and average order value (`Revenue`). **Guardrails**: refunds, payment errors, page speed.
- **Signals**: in Phase 1, the product pages' views, clicks on "Add to cart" and "Checkout", the order
  confirmation page; the site's own `purchase` if its code sends one. Revenue is readable only from an
  event that carries `value` (a `purchase` with `transaction_id`, `value`, `currency` and `items`); with
  none, the Revenue row says `Not measured: <why>`.
- **Dimensions**: device, channel, product category, new or returning.
- **Templates**: Version 1's Purchases, Revenue, Average order value and Conversion funnel.
- **Modules**: Metrics, BigQuery queries, Launch checklist; a `fct_` table once the definitions settle.
- **Mistakes**: counting a "Place order" click as revenue; one purchase counted twice (each
  `transaction_id` once).

### retention_health: a retention health check of an existing product
- **Goal**: the return rate on the product's own rhythm (the share of last period's active people active
  again this period).
- **Drivers**: new people, returning people, people who came back after a gap, people gone quiet.
  **Guardrails**: none needed unless a failure path is visible.
- **Signals**: GA4's `first_visit` and `page_view`, the core action's page or button.
- **Dimensions**: first-visit month, first channel, device.
- **Modules**: Metrics, BigQuery queries; no launch checklist (nothing launches); a daily-per-person table
  when the same retention query runs every day.
- **Mistakes**: a calendar window that ignores the product's rhythm; a period whose window has not
  passed shown as zero.

### acquisition: marketing and acquisition
- **Goal**: the conversion rate per channel (conversions ÷ visitors, split by channel and campaign).
- **Drivers**: visitors by channel, by first page (the landing page) and by campaign (`Traffic`); with
  ads, spend, cost per conversion and return on ad spend. **Guardrails**: engagement of paid visits
  (paid traffic that leaves at once is bought, not won).
- **Signals**: the session's source (the GA4 export SQL reference says which field, and which days need
  another), the conversion's page view or form, Google Ads' own numbers when they are in BigQuery.
- **Dimensions**: default channel group, source and medium, campaign, first page, device, country.
- **Templates**: choose the version from the facts above (Choosing the metric templates).
- **The one exception to Phase 1**: an advertising or acquisition plan may recommend ONE conversion
  event: the one the ads optimise for: `generate_lead`, `sign_up`, or `purchase` with `transaction_id`,
  `value`, `currency` and `items`. Say in one sentence why (an ad platform optimises only for an event it
  receives); it is written into the Draft only after the person agrees, and it goes through the Pull
  Request as usual. Every other signal stays Phase 1.
- **Modules**: Metrics, BigQuery queries, Launch checklist (with the Google Ads link step when it applies).
- **Mistakes**: reading `traffic_source` (the person's FIRST source ever) as the session's; adding Google
  Ads' and GA4's conversions together (they count differently and never match: the GA4 export SQL
  reference says why).

### experiment: an A/B experiment
- **Goal**: the experiment's primary metric: one rate, decided before it starts.
- **Drivers**: secondary metrics that explain a change. **Guardrails** (the `Guardrail` role, at least
  one): what must not get worse: errors, speed, revenue per visitor, unsubscribes.
- **Signals**: the primary metric's signals, and how each person's group is recorded: an event or a
  parameter the site already sends. When the site records no group, adding one is a business event the
  person must ask for (Phase 1); without it the plan cannot compare groups and says so.
- **The `## Experiment` section** says what is compared (control and each variant, who is in each, how
  they are split), the exposure (the page or event that puts a person in), the sample size needed to see
  the change that matters, and `Duration: <how long it runs>`: whole weeks, set before it starts, never
  stopped early because the number looks good.
- **Dimensions**: group first; device and channel only to check the split is fair.
- **Modules**: Metrics, BigQuery queries (the primary metric per group per day), Launch checklist.
- **Mistakes**: several primary metrics; reading the result every day and stopping when it looks good;
  a split that is not random.

### small_change: a small change
- **No Core metrics table and no goal row.** One or two P1 signals: did people use the changed thing,
  and did it work.
- **`## Tracking`** names the signal (Autocapture's click or form, or a page view), where it is
  recognised, and how to check it fires after the change merges. Add a TL;DR line only when it helps.
- **Mistakes**: a full plan for a button; a new business event where an Autocapture click answers it.

## Sources
Ideas, rewritten in our own words: Amplitude's `mcp-marketplace` skills (MIT): `diff-intake` (the size of
the analysis follows the change), `discover-event-surfaces` (the four kinds of event, three priorities,
the funnel's ends first), `create-dashboard` (who reads it, which decision, how often, which story: the four questions `## Metrics` opens with);
PostHog's templates and web analytics (MIT outside `ee/`): the metrics and dimensions of landing pages
and paid traffic; Amplitude's builder skills and Mixpanel's metric trees (no licence: the structure only).
GA4's recommended events: Google's documentation, text CC BY 4.0.
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
read_guide({ domain: "measurement_plan", section: "<heading>" }) returns any of them whole.
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