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

## Shared blocks

The two blocks every GA4 template and every GA4 breakdown starts with. A template's section names the
ones it needs; its own text follows them exactly as written.

### Shared GA4 block

One `WITH`, one fact per CTE: `raw` the production site's events of the days asked for (every
parameter read with `LIMIT 1`, the GA4 export SQL reference §3); `events` each event's page, view and
source (§11, §12); `ranked` its place in its session; `sessions` one row a session, after dbt-ga4's
sessions model (MIT); `traffic` the session's source (§12: the last click, else the first collected
source, a gclid alone being google / cpc as in dbt-ga4's `stg_ga4__events.sql`, else Direct); `channels`
GA4's default channel group (§11); `classified` Google Ads, paid, organic; `orders` one row per
`transaction_id`; `refunds` by day and order. BigQuery reads only the columns a statement uses, so the
unused ones cost nothing; the dry run reports the bytes. The 7-day template reads its first table from
`@lookback_start_suffix` instead of `@start_suffix`, and nothing else changes.

```sql
WITH raw AS (
  -- One row per event of the production site, from the days asked for.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    event_timestamp,
    event_name,
    user_pseudo_id,
    user_pseudo_id || '.' || CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id' LIMIT 1) AS STRING) AS session_key,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number' LIMIT 1) AS session_number,
    (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING)) FROM UNNEST(event_params) WHERE key = 'session_engaged' LIMIT 1) AS session_engaged,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location' LIMIT 1) AS page_location,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title' LIMIT 1) AS page_title,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_frame' LIMIT 1) AS page_frame,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_id' LIMIT 1) AS element_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'element_label' LIMIT 1) AS element_label,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id' LIMIT 1) AS form_id,
    is_active_user,
    device.web_info.hostname AS hostname,
    geo.country AS country,
    geo.region AS region,
    geo.city AS city,
    device.language AS language,
    device.category AS device_category,
    device.web_info.browser AS browser,
    device.operating_system AS os,
    device.operating_system_version AS os_version,
    device.mobile_model_name AS device_model,
    session_traffic_source_last_click AS last_click,
    collected_traffic_source AS collected,
    collected_traffic_source.gclid AS gclid,
    NULLIF(ecommerce.transaction_id, '(not set)') AS transaction_id,
    ecommerce.purchase_revenue AS purchase_revenue,
    ecommerce.refund_value AS refund_value,
    items
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND device.web_info.hostname IN ({{production_hosts}})
),
events AS (
  -- Each event's page path and whether it is a view (a page_view in the top frame); the session's last
  -- click as GA4 wrote it on the event (cross-channel, else manual, else google / cpc for a Google Ads
  -- campaign); and what the event was collected with (a manual source other than (direct), else
  -- google / cpc for a gclid alone, as dbt-ga4's stg_ga4__events.sql), for a session with no last click.
  SELECT
    *,
    IF(page_location IS NULL, NULL,
       IFNULL(NULLIF(REGEXP_EXTRACT(page_location, r'^[^:/]+://[^/?#]*([^?#]*)'), ''), '/')) AS page_path,
    (event_name = 'page_view' AND IFNULL(page_frame, 'top') = 'top') AS is_view,
    LOWER(CASE WHEN last_click.cross_channel_campaign.source IS NOT NULL THEN last_click.cross_channel_campaign.source
               WHEN last_click.manual_campaign.source IS NOT NULL THEN last_click.manual_campaign.source
               WHEN last_click.google_ads_campaign.campaign_id IS NOT NULL THEN 'google' END) AS lc_source,
    LOWER(CASE WHEN last_click.cross_channel_campaign.source IS NOT NULL THEN last_click.cross_channel_campaign.medium
               WHEN last_click.manual_campaign.source IS NOT NULL THEN last_click.manual_campaign.medium
               WHEN last_click.google_ads_campaign.campaign_id IS NOT NULL THEN 'cpc' END) AS lc_medium,
    CASE WHEN last_click.cross_channel_campaign.source IS NOT NULL THEN last_click.cross_channel_campaign.campaign_name
         WHEN last_click.manual_campaign.source IS NOT NULL THEN last_click.manual_campaign.campaign_name
         WHEN last_click.google_ads_campaign.campaign_id IS NOT NULL THEN last_click.google_ads_campaign.campaign_name END AS lc_campaign,
    last_click.google_ads_campaign.campaign_id AS ads_campaign_id,
    LOWER(CASE WHEN collected.manual_source != '(direct)' THEN collected.manual_source
               WHEN collected.gclid IS NOT NULL THEN 'google' END) AS ev_source,
    LOWER(CASE WHEN collected.manual_source != '(direct)' THEN collected.manual_medium
               WHEN collected.gclid IS NOT NULL THEN 'cpc' END) AS ev_medium,
    CASE WHEN collected.manual_source != '(direct)' THEN collected.manual_campaign_name END AS ev_campaign
  FROM raw
),
ranked AS (
  -- Each event's place in its session: its first event, its first view, its first event with a last
  -- click, its first event with a collected source.
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY session_key ORDER BY event_timestamp) AS event_rank,
    ROW_NUMBER() OVER (PARTITION BY session_key, is_view ORDER BY event_timestamp) AS view_rank,
    ROW_NUMBER() OVER (PARTITION BY session_key, lc_source IS NOT NULL ORDER BY event_timestamp) AS last_click_rank,
    ROW_NUMBER() OVER (PARTITION BY session_key, ev_source IS NOT NULL ORDER BY event_timestamp) AS collected_rank
  FROM events
  WHERE session_key IS NOT NULL
),
sessions AS (
  -- One row per session (after dbt-ga4's sessions model): its day is the day it started; its place,
  -- device and session number are its first event's; its landing page is the path of its first view.
  SELECT
    session_key,
    MIN(event_day) AS day,
    LOGICAL_OR(session_engaged = '1') AS engaged,
    LOGICAL_OR(gclid IS NOT NULL) AS has_gclid,
    LOGICAL_OR(lc_source IS NOT NULL) AS has_last_click,
    MAX(IF(lc_source IS NOT NULL AND last_click_rank = 1, lc_source, NULL)) AS lc_source,
    MAX(IF(lc_source IS NOT NULL AND last_click_rank = 1, lc_medium, NULL)) AS lc_medium,
    MAX(IF(lc_source IS NOT NULL AND last_click_rank = 1, lc_campaign, NULL)) AS lc_campaign,
    MAX(IF(lc_source IS NOT NULL AND last_click_rank = 1, ads_campaign_id, NULL)) AS ads_campaign_id,
    MAX(IF(ev_source IS NOT NULL AND collected_rank = 1, ev_source, NULL)) AS ev_source,
    MAX(IF(ev_source IS NOT NULL AND collected_rank = 1, ev_medium, NULL)) AS ev_medium,
    MAX(IF(ev_source IS NOT NULL AND collected_rank = 1, ev_campaign, NULL)) AS ev_campaign,
    MAX(IF(is_view AND view_rank = 1, page_path, NULL)) AS landing_page,
    MAX(IF(event_rank = 1, hostname, NULL)) AS hostname,
    MAX(IF(event_rank = 1, country, NULL)) AS country,
    MAX(IF(event_rank = 1, region, NULL)) AS region,
    MAX(IF(event_rank = 1, city, NULL)) AS city,
    MAX(IF(event_rank = 1, language, NULL)) AS language,
    MAX(IF(event_rank = 1, device_category, NULL)) AS device_category,
    MAX(IF(event_rank = 1, browser, NULL)) AS browser,
    MAX(IF(event_rank = 1, os, NULL)) AS os,
    MAX(IF(event_rank = 1, os_version, NULL)) AS os_version,
    MAX(IF(event_rank = 1, device_model, NULL)) AS device_model,
    MAX(IF(event_rank = 1, session_number, NULL)) AS session_number
  FROM ranked
  GROUP BY session_key
),
traffic AS (
  -- The session's source, medium and campaign: GA4's last click when any event carries it (from mid-July
  -- 2024), else its first collected source, else direct.
  SELECT
    s.*,
    CASE WHEN s.has_last_click THEN s.lc_source ELSE IFNULL(s.ev_source, '(direct)') END AS source,
    CASE WHEN s.has_last_click THEN s.lc_medium WHEN s.ev_source IS NOT NULL THEN s.ev_medium ELSE '(none)' END AS medium,
    CASE WHEN s.has_last_click THEN s.lc_campaign ELSE s.ev_campaign END AS campaign
  FROM sessions AS s
),
channels AS (
-- GA4's default channel group: the SQL block of the GA4 export SQL reference §11, whole.
),
classified AS (
  -- A Google Ads session: GA4 names its Google Ads campaign, or it carries a gclid. A paid session: that,
  -- or a paid channel. Organic search: the Organic Search channel.
  SELECT
    *,
    (ads_campaign_id IS NOT NULL OR has_gclid) AS google_ads,
    (ads_campaign_id IS NOT NULL OR has_gclid
      OR channel IN ('Paid Search', 'Paid Social', 'Paid Video', 'Paid Shopping', 'Paid Other', 'Display', 'Cross-network')) AS paid,
    (channel = 'Organic Search') AS organic
  FROM channels
),
purchases AS (
  -- Every purchase event with a transaction ID, numbered within its order.
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY event_timestamp) AS purchase_rank
  FROM events
  WHERE event_name = 'purchase' AND transaction_id IS NOT NULL
),
orders AS (
  -- One row per order (purchase's grain is transaction_id): its first purchase event's day, session,
  -- value and items.
  SELECT event_day AS day, transaction_id, session_key, purchase_revenue AS revenue, items
  FROM purchases
  WHERE purchase_rank = 1
),
refunds AS (
  -- What was refunded, by day and order.
  SELECT event_day AS day, transaction_id, SUM(refund_value) AS refunded
  FROM events
  WHERE event_name = 'refund' AND refund_value IS NOT NULL
  GROUP BY event_day, transaction_id
)
```

