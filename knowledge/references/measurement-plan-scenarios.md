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
