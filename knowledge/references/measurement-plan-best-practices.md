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

- **Find out before you write.** Read the public pages the person names (`read_public_page`) and look
  at the screenshots they attach. With Tracking connected, `get_tracking_state` says what the code
  already sends and whether Autocapture is installed.
- **With BigQuery connected, look at the data before you write.** When the project's state says
  BigQuery is connected and the GA4 export is there with daily tables, query it with
  `query_bigquery`, which needs no Tables guide, and then:
  1. run Query 0 (the GA4 export SQL reference) on the last 14 days of the export (every day it has,
     when it has fewer) BEFORE you write any other query, and build "How each action is recognized",
     the production hostnames and every `actions` row from what it returns: the real button labels, ids,
     forms and pages, each marked "seen in the data". Add `page_view` and its path to it when a metric
     counts a page, so the path is one the data has. An action the data does not show yet stays "seen
     on the website" or "confirm with code";
  2. write every query against the real dataset and hostnames, check each one with
     `query_bigquery { dryRun: true }`, fix what the dry run rejects, and only then write
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