### Shared breakdown blocks

After the GA4 block. `session_bd` gives every session its value of `@dimension` (one `WHEN` per key of
S); user metrics add `event_bd` (a page and a page title are each event's own); order metrics add
`order_bd` and `item_bd` (one row per item; item revenue is GA4's price × quantity, before refunds,
shipping and tax). NULL and `''` are shown as "(not set)". The rows of a breakdown rarely add up to the
metric's number: one person has several sessions, a session several pages, an order several items.

```sql
, session_bd AS (
  -- Each session's value of @dimension. NULL and '' are shown as (not set).
  SELECT
    c.*,
    NULLIF(CASE @dimension
      WHEN 'landing_page' THEN c.landing_page
      WHEN 'hostname' THEN c.hostname
      WHEN 'channel' THEN c.channel
      WHEN 'source' THEN c.source
      WHEN 'medium' THEN c.medium
      WHEN 'campaign' THEN c.campaign
      WHEN 'country' THEN c.country
      WHEN 'region' THEN c.region
      WHEN 'city' THEN c.city
      WHEN 'language' THEN c.language
      WHEN 'device_category' THEN c.device_category
      WHEN 'browser' THEN c.browser
      WHEN 'os' THEN c.os
      WHEN 'os_version' THEN c.os_version
      WHEN 'device_model' THEN c.device_model
      WHEN 'user_type' THEN CASE WHEN c.session_number = 1 THEN 'New' WHEN c.session_number > 1 THEN 'Returning' END
    END, '') AS dimension_value
  FROM classified AS c
)
```

```sql
, event_bd AS (
  -- Page and page title are each event's own; every other dimension is its session's.
  SELECT
    e.event_day,
    e.user_pseudo_id,
    e.is_active_user,
    e.event_name,
    e.is_view,
    e.session_number,
    CASE @dimension
      WHEN 'page' THEN e.page_path
      WHEN 'page_title' THEN NULLIF(e.page_title, '')
      ELSE b.dimension_value
    END AS dimension_value
  FROM events AS e
  LEFT JOIN session_bd AS b USING (session_key)
)
```

```sql
, order_bd AS (
  -- Each order with its session's value of @dimension, and whether the session was paid or Google Ads.
  SELECT o.*, b.dimension_value, b.paid, b.google_ads
  FROM orders AS o
  LEFT JOIN session_bd AS b USING (session_key)
),
item_bd AS (
  -- One row per item of an order, by item name or category. Item revenue is GA4's price × quantity.
  SELECT
    o.transaction_id,
    i.item_revenue,
    NULLIF(CASE @dimension WHEN 'item_name' THEN i.item_name WHEN 'item_category' THEN i.item_category END, '') AS dimension_value
  FROM orders AS o
  CROSS JOIN UNNEST(o.items) AS i
)
```

### Days with no event

A count or an amount over GA4 events returns a row for EVERY day the export holds over the days asked for,
whatever that day's events: a quiet day is a true 0, and a day whose table has not landed (today, a gap in the
export) is no row at all, never a zero for a day nobody measured. Every count and amount template below does it
(Active users, New users, Returning users, Sessions, Organic search sessions, Purchases and Leads, Revenue, Ad
conversions, Revenue from ads, Paid sessions): its own statement is the `counted` CTE, then the export's own days
(the GA4 export SQL reference §11, whole) are joined to it:

```sql
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

A rate, a ratio, an average and a funnel are never filled: a day with no denominator is NULL. A Google Ads
template reads the transfer, not the export, and is left as it is. A count you write yourself is finished the
same way.

## Version 1: without ads

Every site's ten. Active, New and Returning users read the export directly, like Google's own sample
queries (developers.google.com/analytics/bigquery/basic-queries, code Apache 2.0); the rest start with
the shared GA4 block. Where the code does not send `purchase` yet, Purchases, Revenue and Average order
value have no number ("purchase is not sent by the merged code yet."), and the funnel names that step:
"Step 5, Purchased: purchase is not sent by the merged code yet." (`docs/metrics/metrics.md` §6, §9).

### Active users

**Definition:** People who used the site that day.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any

`is_active_user` is Google's "active at any point in the calendar day", filled in daily tables only.

Daily SQL, whole:

```sql
WITH source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    COUNT(DISTINCT IF(is_active_user, user_pseudo_id, NULL)) AS value
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND device.web_info.hostname IN ({{production_hosts}})
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `page`, `page_title`, `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · extra column `views`

People, and the pages they viewed (GA4's Views). The shared GA4 block, `session_bd` and `event_bd`, then:

```sql
SELECT
  dimension_value,
  COUNT(DISTINCT IF(is_active_user, user_pseudo_id, NULL)) AS value,
  COUNTIF(is_view) AS views
FROM event_bd
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** unchanged.

### New users

**Definition:** People on their first visit.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `first_visit`

GA4's own `first_visit` event: never "the first page_view in the range".

