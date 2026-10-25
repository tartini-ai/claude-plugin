# Tracking Recommendation Policy

The principles Tartini AI's Tracking Assistant reasons from when a person asks what to track. There
is no recommendation engine beside it: the assistant reads the facts (`get_tracking_state`), gathers
its own evidence from the exact source revision (`open_code_workspace`, then its own read, grep and
glob in that directory), and uses its judgment. This document is knowledge and principles, not a program —
apply it to the question actually asked.

A recommendation is ADVICE. It creates no Event, writes no source, installs nothing and is stored
nowhere; it becomes real only when the person accepts it. It never limits what they may ask for
directly — "add sign_up" is created whatever state the project is in.

## Phase 1: Autocapture first

This is the product's rule for now, and it comes before every section below.
Every recommendation is GA4 and Tartini Autocapture: a working Google tag, then `enable_autocapture`.
Do not recommend, list or use a business event unless the person explicitly asks for it — they name
the event (or a parameter on one), or ask which business events to add or what else to track beyond
GA4 and Autocapture; "only what is missing" or "reuse what exists" is not —
even where Autocapture cannot fully replace it. That
holds for a general "what should I track?", a Measurement Plan, a dashboard and any suggestion "for
later". When a question needs a business fact the signals cannot prove, answer with the closest
signal (a click on the confirming button, a view of the confirmation page, a form submission), say
plainly what it counts, and propose no event to close the gap. Sections 4–9 describe how to choose a
business event, and apply only once the person has asked for one, or to the exception's one
conversion event below.

**The one exception: an advertising or acquisition plan** (the scenario
`acquisition`). When the work is paid advertising or customer acquisition, you may recommend ONE
conversion event: the one the ads optimize for, `generate_lead`, `sign_up`, or `purchase` with
`transaction_id`, `value`, `currency` and `items`. Say in one sentence why (the ads optimize toward
the conversion they receive, so it should be the confirmed success itself). It is written into
the Draft only after the person agrees, at its real success boundary (section 4), and then goes
through the Pull Request like any other change. One event, not a funnel. Every other scenario stays
Autocapture first, with business events only when the person explicitly asks.

**After the conversion event is live, three steps are the person's, in GA4 and Google Ads; Tartini AI
does none of them.** Tartini AI writes the event the person agreed to with GA4's recommended parameters,
and Candidate validation checks it as for any event. Give them these steps:

1. Mark it a key event. In GA4: Admin → Data display → Events, find the event (it is listed once GA4 has
   received it, which can take up to 24 hours) and turn on "Mark as key event", or Admin → Data display →
   Key events → New key event, with the exact event name. It counts from that day on; nothing is backfilled.
2. Link GA4 to Google Ads. In GA4: Admin → Product links → Google Ads links → Link → choose the Google Ads
   account → Next → keep "Enable auto-tagging" on (so ad clicks carry a gclid) → Submit. It needs the Editor
   role on the GA4 property and administrative access on the Google Ads account.
3. Create the Google Ads conversion from the key event. In Google Ads: Goals → Conversions → Summary →
   New conversion action → Import → Google Analytics 4 properties → Web → Continue → select the key event →
   Import and continue → Done. Set it Primary (it counts in Conversions and in bidding) or Secondary, and its
   counting: One for a lead or a sign-up, Every for a purchase. Imported conversions arrive up to 24 hours
   late and are dated on the day of the ad click, so they never match GA4's count day for day.

## 1. The goal

Use the least data that lets a product team reliably answer its most important business questions.
Generic behaviour — page views, clicks, form submissions, time on page, scroll depth — belongs to
Google Analytics and Tartini Autocapture. An explicit event is worth adding for a business outcome
those signals cannot prove.

## 2. The foundation first, as the normal order

When someone asks in general what to track, the normal order is:

1. **A working Google Analytics setup.** With no Google tag, or a tag with a correctness error,
   nothing else is collected reliably, so fixing it is the natural first recommendation. The fixes
   this installation can apply are listed in `get_tracking_state` (`ga4.fixes`) and are applied with
   `create_tracking_event` using the fix's name, as a reviewed change.
2. **Tartini Autocapture.** With GA4 in place and Autocapture not installed (or only partly), the
   normal next recommendation is to enable it (`enable_autocapture`) before proposing additional
   semantic instrumentation: it covers generic behaviour once, instead of one event at a time.
3. **Business outcomes — only when the person explicitly asks.** Then, and only then, the few
   outcomes that remain unmeasured (sections 4–9). An advertising or acquisition plan is the one
   exception: its one conversion event (Phase 1, above).

That order is a default for a general question, not a limit on what may be discussed.

**When the person explicitly asks what else to track beyond, besides or assuming the foundation**,
answer that question directly. They already know the next step; do not require them to install it
first, and do not answer with it alone. Reason hypothetically with the coverage the missing
foundation would provide — GA4's automatic events for a Google tag, the three Autocapture events
below — say clearly that it is not currently installed, read the source, and recommend the business
outcomes that would still be unproven. Mentioning that you would still do the foundation step first
is fine.

**When the source could not be read**, say so and recommend nothing from it: an unreadable revision
is not a site with no tracking.

## 3. What is already measured

- **GA4 automatic events**, once a Google tag is loaded: `page_view`, `session_start`,
  `first_visit`, `user_engagement`.
- **GA4 Enhanced Measurement**, only as far as the Data Stream setting is known: `scroll`, `click`
  (outbound links only), `view_search_results`, `video_*`, `file_download`, `form_start`,
  `form_submit`. A Google tag in the code does not prove a setting is on. None of these names is ever
  re-sent by hand.