Daily SQL, whole:

```sql
WITH source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    COUNT(DISTINCT IF(event_name = 'first_visit', user_pseudo_id, NULL)) AS value
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND device.web_info.hostname IN ({{production_hosts}})
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model` · no extra column

New users split by Channel give the channel of their first session. The shared GA4 block, `session_bd`
and `event_bd`, then:

```sql
SELECT
  dimension_value,
  COUNT(DISTINCT IF(event_name = 'first_visit', user_pseudo_id, NULL)) AS value
FROM event_bd
GROUP BY dimension_value
HAVING COUNT(DISTINCT IF(event_name = 'first_visit', user_pseudo_id, NULL)) > 0
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Returning users

**Definition:** People who had been here before.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any

Active that day in a session that is not their first. Like GA4, a person who came for the first time and
came back the same day counts as new and as returning.

Daily SQL, whole:

```sql
WITH source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
users AS (
  -- Each person's day: active, and in a session that is not their first.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    user_pseudo_id,
    LOGICAL_OR(is_active_user) AS active,
    LOGICAL_OR((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number' LIMIT 1) > 1) AS came_back
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND device.web_info.hostname IN ({{production_hosts}})
    AND user_pseudo_id IS NOT NULL
  GROUP BY day, user_pseudo_id
),
counted AS (
  SELECT day, COUNTIF(active AND came_back) AS value
  FROM users
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `page`, `page_title`, `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model` · extra column `views`

The shared GA4 block, `session_bd` and `event_bd`, then:

```sql
SELECT
  dimension_value,
  COUNT(DISTINCT IF(is_active_user AND session_number > 1, user_pseudo_id, NULL)) AS value,
  COUNTIF(is_view AND session_number > 1) AS views
FROM event_bd
GROUP BY dimension_value
HAVING COUNT(DISTINCT IF(is_active_user AND session_number > 1, user_pseudo_id, NULL)) > 0
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Sessions

**Definition:** Visits to the site.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any

Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT day, COUNT(*) AS value
  FROM classified
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

The shared GA4 block and `session_bd`, then:

```sql
SELECT dimension_value, COUNT(*) AS value
FROM session_bd
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Engagement rate

**Definition:** Engaged sessions ÷ sessions: over 10 seconds, a key event, or 2+ pages.

**Unit** `percent` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any

GA4's own `session_engaged` parameter says which sessions were engaged.

Daily SQL: the shared GA4 block, then:

```sql
SELECT day, 100 * SAFE_DIVIDE(COUNTIF(engaged), COUNT(*)) AS value
FROM classified
GROUP BY day
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · extra column `sessions`

A rate is sorted by its sessions. The shared GA4 block and `session_bd`, then:

```sql
SELECT dimension_value, 100 * SAFE_DIVIDE(COUNTIF(engaged), COUNT(*)) AS value, COUNT(*) AS sessions
FROM session_bd
GROUP BY dimension_value
ORDER BY sessions DESC
```

**Lead variant:** unchanged.

### Organic search sessions

**Definition:** Visits from search results, not ads.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any

The Organic Search channel of §11's rule: a site without ads gets most of its visitors from search.

Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT day, COUNTIF(organic) AS value
  FROM classified
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `source`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

Its channel and medium are one value, so they are not offered. The shared GA4 block and `session_bd`, then:

```sql
SELECT dimension_value, COUNT(*) AS value
FROM session_bd
WHERE organic
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Purchases

**Definition:** Orders, each transaction_id counted once.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `purchase`

A purchase with no transaction ID is not an order; Tartini's tracking always sends one (with `value`,
`currency` and `items`).

Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT day, COUNT(*) AS value
  FROM orders
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type`, `item_name`, `item_category` · no extra column

By item: the orders that contain it. The shared GA4 block, `session_bd`, `order_bd` and `item_bd`, then:

```sql
SELECT dimension_value, COUNT(DISTINCT transaction_id) AS value
FROM (
  SELECT transaction_id, dimension_value FROM order_bd
  WHERE @dimension NOT IN ('item_name', 'item_category')
  UNION ALL
  SELECT transaction_id, dimension_value FROM item_bd
  WHERE @dimension IN ('item_name', 'item_category')
)
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** **Leads**, "Sessions with a lead (generate_lead), each counted once."; **Sign-ups**
for `sign_up`, "Sessions with a sign-up (sign_up), each counted once.". Events: the conversion event.
Breakdown: S, no Items. Daily SQL: the shared GA4 block, then:

```sql
, converted AS (
  -- Each session with the conversion event, once.
  SELECT DISTINCT session_key
  FROM events
  WHERE event_name = {{conversion_event}} AND session_key IS NOT NULL
)
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT c.day, COUNT(*) AS value
  FROM classified AS c
  JOIN converted AS v USING (session_key)
  GROUP BY c.day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

Its breakdown: the shared GA4 block and `session_bd`, the same `converted`, then:

```sql
SELECT b.dimension_value, COUNT(*) AS value
FROM session_bd AS b
JOIN converted AS v USING (session_key)
GROUP BY b.dimension_value
ORDER BY value DESC
```

### Revenue

**Definition:** Purchase value, minus refunds.

**Unit** `currency` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `purchase`

A refund is subtracted on the day it happened. A shop that sells in several currencies uses
`purchase_revenue_in_usd` and `refund_value_in_usd` instead.

Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT day, SUM(amount) AS value
  FROM (
    SELECT day, revenue AS amount FROM orders
    UNION ALL
    SELECT day, -refunded AS amount FROM refunds
  )
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type`, `item_name`, `item_category` · no extra column

Under the Items tab the card says: "Item revenue: price × quantity, before refunds, shipping and tax."
The shared GA4 block, `session_bd`, `order_bd` and `item_bd`, then:

```sql
SELECT dimension_value, SUM(amount) AS value
FROM (
  SELECT dimension_value, revenue AS amount FROM order_bd
  WHERE @dimension NOT IN ('item_name', 'item_category')
  UNION ALL
  -- A refund is on its order's row; the refund of an order placed before these days is (not set).
  SELECT o.dimension_value, -r.refunded AS amount
  FROM refunds AS r
  LEFT JOIN order_bd AS o USING (transaction_id)
  WHERE @dimension NOT IN ('item_name', 'item_category')
  UNION ALL
  -- By item: item revenue (price × quantity) on purchases, before refunds, shipping and tax.
  SELECT dimension_value, item_revenue AS amount FROM item_bd
  WHERE @dimension IN ('item_name', 'item_category')
)
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** removed: a business with no purchase has no revenue on the site.

### Average order value

**Definition:** Purchase value ÷ purchases, before refunds.

**Unit** `currency` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `purchase`

Daily SQL: the shared GA4 block, then:

```sql
SELECT day, SAFE_DIVIDE(SUM(revenue), COUNT(*)) AS value
FROM orders
GROUP BY day
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · extra column `orders`

The shared GA4 block, `session_bd`, `order_bd` and `item_bd`, then:

```sql
SELECT dimension_value, SAFE_DIVIDE(SUM(revenue), COUNT(*)) AS value, COUNT(*) AS orders
FROM order_bd
GROUP BY dimension_value
ORDER BY orders DESC
```

**Lead variant:** removed.

### Conversion funnel

**Definition:** Purchases ÷ sessions, with every step in between: in order, in the same session.

**Unit** `percent` · **Direction** `up` · **Shape** `funnel` · **Reads** the GA4 export · **Events** `page_view`, `purchase` and the steps' events

Steps: 1 Sessions, 2 Viewed a product, 3 Added to cart, 4 Started checkout, 5 Purchased. Each step is
saved with the event it counts (`steps[].event`), so a step the merged code does not send yet is named:
2 `page_view`, 3 and 4 the event of the condition filled into `{{add_to_cart_step}}` and `{{checkout_step}}`
(`add_to_cart`, or `auto_click` for a button), 5 `purchase`; step 1 is every session and names none. A
plan's `Steps:` line writes each as `Purchased (event: purchase)`: only `event:` makes a bracket an event. A
session is counted on the day it started; a step counts when its first time comes at or after the first
time of the step before it (PostHog calls the order "sequential"; a session enters at step 1).
Each step's share, abandonments and the biggest drop are worked out by the metric service from the stored
steps, never in SQL. Steps whose event the code does not send yet still compute the steps before them, and the
funnel shows no conversion until that event is sent.

Daily SQL: the shared GA4 block, then:

```sql
, steps AS (
  -- Each session's first time at each step: its first event, its first view of a product page, its first
  -- add to cart, its first checkout, its first purchase.
  SELECT
    session_key,
    MIN(event_timestamp) AS t1,
    MIN(IF(is_view AND REGEXP_CONTAINS(page_path, {{product_path_re}}), event_timestamp, NULL)) AS t2,
    MIN(IF({{add_to_cart_step}}, event_timestamp, NULL)) AS t3,
    MIN(IF({{checkout_step}}, event_timestamp, NULL)) AS t4,
    MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS t5
  FROM events
  WHERE session_key IS NOT NULL
  GROUP BY session_key
),
reached AS (
  -- A step counts when its first time comes at or after the first time of the step before it.
  SELECT
    c.session_key,
    c.day,
    c.paid,
    s.t2 >= s.t1 AS r2,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AS r3,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AND s.t4 >= s.t3 AS r4,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AND s.t4 >= s.t3 AND s.t5 >= s.t4 AS r5
  FROM classified AS c
  JOIN steps AS s USING (session_key)
)
SELECT
  r.day,
  n.step,
  COUNTIF(CASE n.step WHEN 1 THEN TRUE WHEN 2 THEN r.r2 WHEN 3 THEN r.r3 WHEN 4 THEN r.r4 ELSE r.r5 END) AS value
FROM reached AS r
CROSS JOIN (SELECT 1 AS step UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS n
GROUP BY r.day, n.step
ORDER BY r.day, n.step
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

One row per value and step, the values with most sessions first; each row's conversion is worked out
like the daily one. The shared GA4 block, `session_bd`, the same `steps` and `reached`, then:

```sql
, counts AS (
  SELECT
    b.dimension_value,
    n.step,
    COUNTIF(CASE n.step WHEN 1 THEN TRUE WHEN 2 THEN r.r2 WHEN 3 THEN r.r3 WHEN 4 THEN r.r4 ELSE r.r5 END) AS value
  FROM reached AS r
  JOIN session_bd AS b USING (session_key)
  CROSS JOIN (SELECT 1 AS step UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS n
  GROUP BY b.dimension_value, n.step
)
SELECT c.dimension_value, c.step, c.value
FROM counts AS c
JOIN (SELECT dimension_value, value AS entered FROM counts WHERE step = 1) AS e
  ON e.dimension_value IS NOT DISTINCT FROM c.dimension_value
ORDER BY e.entered DESC, c.dimension_value, c.step
```

**Lead variant:** "Conversions ÷ sessions, with every step in between: in order, in the same session.";
steps 1 Sessions, 2 Clicked the main button, 3 Started the form, 4 Submitted the form, 5 Succeeded, each
saved with the event its condition counts (2 to 4 the events of `{{main_button_step}}`, `{{form_start_step}}`
and `{{form_submit_step}}`, 5 `{{conversion_event}}`). `{{form_start_step}}` is GA4's `form_start` (Enhanced Measurement's form interactions, an Admin setting
the code cannot prove) or an event the code sends; `{{form_submit_step}}` is an attempt, the conversion
event the success. Use a `page_view` for step 2 only when the button is on a page of its own. The same
daily and breakdown statements, with this `steps` in place of the one above:

```sql
, steps AS (
  -- Each session's first time at each step: its first event, its first click on the main button, its
  -- first form start, its first form submit, its first conversion.
  SELECT
    session_key,
    MIN(event_timestamp) AS t1,
    MIN(IF({{main_button_step}}, event_timestamp, NULL)) AS t2,
    MIN(IF({{form_start_step}}, event_timestamp, NULL)) AS t3,
    MIN(IF({{form_submit_step}}, event_timestamp, NULL)) AS t4,
    MIN(IF(event_name = {{conversion_event}}, event_timestamp, NULL)) AS t5
  FROM events
  WHERE session_key IS NOT NULL
  GROUP BY session_key
),
```

## Version 2: added when the site runs ads

Thirteen more for a site that runs ads. Each says which side its number reads (Conventions, "Two
sides"). The rows that read the Google Ads transfer need it in BigQuery; until it exists their check
says "Google Ads cost is not in BigQuery yet.". A site whose paid traffic is from other platforms only
takes the *any paid* rows: Ad conversions, Revenue from ads, Paid conversion funnel, Paid sessions and
Paid engagement rate.

### Ad spend

**Definition:** What Google Ads charged that day.

**Unit** `currency` · **Direction** `none` · **Shape** `line` · **Reads** the Google Ads transfer · **Events** none · **When** Google Ads

Spend has no good or bad direction, so it is drawn gray. Daily SQL, whole:

```sql
WITH ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT date_day AS day, spend AS value
FROM ads
ORDER BY day
```

**Breakdown:** `ads_campaign`, `ads_network`, `ads_device`, `ads_country` · no extra column

A Google Ads row of spend, clicks or impressions adds up. The country is Google's criterion ID (2840 is
the United States), shown by name from `app/metrics/google-ads-countries.json`. Whole:

```sql
WITH campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
ads_rows AS (
  -- Campaign, network and device are the campaign stats'. Country is GeoStats' own, one row per country
  -- and location type, which are added up.
  SELECT
    CASE @dimension
      WHEN 'ads_campaign' THEN IFNULL(c.campaign_name, CAST(s.campaign_id AS STRING))
      WHEN 'ads_network' THEN s.segments_ad_network_type
      WHEN 'ads_device' THEN s.segments_device
    END AS dimension_value,
    s.metrics_cost_micros AS cost_micros,
    s.metrics_clicks AS clicks,
    s.metrics_impressions AS impressions
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}` AS s
  LEFT JOIN campaigns AS c USING (campaign_id)
  WHERE @dimension IN ('ads_campaign', 'ads_network', 'ads_device')
    AND s._DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  UNION ALL
  SELECT
    CAST(geographic_view_country_criterion_id AS STRING),
    metrics_cost_micros,
    metrics_clicks,
    metrics_impressions
  FROM `{{ads_dataset}}.ads_GeoStats_{{ads_customer_id}}`
  WHERE @dimension = 'ads_country'
    AND _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
)
SELECT dimension_value, SUM(cost_micros) / 1000000 AS value
FROM ads_rows
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Ad conversions

**Definition:** Orders placed in paid sessions, each order counted once.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `purchase` · **When** any paid

GA4's side: never Google Ads' own conversions, which count another way (Conversion gap).

Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT o.day, COUNT(*) AS value
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  WHERE c.paid
  GROUP BY o.day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

The shared GA4 block, `session_bd`, `order_bd` and `item_bd`, then:

```sql
SELECT dimension_value, COUNT(*) AS value
FROM order_bd
WHERE paid
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** "Paid sessions with a conversion, each counted once."; events: the conversion event.
Daily SQL: the shared GA4 block, then:

```sql
, converted AS (
  -- Each session with the conversion event, once.
  SELECT DISTINCT session_key
  FROM events
  WHERE event_name = {{conversion_event}} AND session_key IS NOT NULL
)
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT c.day, COUNT(*) AS value
  FROM classified AS c
  JOIN converted AS v USING (session_key)
  WHERE c.paid
  GROUP BY c.day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

Its breakdown: the shared GA4 block and `session_bd`, the same `converted`, then:

```sql
SELECT b.dimension_value, COUNT(*) AS value
FROM session_bd AS b
JOIN converted AS v USING (session_key)
WHERE b.paid
GROUP BY b.dimension_value
ORDER BY value DESC
```

### Cost per conversion

**Definition:** Ad spend ÷ orders from Google Ads sessions.

**Unit** `currency` · **Direction** `down` · **Shape** `line` · **Reads** the Google Ads transfer and the GA4 export · **Events** `purchase` · **When** Google Ads

Both sides joined on the day (§12); GA4's side counts Google Ads sessions only. A day with spend and no
order has no number. Daily SQL: the shared GA4 block, then:

```sql
, ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT a.date_day AS day, SAFE_DIVIDE(a.spend, g.conversions) AS value
FROM ads AS a
LEFT JOIN (
  SELECT o.day, COUNT(*) AS conversions
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  WHERE c.google_ads
  GROUP BY o.day
) AS g ON g.day = a.date_day
ORDER BY a.date_day
```

**Breakdown:** `ads_campaign` · extra column `conversions`

By campaign only: the one key both sides share (§12: `campaign_id`). The shared GA4 block, then:

```sql
, campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
cost AS (
  -- Spend and clicks by campaign over the range.
  SELECT campaign_id, SUM(metrics_cost_micros) / 1000000 AS spend, SUM(metrics_clicks) AS clicks
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY campaign_id
),
conv AS (
  -- GA4's orders by the Google Ads campaign of their session.
  SELECT SAFE_CAST(c.ads_campaign_id AS INT64) AS campaign_id, COUNT(*) AS conversions
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  WHERE c.google_ads
  GROUP BY campaign_id
)
SELECT
  CASE @dimension WHEN 'ads_campaign' THEN IFNULL(n.campaign_name, CAST(k.campaign_id AS STRING)) END AS dimension_value,
  SAFE_DIVIDE(k.spend, v.conversions) AS value,
  IFNULL(v.conversions, 0) AS conversions
FROM cost AS k
LEFT JOIN conv AS v USING (campaign_id)
LEFT JOIN campaigns AS n USING (campaign_id)
ORDER BY conversions DESC
```

**Lead variant:** "Ad spend ÷ Google Ads sessions with a conversion."; events: the conversion event.
Daily SQL: the shared GA4 block, then:

```sql
, converted AS (
  -- Each session with the conversion event, once.
  SELECT DISTINCT session_key
  FROM events
  WHERE event_name = {{conversion_event}} AND session_key IS NOT NULL
)
, ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT a.date_day AS day, SAFE_DIVIDE(a.spend, g.conversions) AS value
FROM ads AS a
LEFT JOIN (
  SELECT c.day, COUNT(*) AS conversions
  FROM classified AS c
  JOIN converted AS v USING (session_key)
  WHERE c.google_ads
  GROUP BY c.day
) AS g ON g.day = a.date_day
ORDER BY a.date_day
```

Its breakdown: the shared GA4 block, the same `converted`, then:

```sql
, campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
cost AS (
  -- Spend and clicks by campaign over the range.
  SELECT campaign_id, SUM(metrics_cost_micros) / 1000000 AS spend, SUM(metrics_clicks) AS clicks
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY campaign_id
),
conv AS (
  -- GA4's converting sessions by their Google Ads campaign.
  SELECT SAFE_CAST(c.ads_campaign_id AS INT64) AS campaign_id, COUNT(*) AS conversions
  FROM classified AS c
  JOIN converted AS v USING (session_key)
  WHERE c.google_ads
  GROUP BY campaign_id
)
SELECT
  CASE @dimension WHEN 'ads_campaign' THEN IFNULL(n.campaign_name, CAST(k.campaign_id AS STRING)) END AS dimension_value,
  SAFE_DIVIDE(k.spend, v.conversions) AS value,
  IFNULL(v.conversions, 0) AS conversions
FROM cost AS k
LEFT JOIN conv AS v USING (campaign_id)
LEFT JOIN campaigns AS n USING (campaign_id)
ORDER BY conversions DESC
```

### Revenue from ads

**Definition:** Purchase value from paid sessions, minus refunds.

**Unit** `currency` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** `purchase` · **When** any paid

A refund is subtracted on its order's day here, so a paid order's refund never lands on a day with no
paid orders. Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT o.day, SUM(o.revenue) - IFNULL(SUM(r.refunded), 0) AS value
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  LEFT JOIN (SELECT transaction_id, SUM(refunded) AS refunded FROM refunds GROUP BY transaction_id) AS r
    USING (transaction_id)
  WHERE c.paid
  GROUP BY o.day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

The shared GA4 block, `session_bd`, `order_bd` and `item_bd`, then:

```sql
SELECT o.dimension_value, SUM(o.revenue) - IFNULL(SUM(r.refunded), 0) AS value
FROM order_bd AS o
LEFT JOIN (SELECT transaction_id, SUM(refunded) AS refunded FROM refunds GROUP BY transaction_id) AS r
  USING (transaction_id)
WHERE o.paid
GROUP BY o.dimension_value
ORDER BY value DESC
```

**Lead variant:** removed.

### Return on ad spend

**Definition:** Revenue from Google Ads sessions ÷ ad spend.

**Unit** `ratio` · **Direction** `up` · **Shape** `line` · **Reads** the Google Ads transfer and the GA4 export · **Events** `purchase` · **When** Google Ads

A day with spend and no revenue is 0. Daily SQL: the shared GA4 block, then:

```sql
, ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT a.date_day AS day, SAFE_DIVIDE(IFNULL(g.revenue, 0), a.spend) AS value
FROM ads AS a
LEFT JOIN (
  SELECT o.day, SUM(o.revenue) - IFNULL(SUM(r.refunded), 0) AS revenue
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  LEFT JOIN (SELECT transaction_id, SUM(refunded) AS refunded FROM refunds GROUP BY transaction_id) AS r
    USING (transaction_id)
  WHERE c.google_ads
  GROUP BY o.day
) AS g ON g.day = a.date_day
ORDER BY a.date_day
```

**Breakdown:** `ads_campaign` · extra column `spend`

By campaign only. The shared GA4 block, then:

```sql
, campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
cost AS (
  -- Spend and clicks by campaign over the range.
  SELECT campaign_id, SUM(metrics_cost_micros) / 1000000 AS spend, SUM(metrics_clicks) AS clicks
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY campaign_id
),
rev AS (
  -- GA4's purchase value, minus refunds, by the Google Ads campaign of the order's session.
  SELECT SAFE_CAST(c.ads_campaign_id AS INT64) AS campaign_id, SUM(o.revenue) - IFNULL(SUM(r.refunded), 0) AS revenue
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  LEFT JOIN (SELECT transaction_id, SUM(refunded) AS refunded FROM refunds GROUP BY transaction_id) AS r
    USING (transaction_id)
  WHERE c.google_ads
  GROUP BY campaign_id
)
SELECT
  CASE @dimension WHEN 'ads_campaign' THEN IFNULL(n.campaign_name, CAST(k.campaign_id AS STRING)) END AS dimension_value,
  SAFE_DIVIDE(IFNULL(g.revenue, 0), k.spend) AS value,
  k.spend AS spend
FROM cost AS k
LEFT JOIN rev AS g USING (campaign_id)
LEFT JOIN campaigns AS n USING (campaign_id)
ORDER BY spend DESC
```

**Lead variant:** removed.

### Paid conversion funnel

**Definition:** Purchases ÷ paid sessions, with every step in between: in order, in the same session.

**Unit** `percent` · **Direction** `up` · **Shape** `funnel` · **Reads** the GA4 export · **Events** `page_view`, `purchase` and the steps' events · **When** any paid

The Conversion funnel over paid sessions, with the same steps (1 Sessions, 2 Viewed a product, 3 Added
to cart, 4 Started checkout, 5 Purchased: the same names, so they compare) and the same events on them;
`compareWith` is the Conversion funnel's id. Daily SQL: the shared GA4 block, then:

```sql
, steps AS (
  -- Each session's first time at each step: its first event, its first view of a product page, its first
  -- add to cart, its first checkout, its first purchase.
  SELECT
    session_key,
    MIN(event_timestamp) AS t1,
    MIN(IF(is_view AND REGEXP_CONTAINS(page_path, {{product_path_re}}), event_timestamp, NULL)) AS t2,
    MIN(IF({{add_to_cart_step}}, event_timestamp, NULL)) AS t3,
    MIN(IF({{checkout_step}}, event_timestamp, NULL)) AS t4,
    MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS t5
  FROM events
  WHERE session_key IS NOT NULL
  GROUP BY session_key
),
reached AS (
  -- A step counts when its first time comes at or after the first time of the step before it.
  SELECT
    c.session_key,
    c.day,
    c.paid,
    s.t2 >= s.t1 AS r2,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AS r3,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AND s.t4 >= s.t3 AS r4,
    s.t2 >= s.t1 AND s.t3 >= s.t2 AND s.t4 >= s.t3 AND s.t5 >= s.t4 AS r5
  FROM classified AS c
  JOIN steps AS s USING (session_key)
)
SELECT
  r.day,
  n.step,
  COUNTIF(CASE n.step WHEN 1 THEN TRUE WHEN 2 THEN r.r2 WHEN 3 THEN r.r3 WHEN 4 THEN r.r4 ELSE r.r5 END) AS value
FROM reached AS r
CROSS JOIN (SELECT 1 AS step UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS n
WHERE r.paid
GROUP BY r.day, n.step
ORDER BY r.day, n.step
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

The shared GA4 block, `session_bd`, the same `steps` and `reached`, then:

```sql
, counts AS (
  SELECT
    b.dimension_value,
    n.step,
    COUNTIF(CASE n.step WHEN 1 THEN TRUE WHEN 2 THEN r.r2 WHEN 3 THEN r.r3 WHEN 4 THEN r.r4 ELSE r.r5 END) AS value
  FROM reached AS r
  JOIN session_bd AS b USING (session_key)
  CROSS JOIN (SELECT 1 AS step UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS n
  WHERE r.paid
  GROUP BY b.dimension_value, n.step
)
SELECT c.dimension_value, c.step, c.value
FROM counts AS c
JOIN (SELECT dimension_value, value AS entered FROM counts WHERE step = 1) AS e
  ON e.dimension_value IS NOT DISTINCT FROM c.dimension_value
ORDER BY e.entered DESC, c.dimension_value, c.step
```

**Lead variant:** "Conversions ÷ paid sessions, with every step in between: in order, in the same
session."; steps 1 Sessions, 2 Clicked the main button, 3 Started the form, 4 Submitted the form,
5 Succeeded (the Conversion funnel's lead steps). The same daily and breakdown statements, with this
`steps` in place of the one above:

```sql
, steps AS (
  -- Each session's first time at each step: its first event, its first click on the main button, its
  -- first form start, its first form submit, its first conversion.
  SELECT
    session_key,
    MIN(event_timestamp) AS t1,
    MIN(IF({{main_button_step}}, event_timestamp, NULL)) AS t2,
    MIN(IF({{form_start_step}}, event_timestamp, NULL)) AS t3,
    MIN(IF({{form_submit_step}}, event_timestamp, NULL)) AS t4,
    MIN(IF(event_name = {{conversion_event}}, event_timestamp, NULL)) AS t5
  FROM events
  WHERE session_key IS NOT NULL
  GROUP BY session_key
),
```

### Paid sessions

**Definition:** Sessions from a Google Ads click or a paid channel.

**Unit** `count` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any · **When** any paid

A Google Ads click is a session GA4 names a Google Ads campaign for, or one with a gclid; the paid
channels are §11's. Daily SQL: the shared GA4 block, then:

```sql
, source_days AS (
  -- Every day the export holds over the days asked for, whatever its events.
  SELECT DISTINCT PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS day
  FROM `{{events_table}}`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
),
counted AS (
  SELECT day, COUNTIF(paid) AS value
  FROM classified
  GROUP BY day
)
SELECT source_days.day, COALESCE(counted.value, 0) AS value
FROM source_days
LEFT JOIN counted USING (day)
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · no extra column

The landing pages of paid sessions are GA4's: the transfer has none. The shared GA4 block and
`session_bd`, then:

```sql
SELECT dimension_value, COUNT(*) AS value
FROM session_bd
WHERE paid
GROUP BY dimension_value
ORDER BY value DESC
```

**Lead variant:** unchanged.

### Click-through rate

**Definition:** Ad clicks ÷ ad impressions.

**Unit** `percent` · **Direction** `up` · **Shape** `line` · **Reads** the Google Ads transfer · **Events** none · **When** Google Ads

Daily SQL, whole:

```sql
WITH ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT date_day AS day, 100 * SAFE_DIVIDE(clicks, impressions) AS value
FROM ads
ORDER BY day
```

**Breakdown:** `ads_campaign`, `ads_network`, `ads_device`, `ads_country` · extra column `impressions`

Ad impressions by Campaign, Network, Device and Country, never by page: an ad is seen on Google's pages.
Whole:

```sql
WITH campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
ads_rows AS (
  -- Campaign, network and device are the campaign stats'. Country is GeoStats' own, one row per country
  -- and location type, which are added up.
  SELECT
    CASE @dimension
      WHEN 'ads_campaign' THEN IFNULL(c.campaign_name, CAST(s.campaign_id AS STRING))
      WHEN 'ads_network' THEN s.segments_ad_network_type
      WHEN 'ads_device' THEN s.segments_device
    END AS dimension_value,
    s.metrics_cost_micros AS cost_micros,
    s.metrics_clicks AS clicks,
    s.metrics_impressions AS impressions
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}` AS s
  LEFT JOIN campaigns AS c USING (campaign_id)
  WHERE @dimension IN ('ads_campaign', 'ads_network', 'ads_device')
    AND s._DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  UNION ALL
  SELECT
    CAST(geographic_view_country_criterion_id AS STRING),
    metrics_cost_micros,
    metrics_clicks,
    metrics_impressions
  FROM `{{ads_dataset}}.ads_GeoStats_{{ads_customer_id}}`
  WHERE @dimension = 'ads_country'
    AND _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
)
SELECT dimension_value, 100 * SAFE_DIVIDE(SUM(clicks), SUM(impressions)) AS value, SUM(impressions) AS impressions
FROM ads_rows
GROUP BY dimension_value
ORDER BY impressions DESC
```

**Lead variant:** unchanged.

### Cost per click

**Definition:** Ad spend ÷ ad clicks.

**Unit** `currency` · **Direction** `down` · **Shape** `line` · **Reads** the Google Ads transfer · **Events** none · **When** Google Ads

Daily SQL, whole:

```sql
WITH ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT date_day AS day, SAFE_DIVIDE(spend, clicks) AS value
FROM ads
ORDER BY day
```

**Breakdown:** `ads_campaign`, `ads_network`, `ads_device`, `ads_country` · extra column `clicks`

Whole:

```sql
WITH campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
ads_rows AS (
  -- Campaign, network and device are the campaign stats'. Country is GeoStats' own, one row per country
  -- and location type, which are added up.
  SELECT
    CASE @dimension
      WHEN 'ads_campaign' THEN IFNULL(c.campaign_name, CAST(s.campaign_id AS STRING))
      WHEN 'ads_network' THEN s.segments_ad_network_type
      WHEN 'ads_device' THEN s.segments_device
    END AS dimension_value,
    s.metrics_cost_micros AS cost_micros,
    s.metrics_clicks AS clicks,
    s.metrics_impressions AS impressions
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}` AS s
  LEFT JOIN campaigns AS c USING (campaign_id)
  WHERE @dimension IN ('ads_campaign', 'ads_network', 'ads_device')
    AND s._DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  UNION ALL
  SELECT
    CAST(geographic_view_country_criterion_id AS STRING),
    metrics_cost_micros,
    metrics_clicks,
    metrics_impressions
  FROM `{{ads_dataset}}.ads_GeoStats_{{ads_customer_id}}`
  WHERE @dimension = 'ads_country'
    AND _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
)
SELECT dimension_value, SAFE_DIVIDE(SUM(cost_micros) / 1000000, SUM(clicks)) AS value, SUM(clicks) AS clicks
FROM ads_rows
GROUP BY dimension_value
ORDER BY clicks DESC
```

**Lead variant:** unchanged.

### Click-to-session rate

**Definition:** Google Ads sessions ÷ ad clicks; a drop means lost gclids or slow pages.

**Unit** `percent` · **Direction** `up` · **Shape** `line` · **Reads** the Google Ads transfer and the GA4 export · **Events** none · **When** Google Ads

Google Ads sessions only, because only they are counted in Google Ads clicks. Daily SQL: the shared GA4
block, then:

```sql
, ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
)
SELECT a.date_day AS day, 100 * SAFE_DIVIDE(IFNULL(g.sessions, 0), a.clicks) AS value
FROM ads AS a
LEFT JOIN (
  SELECT day, COUNTIF(google_ads) AS sessions
  FROM classified
  GROUP BY day
) AS g ON g.day = a.date_day
ORDER BY a.date_day
```

**Breakdown:** `ads_campaign` · extra column `clicks`

By campaign only. The shared GA4 block, then:

```sql
, campaigns AS (
  -- Campaign names, from the newest snapshot of the transfer's Campaign table (Google's sample queries).
  SELECT campaign_id, ANY_VALUE(campaign_name) AS campaign_name
  FROM `{{ads_dataset}}.ads_Campaign_{{ads_customer_id}}`
  WHERE _DATA_DATE = _LATEST_DATE
  GROUP BY campaign_id
),
cost AS (
  -- Spend and clicks by campaign over the range.
  SELECT campaign_id, SUM(metrics_cost_micros) / 1000000 AS spend, SUM(metrics_clicks) AS clicks
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY campaign_id
),
visits AS (
  -- Google Ads sessions by their campaign.
  SELECT SAFE_CAST(ads_campaign_id AS INT64) AS campaign_id, COUNT(*) AS sessions
  FROM classified
  WHERE google_ads
  GROUP BY campaign_id
)
SELECT
  CASE @dimension WHEN 'ads_campaign' THEN IFNULL(n.campaign_name, CAST(k.campaign_id AS STRING)) END AS dimension_value,
  100 * SAFE_DIVIDE(IFNULL(v.sessions, 0), k.clicks) AS value,
  k.clicks AS clicks
FROM cost AS k
LEFT JOIN visits AS v USING (campaign_id)
LEFT JOIN campaigns AS n USING (campaign_id)
ORDER BY clicks DESC
```

**Lead variant:** unchanged.

### Paid engagement rate

**Definition:** Engaged paid sessions ÷ paid sessions.

**Unit** `percent` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any · **When** any paid

Daily SQL: the shared GA4 block, then:

```sql
SELECT day, 100 * SAFE_DIVIDE(COUNTIF(paid AND engaged), COUNTIF(paid)) AS value
FROM classified
GROUP BY day
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · extra column `sessions`

The shared GA4 block and `session_bd`, then:

```sql
SELECT dimension_value, 100 * SAFE_DIVIDE(COUNTIF(engaged), COUNT(*)) AS value, COUNT(*) AS sessions
FROM session_bd
WHERE paid
GROUP BY dimension_value
ORDER BY sessions DESC
```

**Lead variant:** unchanged.

### Conversion gap, Ads vs GA4 (7-day)

**Definition:** How far Google Ads' conversions are from GA4's orders from Google Ads sessions over 7 days: (Ads − GA4) ÷ GA4.

**Unit** `percent` · **Direction** `down` · **Shape** `line` · **Reads** the Google Ads transfer and the GA4 export · **Events** `purchase` · **When** Google Ads

Over 7 days, because Google Ads dates a conversion on the day of the click and GA4 on the day it
happened, so a daily gap jumps around. Why they differ (§12): `metrics_conversions` counts Primary
actions only, an action counting One counts one per click, and a GA4 key event imported into Ads arrives
up to 24 hours late. The two are never added together.

Daily SQL: the shared GA4 block with its `_TABLE_SUFFIX BETWEEN @start_suffix` read as
`_TABLE_SUFFIX BETWEEN @lookback_start_suffix` (code binds it six days before the start, so the first day
has a whole window), then:

```sql
, ads AS (
  -- Google Ads' numbers by day, from the transfer's campaign stats, with the field names of Fivetran
  -- dbt_google_ads' campaign report (Apache 2.0). Spend is in the Ads account's currency.
  SELECT
    _DATA_DATE AS date_day,
    SUM(metrics_cost_micros) / 1000000 AS spend,
    SUM(metrics_clicks) AS clicks,
    SUM(metrics_impressions) AS impressions,
    SUM(metrics_conversions) AS conversions,
    SUM(metrics_conversions_value) AS conversions_value
  FROM `{{ads_dataset}}.ads_CampaignBasicStats_{{ads_customer_id}}`
  WHERE _DATA_DATE BETWEEN PARSE_DATE('%Y%m%d', @lookback_start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
  GROUP BY _DATA_DATE
),
ga4 AS (
  -- GA4's orders from Google Ads sessions, by day.
  SELECT o.day, COUNT(*) AS conversions
  FROM orders AS o
  JOIN classified AS c USING (session_key)
  WHERE c.google_ads
  GROUP BY o.day
),
daily AS (
  -- Both sides by day; a day one side has no row for is a 0 there.
  SELECT
    COALESCE(a.date_day, g.day) AS day,
    IFNULL(a.conversions, 0) AS ads_conversions,
    IFNULL(g.conversions, 0) AS ga4_conversions
  FROM ads AS a
  FULL OUTER JOIN ga4 AS g ON g.day = a.date_day
),
rolling AS (
  -- Seven days ending on each day. The window runs before the range is cut, so its first day has its six.
  SELECT
    day,
    100 * SAFE_DIVIDE(
      SUM(ads_conversions) OVER (ORDER BY UNIX_DATE(day) RANGE BETWEEN 6 PRECEDING AND CURRENT ROW)
        - SUM(ga4_conversions) OVER (ORDER BY UNIX_DATE(day) RANGE BETWEEN 6 PRECEDING AND CURRENT ROW),
      SUM(ga4_conversions) OVER (ORDER BY UNIX_DATE(day) RANGE BETWEEN 6 PRECEDING AND CURRENT ROW)) AS value
  FROM daily
)
SELECT day, value
FROM rolling
WHERE day BETWEEN PARSE_DATE('%Y%m%d', @start_suffix) AND PARSE_DATE('%Y%m%d', @end_suffix)
ORDER BY day
```

**Breakdown:** none: a 7-day rolling gap has no meaning per row.

**Lead variant:** "How far Google Ads' conversions are from GA4's converting Google Ads sessions over 7
days: (Ads − GA4) ÷ GA4."; events: the conversion event. The same lookback block, then this `converted`
and `ga4`, and the `ads`, `daily`, `rolling` and final SELECT above:

```sql
, converted AS (
  -- Each session with the conversion event, once.
  SELECT DISTINCT session_key
  FROM events
  WHERE event_name = {{conversion_event}} AND session_key IS NOT NULL
)
```

```sql
ga4 AS (
  -- GA4's converting Google Ads sessions, by day.
  SELECT c.day, COUNT(*) AS conversions
  FROM classified AS c
  JOIN converted AS v USING (session_key)
  WHERE c.google_ads
  GROUP BY c.day
),
```

### Auto-tagging coverage

**Definition:** Google Ads sessions that carry a gclid.

**Unit** `percent` · **Direction** `up` · **Shape** `line` · **Reads** the GA4 export · **Events** any · **When** Google Ads

Google Ads sessions here are those GA4 names a Google Ads campaign for, those with a gclid, and those
tagged `google` / `cpc` by hand: auto-tagging off shows as the share without a gclid. Daily SQL: the
shared GA4 block, then:

```sql
SELECT day, 100 * SAFE_DIVIDE(COUNTIF(has_gclid), COUNT(*)) AS value
FROM classified
WHERE google_ads OR (source = 'google' AND medium = 'cpc')
GROUP BY day
ORDER BY day
```

**Breakdown:** `landing_page`, `hostname`, `channel`, `source`, `medium`, `campaign`, `country`, `region`, `city`, `language`, `device_category`, `browser`, `os`, `os_version`, `device_model`, `user_type` · extra column `sessions`

The shared GA4 block and `session_bd`, then:

```sql
SELECT dimension_value, 100 * SAFE_DIVIDE(COUNTIF(has_gclid), COUNT(*)) AS value, COUNT(*) AS sessions
FROM session_bd
WHERE google_ads OR (source = 'google' AND medium = 'cpc')
GROUP BY dimension_value
ORDER BY sessions DESC
```

**Lead variant:** unchanged.

## Breakdowns: what GA4 offers, and what the export carries

The dimension list is closed and lives in code (`app/metrics/metric-dimensions.js`); how the detail page
shows a breakdown is `docs/metrics/metrics.md` §9. Why the default keys are these: GA4's standard
reports, restricted to what the BigQuery export carries (report help pages, checked 2026-10-19).

| GA4 report | Dimensions GA4 lists | In the BigQuery export | Default keys |
|---|---|---|---|
| Traffic acquisition | Session primary channel group, source, medium, campaign | the channel is worked out (§11, no column); the rest is the session's source (§12) | `channel`, `source`, `medium`, `campaign` |
| User acquisition | First user channel, source, medium, campaign | `traffic_source` | none: New users split by channel already gives their first session's channel |
| Pages and screens | Page path, page title, content group, hostname | `page_location`, `page_title`; `device.web_info.hostname` | `page`, `page_title`, `hostname` |
| Landing page | Landing page | the session's first view | `landing_page` |
| Demographic details | Country, region, city, language, age, gender, interests | `geo.*`, `device.language`; no age, gender or interests (Google signals stay out of the export) | `country`, `region`, `city`, `language` |
| Tech details | Browser, device category, model, OS, OS version, screen resolution | `device.*`; no screen resolution | `device_category`, `browser`, `os`, `os_version`, `device_model` |
| Ecommerce purchases | Item name, ID, category, brand | `items.*` | `item_name`, `item_category` |
| Explorations | New / returning | `ga_session_number` (1 is New) | `user_type` |

City, device model and OS version are "(not set)" where an admin turned granular location and device
data off. The Google Ads transfer's own: campaign (`ads_Campaign_<id>.campaign_name`), network
(`segments_ad_network_type`), device (`segments_device`) and country (`ads_GeoStats_<id>`,
`geographic_view_country_criterion_id`); age, gender, keywords and search terms are on request, and
there is no landing page (an ad is seen on Google's pages). A split not on the list (UTM term, item
brand, a custom parameter) is a question for Tartini AI, answered from the metric's definition and
stored nowhere.

## Sources

- GA4 BigQuery export schema (support.google.com/analytics/answer/7029846): `is_active_user`,
  `ecommerce.*`, `items.*`, `device.*`, `geo.*`, `session_traffic_source_last_click`,
  `collected_traffic_source`; no channel-group field.
- GA4 traffic attribution data (developers.google.com/analytics/bigquery/traffic-attribution-data) and
  the GA4 export SQL reference §12 built from it.
- GA4 basic queries (developers.google.com/analytics/bigquery/basic-queries), code Apache 2.0: users,
  new users.
- GA4 default channel group (support.google.com/analytics/answer/9756891), translated in
  `app/metrics/ga4-metric-sql.js` from dbt-ga4 (MIT, Copyright (c) 2022 Adam Ribaudo):
  `macros/default_channel_grouping.sql` and `seeds/ga4_source_categories.csv`.
- dbt-ga4 (MIT): the sessions model (a session's first event, its landing page) and
  `models/staging/stg_ga4__events.sql` (a gclid alone is google / cpc); ideas, rewritten.
- BigQuery Google Ads transfer and its report transformation (docs.cloud.google.com/bigquery/docs/
  google-ads-transformation): CampaignBasicStats, Campaign, GeoStats and their columns; Google's sample
  queries (`_DATA_DATE`, `_LATEST_DATE`, `metrics_cost_micros / 1000000`).
- Fivetran dbt_google_ads (Apache 2.0), `models/google_ads__campaign_report.sql`: the field names
  date_day, campaign_id, spend, clicks, impressions, conversions, conversions_value; no code copied.
- PostHog (MIT outside `ee/`): the funnel's sequential order; web analytics' breakdown list, the idea of
  the dimension catalog. Umami (MIT): the event and session levels.