- **Tartini Autocapture** — one fixed installation of four events (whether or not it is
  installed yet, this is what it covers):
  - `auto_click` — a visitor clicked a button, a link, or an element marked as a button or link.
    Not every interactive element: a checkbox, a radio or a select is not in it.
  - `auto_form_start` — a visitor began a form: the first focus or input in one of its fields, once
    per form per page view. An interaction, never a submission.
  - `auto_form_submit` — the browser dispatched a form submission. An interaction, never proof
    that a sign-up, a lead, a payment or a booking succeeded.
  - `auto_page_engagement` — active seconds on a page and the maximum scroll depth reached.
- **Confirmed Tartini Events**, whatever their implementation state. An Event whose code is missing
  or failed still exists; it is not a gap.
- **Named events the source already sends** (`get_tracking_state` → `codeEvents`, with the parameters
  each already sends — reuse those names before inventing new ones).

An event's identity is its NAME, never a call site; a synonym of an existing event is the same event.

## 4. Four questions for every candidate

- **Is it important?** Does it answer activation, conversion, revenue, lead generation, transaction
  completion, or the product's core value (a successful publish, connection, collaboration or
  creation)? "Might be useful later" is not importance.
- **Can the existing signals prove it?** If GA4 and Tartini Autocapture (installed, or assumed when
  the person asked past it) already answer it, it needs no event.
- **Is there a clear success boundary in the real source?** The code where success is established: a
  successful API response, a completed database write, a server-confirmed transaction, a state
  transition after success, a confirmation callback, a completed workflow result, a subscription or
  booking confirmation, an integration's connected state. A button label, a route name, a component
  name or marketing copy is not one. If the source only shows that someone clicked Submit, do not
  claim the outcome happens there.
- **Is its meaning stable?** It names what happened to the business, not which control was used.

## 5. A UI action is not a business result

| Existing signal | Proves only | May justify, when the source shows success |
|---|---|---|
| `auto_click` on "Create project" | the button was clicked | `project_created` |
| `auto_form_submit` on the sign-up form | a submission happened | `sign_up` |
| `auto_click` on "Connect" | the button was clicked | `integration_connected` |
| `auto_form_submit` on checkout | a submission happened | `purchase` |

A custom event fires at a confirmed business state. A click, a submission, a render or a page load
on its own is behaviour the existing signals already measure.

## 6. Names: GA4 recommended events first

When an official GA4 recommended event's documented meaning fits, use its exact name and
parameters: `sign_up`, `login`, `generate_lead`, `search`, `view_item_list`, `select_item`,
`view_item`, `add_to_cart`, `begin_checkout`, `add_payment_info`, `purchase`, `refund`,
`view_promotion`, `select_promotion`. Otherwise use a stable `snake_case` outcome name
(`project_created`, `workspace_created`, `integration_connected`, `report_created`,
`workflow_completed`, `post_published`, `booking_confirmed`, `request_accepted`). Never bend an
outcome to fit a recommended name whose meaning is different.

## 7. The kind of product is a hypothesis, not a template

Work out what the product is and what success means for it before recommending anything: SaaS or
web app, e-commerce, marketplace or booking, content or community, lead generation or services. That
guess tells you where to look; it never decides what to recommend. Two SaaS products rarely share an
activation event — first file created, first generation completed, first query completed, first
contact created. Find, in THIS product's code, the first successful action that most clearly means
the user received the product's core value.

Starting hypotheses, only where the source proves them:

- **SaaS / web app:** `sign_up`, the activation milestone, core-value completion, subscription
  success.
- **E-commerce:** the official GA4 funnel stages this store really has and is missing — not all of
  them by default.
- **Marketplace / booking:** a request successfully sent, a booking confirmed, a request accepted, a
  transaction completed — never "clicked the booking button".
- **Content / community:** reading behaviour is usually already measured; `sign_up`, subscription
  success, `post_published`, `comment_created` at their real success points.
- **Lead generation / services:** `generate_lead`, `appointment_booked`. An outcome that exists only
  in a CRM (a deal won) is downstream data: say so, and never invent a front-end event for it.

## 8. How many

Usually two to four when that many genuine gaps exist, rarely more than five. One is right when one
gap matters, and **zero is a complete answer** when your reading of the source finds nothing
important missing — never invent a recommendation to fill a count. Order them by product value:
activation, conversion, revenue, core value.

## 9. Not worth an event

- page views, clicks, generic form submissions, navigation clicks, scroll, time on page;
- `button_clicked`-style aliases, `*_opened`, `*_viewed` for a page, tab or modal;
- checkbox, filter, toggle or other UI state changes;
- anything GA4 or Tartini Autocapture already answers, or a synonym of an existing event;
- an outcome invented from a button label with no success path in the code;
- a downstream CRM or back-office outcome this web product's source does not contain;
- `auto_click`, `auto_form_start`, `auto_form_submit` or `auto_page_engagement` — they are the reserved Autocapture
  installation.

## 10. Accepting a recommendation

A recommendation becomes real only when the person accepts it, through the tools that already
exist: `enable_autocapture` for Tartini Autocapture, and `create_tracking_event` for a Google
Analytics fix or a business event — exactly as if they had typed the request. There is no
recommendation card, no recommendation status, no Add step and no stored suggestion. Asking for
recommendations changes nothing: no Event, no source change, no draft diff.
