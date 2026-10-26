# Tracking Events — GA4 Best Practices

Best practices for **designing and generating** tracked GA4 events. Tartini AI's agent produces GA4
instrumentation, so this doc is the spec the agent follows. GA4 **requirements** (Google's official
event names, parameters, and limits) are authoritative; the product-specific taxonomy and operating
practices are recommended patterns.

Full system design: `../overall/DESIGN.md` §7/§9.

> **Runtime migration note:** Tracking capabilities and this GA4 contract remain unchanged. The
> coding runtime moves to OpenCode + OpenRouter inside the same disposable candidate workspace;
> Tartini AI still owns git/GitHub, validation, promotion, transactions and receipts. See
> `opencode-openrouter-runtime.md`.

> **For visualizing events in the Website Preview, read the system prompt +
> wrong-render ledger in [`website-preview-playbook.md`](./website-preview-playbook.md).**

---

## 0. The central rule — LOG BEHAVIORS, CALCULATE METRICS

GA4 is an **event-based** model: every interaction is an **event** with **parameters**. GA4 collects
events, parameters, user properties, and identifiers; metrics (activation rate, checkout conversion,
feature adoption, retention) are **calculated** from those records.

- ✅ Log the behavior that defines a metric (`tutorial_complete`, `report_created`, `purchase`).
- ❌ Never invent an event for a metric (no `activation_rate` event) — compute it downstream.

```
Activation rate = users who completed the activation action / eligible signed-up users
```

The recipe, in order: define the decision + KPI → write the KPI formula → identify the behaviors →
**reuse** automatic/enhanced events → else a **recommended** event → else a **custom** event → add
only parameters that support a real analysis → register only reportable params as custom dimensions →
mark only business-critical outcomes as key events → validate.

---

## 1. Event selection hierarchy (use the HIGHEST available level)

| Priority | Type | Examples | Action |
|---|---|---|---|
| 1 | **Automatically collected** | `first_visit`, `first_open`, `session_start`, `user_engagement` | Never manually duplicate them. |
| 2 | **Enhanced measurement** | `page_view`, `scroll`, `click` (outbound), `file_download`, `form_start`/`form_submit`, `video_start`/`progress`/`complete`, `view_search_results` | Enable + verify; recreate only if the built-in trigger doesn't match the business meaning. |
| 3 | **Recommended** | `sign_up`, `login`, `search`, `share`, `select_content`, `generate_lead`, `view_item`…`purchase`, `refund` | Use the **exact** official name + documented parameters. |
| 4 | **Custom** | `workspace_created`, `integration_connected`, `report_created` | Only when the first three don't accurately represent the action. |

**Decision tree:** already auto-collected? → use it. Else an enhanced-measurement event with the
correct meaning? → enable it. Else a recommended event with the correct meaning? → use its exact
name + params. Else → a custom event tied to a product outcome. *Never* pick a recommended event
just because its name is convenient — its documented meaning must match the behavior.

**Enhanced-measurement caveats:** `scroll` = a single 90%-depth event (not 25/50/75/100); `click` =
outbound links only (not every button); `form_submit` = a submission was detected (not that the
backend accepted it); for SPAs verify page-view behavior after route changes and prevent double count.

**Website Preview ownership follows the same hierarchy.** GA4 Auto / Enhanced Measurement events
remain Google-owned: Tartini AI never edits customer source to add a visual anchor for them. Preview
uses the applicable versioned GA4 collection rule, the real Data Stream/configuration facts that
are available, and current runtime DOM/state. Always-collected page/session events are page chips;
element-related Enhanced Measurement events receive boxes only for runtime matches verified by that
adapter. Unknown GA4 Admin configuration remains unknown.

**Implemented configuration source.**
A project-scoped, read-only `google_analytics` connection exact-matches the setup Measurement
ID to one accessible Web Data Stream and caches its Enhanced Measurement settings. It is separate
from the `google` managed Service Account connection for BigQuery event data, including separate
credentials, state, and business logic. BigQuery may read export data, run SQL, and manage tables/views/
materializations or schedules exactly where the service account's current read, Job User and Output Dataset
permissions allow; missing access guides that capability only. None of those capabilities comes from
`google_analytics`. An explicit disabled setting is authoritative: source, runtime and AI cannot call
that event enabled or tracked. Missing connection/snapshot/fields stay unknown; runtime decides only
current-page location. When no usable snapshot exists, preserve the current behavior rather than hiding events:
include the complete existing GA4 auto/enhanced catalog and run its provider/runtime/AI locating workflow,
labelling every result `fallback_default`, candidate, and missing Data Stream configuration. A connection is an
evidence upgrade, not a Preview gate.
The backend provider registry owns the setting dependency map, and Website Preview plus bookmarklet
consume the same canonical tri-state/fallback result.
See DESIGN §8.1 and the connections design §20. Do not imply that Tartini AI has verified a customer's
Admin configuration unless that Project has a usable matched snapshot.

Recommended/custom events emitted by customer code are customer-owned. A new event's
reviewed diff must carry its event call, trigger contract, and parameters. Tartini AI generates
clean standard GA4 code via a thin helper `trackEvent(name, params)` that delegates directly to
`window.gtag('event', name, params)`. No Tartini-namespaced DOM attribute (`data-toastia-*`),
payload field (`__toastia*`) or `tb_` identity is introduced into the customer's codebase — the
Candidate gate refuses a change that adds one.

The rule applies to direct calls and `initiates_then_confirms`: the latter keeps the emission in the
real confirmed-success branch (e.g. after order submission succeeds), rather than prematurely
firing on a button click. Page/business-state non-visual events and GA4 automatic events require no
fabricated element markers.

**Tartini WebAutocapture as best practice:** When `get_tracking_state` reports it absent or partial,
Tartini AI normally recommends Tartini Autocapture before further business events
([`tracking-recommendation-policy.md`](./tracking-recommendation-policy.md)), and installs (or
upgrades) it with `enable_autocapture` only when the user agrees. A `partial` installation is
unfinished, never "installed": asked to enable tracking, Tartini AI finishes it — `enable_autocapture`,
or `rebuild_event_instrumentation` for `auto_click` when the Draft already holds the installation —
and never reports a partial one as done. One fixed, reviewed component is staged verbatim —
`[src/]components/TartiniAutocapture.tsx` (TypeScript React), `TartiniAutocapture.jsx` (JavaScript
React) or `tartini-autocapture.js` next to `index.html` (plain pages) — and mounted ONCE at the root.
On a site of separate HTML pages "the root" is every page that loads the Google tag, after the tag:
it sends through that page's own `gtag`, so it goes EXACTLY where the tag is — never on a page without
it, where it would send nothing (the gate refuses both a dead mount and a tagged page without one;
`autocapture-detector.js`). With no page loading the tag yet, every page.
Its three variants run one core; a page-level guard makes a second mount inert. It sends four events (the
current component is v3) through the page's own `gtag` (`tracking-event-contract.js` `AUTOCAPTURE_EVENT_CONTRACT` is
the one authority for their payloads):

| Event | Required parameters | Optional | What it is |
|---|---|---|---|
| `auto_click` | `element_tag`, `link_type`, `page_path` | `element_role`, `element_id`, `element_label`, `element_section`, `link_path` | a click on a button, link, `[role="button"]`, `[role="link"]` or submit/button input (capture phase, resolved to the nearest control) — a UI fact |
| `auto_form_start` | `form_id`, `form_type`, `page_path` | — | a visitor began a form: the first `focusin` or `input` in one of its fields (capture phase), once per form per page view (a new pathname is a new page view) — an interaction, never a submission |
| `auto_form_submit` | `form_id`, `form_type`, `field_count`, `page_path` | — | the browser's own `submit` event (capture phase, so a React handler that prevents the default still leaves it observable) — an INTERACTION, never proof the submission succeeded |
| `auto_page_engagement` | `page_path`, `engaged_time_seconds`, `max_scroll_depth` | `flush_reason` (`route_change` \| `hidden` \| `pagehide`) | one stretch of ACTIVE time on one page (visible and focused; hidden and unfocused time excluded) and the deepest point of the page reached, 0–100 (a page shorter than the viewport is 100) |

`form_id` is the form's `data-testid`, else `id`, else `name`, else `aria-label`, else `unnamed_form`,
read with `getAttribute` (a form's `id`/`name` property can be one of its own inputs); `field_count`
counts inputs, selects and textareas a person fills — not hidden inputs, not buttons. Submissions
are never guessed from a button's text. `form_type` is read only from the fields' `type` and
`autocomplete`: any `cc-*` token is `checkout`; `new-password` is `signup`, `current-password` `login`
(both: `other`); without those tokens two password fields are `signup` and one `login`; a `type=search`
field is `search`; an email field with only checkboxes or radios beside it is `newsletter`; any other
form with an email or phone field is `contact`; else `other`. A name, label, placeholder or anything
typed never decides it. `element_section` is the nearest `section`, `header`, `nav`, `footer` or `main`:
its `id`, else `aria-label`, else the text of its own first heading (an opted-out, editable or
typed-into heading is never read; a PII-looking value is dropped). `link_type` comes from `href` and
`download` alone (`internal`, `outbound`, `mailto`, `tel`, `download`, `anchor` for a place on the same
page, `none` for no link or a `javascript:` or non-web address); `link_path` is an internal link's
pathname only, PII segments `(redacted)`. At most 8 keys on `auto_click`, 5 on a form event, and no
value over 80 characters (`AUTOCAPTURE_LIMITS`). An engagement stretch is sent once when it ends — on a
single-page route change (the History API wrapper is reversible and never breaks navigation), when
the page is hidden, or on `pagehide`, never on `unload`; a `pagehide` right after a hidden flush sends
nothing more, returning to the page opens a new stretch for the same pathname, and a stretch with less
than one second of active time is not sent. Downstream, one visit is the SUM of its
`engaged_time_seconds` and the MAX of its `max_scroll_depth`. The depth of a page left by a route
change is its high-water mark up to that moment: the document may already show the next page, so it is
not re-read then.

**One privacy layer, every event.** `data-no-track` on an element or any ancestor opts the whole
subtree out; password and hidden inputs, textareas, selects and editable regions are never read (a
control that contains one is labelled only by `aria-label`/`title`); no input value, form data or
request body is ever sent — not even a length; a label, id or form id that looks like an email, phone
number, card number or SSN is dropped; `page_path` is `location.pathname` only (no query string, no
hash, no full URL), with PII-looking segments replaced by `(redacted)`.

**The policy:**
1. Semantic business outcomes use GA4 recommended events first.
2. A GA4 automatically collected or Enhanced Measurement event is never re-sent by hand under the same
   name.
3. `auto_click`, `auto_form_start`, `auto_form_submit` and `auto_page_engagement` are the reserved, fixed
   Tartini Autocapture namespace: never created, renamed to or redefined as ordinary events. `enable_autocapture`
   installs or upgrades them; removing `auto_click` (the anchor) removes all of them; a lone member is
   never removed, retried or rebuilt on its own.
4. `page_view` stays GA4's: Tartini Autocapture never sends it, never sets `send_page_view` and never
   changes Enhanced Measurement.
5. Tartini Autocapture never sends `scroll`: precise depth is `auto_page_engagement.max_scroll_depth`.
6. `auto_form_start` and `auto_form_submit` are form interactions, not a business success: a form begun is
   not a lead and a form submitted is not a sign-up.
7. `auto_click` beside a semantic event from the same interaction (`auto_click` + `add_to_cart`) is
   correct: different names are not double logging, and neither is suppressed. What Tartini prevents
   is the SAME meaning twice (a second `page_view`).
8. Free-text input values are never collected.
9. Phase 1 (Autocapture first): a critical outcome is read from the closest GA4 or Autocapture signal
   and says what it counts; it becomes an explicit semantic event only when the person asked for it.
   The one exception is an advertising or acquisition plan: Tartini AI may recommend ONE
   conversion event, the one the ads optimize for (`generate_lead`, `sign_up`, or `purchase` with
   `transaction_id`, `value`, `currency` and `items`), saying in one sentence why, and writes it into
   the Draft only after the person agrees; it then goes through the Pull Request as usual. Every other
   scenario stays Autocapture first.

**Presented as ONE installation.** Installing Tartini Autocapture is one change, not "autocapture + 3
events": its review title names it "Tartini Autocapture" (the AI title prompt and
`review-title-fallback.js` both name the bundle from `AUTOCAPTURE_EVENTS`), and the run page lists
its events under **Autocapture**, never among the custom events it counts. Its durable record is
one anchor Spec, and the draft state projects that anchor's `bundle` (`autocaptureBundle()` — each
event's name, meaning and parameters, from the contract), so **Events in this draft** shows the four
events the installation adds, each marked Tartini Autocapture, with one Remove that removes them all.
The Pull Request's checklist registers the bundle's NUMBERS — `field_count`, `engaged_time_seconds`
(Seconds) and `max_scroll_depth` — as custom METRICS (`AUTOCAPTURE_METRICS`), since GA4 can sum or
maximise only a metric; every other parameter stays a custom dimension. Both checklists compare by
parameter NAME, the unit GA4 registers a custom definition by: they list only the parameters the base
revision does not already send, its installed Autocapture version's own included, so an upgrade from v2
to v3 lists exactly `element_section`, `link_type`, `link_path` and `form_type` (`form_id` was already
sent), and `page_path` is never listed, since the Google tag sends it as GA4's own page path. A base
whose Autocapture version was not recognized claims nothing, and every custom parameter is listed. The conversation history does the same: `event-spec-store.activeNamesByRun` lists the events an
anchor stands for, so a conversation that enabled Autocapture reads "+ 4 events", never "+ 1 event".
The panel offers those cards only what the plan allows — they are never changed one by one or given
another place to fire from — and every sentence on the page about when a change is live reads
`review-state.LIVE_ONLY_WHEN` (merged AND deployed), never "merged" alone. An event the draft adds is
"new in this draft", never "tracked". What waits for the merge is the LIVE SITE, not GA4: a deployed
preview of the Pull Request runs the real Google tag, so its visitors' Autocapture events already reach
the customer's GA4 property, and the page says so. An installation
this Draft adds is "added in this draft", not "on" — the live site sends none of it until the Pull
Request is merged, and the Tracking Assistant says the same (`app/test/review-action-facts.test.js`).

**Beside Enhanced Measurement.** Nothing turns Enhanced Measurement off. When both exist, each question
has one signal (`ga-rules.js` `SIGNAL_OWNERSHIP`), and two different names are never added into one
metric:

| Question | Signal |
|---|---|
| page views | GA4 `page_view` |
| outbound links / file downloads / video | GA4's own events (`click`, `file_download`, `video_*`) |
| precise scroll depth | `auto_page_engagement.max_scroll_depth` — GA4 `scroll` may coexist, but it is one 90%-threshold event, not a depth |
| active time on a page | `auto_page_engagement.engaged_time_seconds`, summed per visit |
| form start interactions | `auto_form_start` once Autocapture is installed — GA4 `form_start` (Enhanced Measurement) may coexist as a provider signal; the two are never added |
| form submission interactions | `auto_form_submit` once Autocapture is installed — GA4 `form_submit` may coexist as a provider signal |
| which UI controls are clicked | `auto_click` |
| did the checkout (sign-up, lead) succeed? | Phase 1: the closest GA4 or Autocapture signal (a `page_view` of the confirmation page, an `auto_form_submit` of the form), saying what it counts; `purchase` (`sign_up`, `generate_lead`) only when the person asked for that event, or agreed to it as an advertising or acquisition plan's one conversion event, and then never `auto_click` or `auto_form_submit` |

**Installed, verified, upgraded.** The component is never edited — the gate refuses a modified one,
a component that does not send the whole bundle with its required parameters, a second mount, and any
event outside the bundle. The detector reports `verified` only when ONE module is proved to handle root
clicks, root submits and the page-engagement lifecycle (`visibilitychange`, `pagehide`, `scroll`,
`popstate` listeners on the document root), sends `auto_click`, `auto_form_submit` and
`auto_page_engagement` (`VERIFIED_EVENTS`, its own table, so an event a newer version adds never makes
an earlier complete version partial), and is mounted at the root; anything less is `partial` with
exactly what is missing. Which official version the site holds is `facts.version` (v1 | v2 | v3 |
null), read from the component's exact bytes (`autocapture-versions.js`); `get_tracking_state` reports
it as `autocapture.installed`, with what an upgrade adds. The official V1 (click delegate and
`auto_click` only) is `partial`, V2 and V3 `verified`; `enable_autocapture` upgrades V1 and V2 in place
(V2 although verified): the installer recognises the exact bytes by SHA-256 and stages the current
component over them as a reviewed change, keeping the existing mount, saved only after the project's own
tests ran. Any other content at that path, including an edited copy of the component, is never
overwritten, and an official copy loaded from another path never gets a second one
(`autocapture_installed_elsewhere`). Autocapture is
context. In Phase 1 it is the tracking a plan is built on; a semantic named business event
(`purchase`, `sign_up`, `generate_lead`) is added only when the person asked for it, or agreed to it as
an advertising or acquisition plan's one conversion event, and then Autocapture complements it rather
than replacing it.

**Candidate finish gate (decoupled from Preview, `candidate-validation.js`):** A Candidate transaction validates:
1. The candidate delta is attributable to this Event operation, and adds no emission of another event
   (one implementation, one event — except a Tartini Autocapture installation, which adds exactly its
   fixed bundle and nothing outside it);
2. Every touched script still parses (a file already broken before the change is a warning);
3. The event is sent by name through `gtag`, `window.gtag`, `trackEvent` or the repository's own forwarder;
4. Its parameters match the Event Spec and GA4's required parameters, with legal, non-PII names;
5. A click/submit/confirmed-state event is sent from inside a function, not at module scope;
6. The Google tag (loaders, `config` commands with their measurement ids, `gtag` definition,
   `dataLayer` initialisation, `@next/third-parties` components) is preserved — additive only;
7. No Tartini-namespaced marker is introduced;
8. Analytics that is configured but not ready yet does not lose an event: on a site whose Google tag
   defines `window.gtag` only after hydration (for example `@next/third-parties` `<GoogleAnalytics>`),
   a send that runs when a component mounts either goes through a forwarder that keeps the call, or
   waits for `window.gtag` in the event's own code — bounded, cleaned up on unmount, sent exactly once.
   "Doing nothing when `gtag` is missing" is right only when analytics is not configured at all. An
   Event implementation does not change what the existing shared helper does while `gtag` is missing
   (that is every other event's delivery);
9. A `transaction_id` is the transaction's business identity — taken from the authoritative record
   (the order or transaction number the server created and stored), stable, non-empty and unique;
   never empty, never a constant, never made on the page (random, clock, UUID, mount id). A refresh or
   a new tab of the same transaction reports the same id; re-sending it is GA4's to deduplicate (web
   purchase events), and no browser storage is added to suppress it;
10. A page-level event happens once per page ENTRY (a full load or a client-side navigation to the
   page); the data it reports is read at that moment, and changes to that data while the visitor stays
   on the page (a quantity, a removed line, a filter) are not new occurrences — so its re-send guard is
   keyed on the entry (a ref, or what the route says the page is about), never on page state.
Preview target resolution is NOT a prerequisite for Candidate completion, Diff review, or PR publication.

**Website Preview (auxiliary, non-blocking):** Preview is an independent visualization and testing aid.
It reads best-effort hints from the element each event's call is bound to and tries them as a 4-tier
ladder (`id` → `tag + safeText` → `tag + stableClasses` → `unresolved`) to highlight elements. It
never intercepts analytics: Google owns transport, so an interaction in any Preview is a real GA4
event carrying the preview's hostname. Website Preview visualizes where tracking applies; it does not
act as a GA4 runtime event debugger — to confirm an event arrived, use GA4 Realtime, DebugView or the
BigQuery export. If Preview cannot locate a DOM target on the current page, it reports `no visual
target on this page`.
A locator miss never blocks Candidate finish, PR creation, or merge.

**PR-review continuation (implemented):** If review feedback changes an Event's meaning, parameters,
or trigger locations, preserve the stable Event identity and route the correction through Event Spec,
Desired Coverage, and the Event implementation Candidate path. If the source correction is not an Event
command, persist it as a replayable ordered review adjustment. Never answer review feedback with an
unmodelled top commit that a later Candidate build can erase, and never post "fixed" before the original
PR branch has been updated successfully.

---

## 2. Naming conventions & GA4 limits

**GA4 rules (authoritative):** event names are case-sensitive, must start with a letter, use only
letters/numbers/underscores, no spaces, no reserved names, and **no `ga_` / `google_` / `firebase_`
prefixes**.

**Team convention:** English `lower_snake_case`; a clear verb-object/outcome form
(`report_created`, `integration_connected`); one semantic meaning per name; don't encode
environment/version/screen/plan in the name (use parameters); never reuse an old name for a
materially different behavior.

| Limit | Value | Note |
|---|---:|---|
| Event name length | 40 | keep under ~24 for readability |
| Event parameters per event | 25 | a useful event needs far fewer |
| Parameter name / value length | 40 / 100 | avoid / sanitize / redact / omit unsafe values (never blindly truncate PII) |
| User properties per property | 25 | reserve for high-value segmentation |
| User property name / value length | 24 / 36 | |
| User-ID value length | 256 | opaque, no PII |
| Custom item params in `items[]` | up to ~27 | use standard item params first |
| Custom dimensions | 50 event-scoped / 25 user-scoped / 10 item-scoped | register only actionable params |
| Custom metrics / calculated metrics | 50 / 5 | |
| Key events | 30 (standard) / 50 (360) | business-critical only |

Do not treat limits as design targets.

---

## 3. Recommended event catalog

GA4's recommended NAMES, for an event the person has asked for. In Phase 1 none of them is recommended
or added otherwise (§3.2), except the one conversion event of an advertising or acquisition plan
("The policy", item 9).

### 3.1 Authentication & user lifecycle
| Event | Fire when | Core params |
|---|---|---|
| `sign_up` | account creation **succeeds** | `method` |
| `login` | authentication **succeeds** | `method` |
| `tutorial_begin` / `tutorial_complete` | onboarding starts / completes | *(no official params; `tutorial_name` is a **custom** param)* |

### 3.2 Ecommerce & monetization funnel (only when the person asks for these events)
Phase 1: GA4's own events, Tartini Autocapture and the events the code already
sends answer first — a click on "Add to cart" is an `auto_click`, an order is a `page_view` of its
confirmation page — and none of the events below is recommended or added unless the person explicitly
asks for it, except `purchase` as an advertising or acquisition plan's one conversion event, written
only once they agree ("The policy", item 9). When they do, use these names, and add only the stages
the product actually has — not every event on every site.
```
view_item_list → select_item → view_item → add_to_cart → view_cart → begin_checkout
  → add_shipping_info → add_payment_info → purchase → refund (when applicable)
```
Plus `view_promotion` / `select_promotion` for promotions.

| Event | Core params |
|---|---|
| `view_item_list`, `select_item` | `item_list_id`, `item_list_name`, `items` |
| `view_item`, `add_to_cart`, `remove_from_cart`, `view_cart` | `currency`, `value`, `items` |
| `begin_checkout` | `currency`, `value`, `coupon`, `items` |
| `add_shipping_info` | `currency`, `value`, `shipping_tier`, `items` |
| `add_payment_info` | `currency`, `value`, `payment_type`, `items` |
| `purchase` | `transaction_id`, `value`, `currency`, `tax`, `shipping`, `items` |
| `refund` | `transaction_id`, `value`, `currency`, `items` |

**Ecommerce parameter requirement levels.** Google's reference marks each parameter `Yes`, `Yes*` or
`No`. `value` and `currency` are `Yes*` on the money events: revenue metrics need them, and `currency`
is required whenever `value` is set. Tartini AI's implementation gate enforces exactly the required set
below (`EVENT_SCHEMA` in `app/ga-rules.js`) — a call without one of them fails — and treats every other
listed parameter as recommended: a warning, never a failure.
- **Required:** `value`, `currency` and `items` on `view_item`, `add_to_wishlist`, `add_to_cart`,
  `remove_from_cart`, `view_cart`, `begin_checkout`, `add_shipping_info` and `add_payment_info`;
  `transaction_id`, `value`, `currency` and `items` on `purchase`; `transaction_id` on `refund`; `items`
  on `view_item_list` and `select_item`. Each item carries **at least one of `item_id` OR `item_name`**.
- **Recommended:** the event-specific params (`coupon`, `shipping_tier`, `payment_type`, `tax`,
  `shipping`, `item_list_id`, `item_list_name`, the promotion fields) and `value`, `currency` and
  `items` on `refund`.
- **Optional:** the rest of the item fields below.

**Standard `items` array fields:** `item_id` / `item_name` (≥1 required), `affiliation`, `coupon`,
`discount`, `index`, `item_brand`, `item_category`(2/3…), `item_variant`, `price`, `quantity`.

### 3.3 Engagement & content
| Event | Fire when | Core params |
|---|---|---|
| `search` | user performs a search | `search_term` (⚠ may contain PII — sanitize) |
| `select_content` | user selects identifiable content | `content_type`, `content_id` |
| `share` | content is successfully shared | `method`, `content_type`, `item_id` |
| `generate_lead` | a business lead is actually **created** | `currency`, `value`, `lead_source` |
| `join_group` | user joins a team/group | `group_id` |

### 3.4 Example SaaS custom events (only if they reflect the real product)
`workspace_created`, `project_created`, `integration_connected`, `invite_sent`, `report_created`,
`export_completed`, and async triples `generation_started` / `generation_completed` /
`generation_failed`. Good names describe **completed business actions**. Avoid `button_clicked`,
`cta_click`, `modal_open`, `feature_used`, `action`, `submit`, `blue_button_clicked`. If a UI detail
matters diagnostically, keep the business event and add a bounded param like `entry_point` /
`creation_method`.

---

## 4. Event & parameter design rules

**4.1 Trigger on the meaningful STATE TRANSITION** (not the click):

| Weak trigger | Better trigger |
|---|---|
| the sign-up form is submitted | the backend confirms the account was created → `sign_up` |
| the payment action is invoked | the transaction **succeeds** → `purchase` |
| an integration flow is opened | the connection becomes usable → `integration_connected` |
| an export is requested | the export is produced → `export_completed` |
| UI renders a success message | persisted business state confirms success |

For critical revenue/lifecycle outcomes, prefer the authoritative backend/transaction system, and
ensure client + server can't both emit the same outcome without deduplication.

**4.2 Parameters** — add a parameter only when the person asked for it (Phase 1: that includes a
parameter on an existing event) and a metric needs the same event broken down a stable way. Document
the type; define an allowlist for categorical values; reuse the same name/meaning across events; use
native numbers; **omit unknowns** rather than inventing placeholders; avoid free text; avoid params
that duplicate built-in GA4 dimensions.

**4.3 Cardinality** — high-cardinality dimensions push GA4 into an `(other)` row. **Strong default
(not an absolute):** don't register as custom dimensions user IDs, session IDs, timestamps, request
IDs, transaction IDs, per-object IDs, or full URLs — unless there's a documented reporting need and
Google doesn't prohibit the configuration. If a high-cardinality id is needed for debugging/joins,
collect it only after privacy review and analyze it in BigQuery. (User-ID has a dedicated mechanism —
see §5 — never a custom dimension.)

---

## 5. User properties, User-ID, custom dimensions

- **User properties** = stable segmentation attributes (`plan_tier`, `account_type`, `user_role`,
  `lifecycle_stage`, `region_group`). Not for actions, changing request state, unique ids, or PII.
- **Event parameters** = contextual attributes of one event instance (`search_term`, `filter_applied`).
- **User-ID:** an opaque internal id (no PII). Set it as a GA4 **config** setting — NOT an event
  param, NOT a user property, NOT a custom dimension. Don't send before sign-in; set to `null` after
  sign-out. `gtag('set', { user_id })` after login; `gtag('set', { user_id: null })` after logout.
- **Custom dimensions/metrics:** sending a param does **not** make it reportable — register it in GA4
  Admin → Custom Definitions when UI reporting is needed. Prefer predefined dimensions; register only
  fields a team will actually use; expect 24–48h before reportable; use BigQuery for raw/high-cardinality analysis.

---

## 6. Key events
A **key event** represents a business-critical action. Good: `sign_up`, the agreed activation
outcome, `generate_lead`, `purchase`, a high-value product outcome. **Never** mark every page view /
click / funnel step / generic engagement / diagnostic. Marking affects reporting from configuration
time (no backfill). Keep a key-event register (event · meaning · owner · counting method · value · ads?).

---

## 7. Ecommerce specifics
- **`purchase`**: `transaction_id` (unique — prevents duplicates), `items`, `value` = Σ(`price ×
  quantity`) **excluding tax/shipping**, `currency` (required when `value` is set), separate `tax` /
  `shipping`. Fire it **once, after an authoritative transaction success**. This does not require
  server-side transmission — a reliable client event triggered by server-confirmed order state is
  fine — but never fire it on a mere "Buy" click, and dedupe if client + server can both emit it.
- **`refund`**: send with the original `transaction_id` (+ item data for item-level refunds).
  Reconcile purchase/refund totals with the billing source of truth.
- **Subscriptions**: use `view_item` / `begin_checkout` / `purchase` for the commercial funnel (plan
  as an item); use backend/billing for authoritative MRR/ARR/churn/renewal.

**Paid traffic is a fact read from the GA4 export, never assumed.** Whether the site gets Google Ads or
other paid visits decides a metric template's version. `get_tracking_state`'s `googleAds` says whether the
GA4 property is linked to Google Ads and which Google Ads tags (`AW-`) the site loads; what GA4 RECEIVED
is this query's. Check it first (`query_bigquery` with `dryRun`), then run it with `@start_suffix` 30 days
ago and `@end_suffix` yesterday (`'YYYYMMDD'`). A Google Ads session is one GA4 names a Google Ads
campaign for, or that carries a `gclid`; a paid one also has a paid medium (the GA4 export SQL reference
§11's paid channels), read from GA4's last click, else the session's first collected source (§12).

```sql
-- Paid sessions in the last 30 days. Read-only: dry-run it, then run it.
WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id' LIMIT 1) AS session_id,
    event_timestamp,
    session_traffic_source_last_click AS lc,
    collected_traffic_source AS cts
  FROM `<project>.analytics_<property id>.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix
    AND device.web_info.hostname IN ('<production host>')
    AND user_pseudo_id IS NOT NULL
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    LOGICAL_OR(lc.google_ads_campaign.campaign_id IS NOT NULL OR cts.gclid IS NOT NULL) AS google_ads,
    ARRAY_AGG(CASE
        WHEN lc.cross_channel_campaign.source IS NOT NULL
          THEN STRUCT(LOWER(lc.cross_channel_campaign.medium) AS medium, LOWER(lc.cross_channel_campaign.campaign_name) AS campaign)
        WHEN lc.manual_campaign.source IS NOT NULL
          THEN STRUCT(LOWER(lc.manual_campaign.medium) AS medium, LOWER(lc.manual_campaign.campaign_name) AS campaign)
      END IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS last_click,
    ARRAY_AGG(IF(cts.manual_source != '(direct)',
        STRUCT(LOWER(cts.manual_medium) AS medium, LOWER(cts.manual_campaign_name) AS campaign), NULL)
      IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS collected
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
),
traffic AS (
  SELECT google_ads, IFNULL(last_click, collected) AS t FROM sessions
)
SELECT
  COUNT(*) AS sessions,
  COUNTIF(google_ads) AS google_ads_sessions,
  COUNTIF(google_ads
    OR IFNULL(REGEXP_CONTAINS(t.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$'), FALSE)
    OR IFNULL(t.medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm'), FALSE)
    OR IFNULL(REGEXP_CONTAINS(t.campaign, r'cross-network'), FALSE)) AS paid_sessions
FROM traffic
```

---

## 8. Privacy & PII (hard rule — see also NO-PII in DESIGN.md)
Google prohibits sending data it could recognize as PII. **Never** send — via event names,
parameters, user properties, User-ID, page URLs/paths/query/titles, search terms, form values,
campaign params, or free-form error messages — any: names, emails, phone numbers, government ids,
precise location (finer than ~1 sq mile), or other PII. Operating controls: inventory every field
sent to GA4; sanitize URLs/titles; strip or bucket user-entered values; consent controls per
jurisdiction; restrict GA4/BigQuery access; privacy review before adding any identifier or free-form
field. This is not legal advice.

**Consent comes before the tag.** Before installing the Google tag, find out whether the site asks
visitors before analytics runs: a consent manager (OneTrust, Cookiebot, Usercentrics, Didomi, Osano,
Termly, CookieYes, iubenda, Quantcast, Klaro), a consent module of its own, or Google Consent Mode
already in the code. Where it has one, the tag goes THROUGH it — registered for the analytics category
with the site's own API, or Consent Mode defaults set to denied before the loader and updated when the
visitor agrees — and whatever that mechanism requires of something new (a category declared in use, a
version raised) is part of the same change. The mechanism goes where the tag goes: on a site of
separate pages the tag goes on every page a visitor opens as its own document (Google's own
instruction), and a tagged page that does not load the consent mechanism yet gets it — the tag is
never narrowed to the pages that happen to run it today. Never load analytics before consent on a site
that asks for it, and never write a tag where the site's own tests forbid one outside its consent gate.
Changing HOW a site asks (which regions are asked first, collecting by default with an opt-out, Consent Mode,
a traffic total that does not depend on consent) is the `ga4-bigquery-consent` skill's: load it. A request to change
it is the person's yes, and the change is made in that turn; a question that asks for a recommendation waits for
their answer.
The install brief names the files and consent-manager scripts to read first
(`ga4-baseline.consentCandidates`); which mechanism it is, and how a tag is registered with it, is
read from the code.

---

## 8a. One tag on every page, one page view per page, no record a query cannot tell apart
Each rule is Google's own, linked in §13.

- **Every page.** Google: put the tag "on every page of your website" — every page a visitor opens as
  its own document, or a single root once. Where a plan's actions happen is not a page list: page
  views, sessions and returns count on every page. A page is left out only when the person or the plan
  says so in so many words. The consent mechanism goes with the tag (§8); Autocapture goes where it is.
  Google's place for the tag is the page's `<head>`: the new scripts go there, deferred, never after the
  page's own scripts (a site's own code or tests may depend on which of its scripts comes last).
- **Never log two records nothing tells apart.** One action reaching GA4 twice must differ in a
  parameter, so a query can keep exactly one; identical rows cannot be deduplicated afterwards, and
  GA4's own reports stay doubled.
- **A page inside another page** (an iframe of the same site) still loads the tag — its clicks and
  forms happen there — with page views off: Google's "Block a page_view event … for example if you have
  an iframe loading" (`send_page_view: false`, set on every page; it does not carry across). The page
  around it sends the page view on load and on its own history changes (`pushState`, `replaceState`,
  `popstate`), so a shell that shows its frame's address counts each page once. Each page decides at
  load and says which layer it is with every event, in the same `config` — Google sends `config`
  parameters "with every event on the page" and recommends `config` over `set` for custom ones:
  `gtag('config', ID, { send_page_view: top, page_frame: top ? 'top' : 'framed' })`, where
  `top = window.top === window.self`.
- **Google's one limit:** a history-change page view is still sent inside a frame with
  `send_page_view: false`, and its only switch is stream-wide. That row says `page_frame: 'framed'`, so
  page views are counted where `page_frame` is `'top'` or absent. Say which framed pages rewrite their
  address. The parameter is in the BigQuery export with no setup; register it as an event-scoped custom
  dimension to filter GA4's own reports by it (up to 48 hours).
- **A secret in the address** (an invitation token, a reset code, an email address): the page is tagged
  like any other, and what it sends is cleaned first. Google: "if there is any possibility your URLs,
  URL parameters, or titles contain PII, you'll need to remove it" — clear it from the address before
  the tag reads it, or pass `page_location` without it in the `config`. GA4's Data redaction (stream →
  Redact data → URL query parameters) is Google's safety net, not the fix, and does not reach `#`.

Contrast: a shell around the app's pages → the shell sends page views; framed pages have them off and
still send clicks. Which document is the shell is the SERVER's answer, not a file name: a document it
sends in place of many addresses' own pages is the top-level page of every one of them — read its routes. A same-site widget embedded in many pages → page views off. A page never framed →
`page_frame: 'top'`, page views on — one loader, no special case.

---

## 9. Validation & QA
**DebugView / Realtime** — validate realtime payloads (`gtag('config', ID, { debug_mode: true })` or
`debug_mode:true` on a test event; **omit** the param to disable — `debug_mode:false` does not
disable it). Filter developer traffic. **Pre-release checklist:** every event maps to a
question/metric · no duplicated automatic events · recommended events use exact names/params · custom
names comply with GA4 rules · trigger is the correct state transition · success events don't fire on
failures · one action ≠ duplicate events · required params present + typed · values follow the
allowlist · **no PII / free text** · User-ID correct before/after login and after logout · purchase
`transaction_id`/`value`/`currency`/`items` correct · consent verified. **Post-release:** verify
arrival in Realtime/DebugView, reconcile critical counts with the backend, verify custom
dimensions/key events after the 24–48h window; **BigQuery** for reconciliation (duplicate
transaction ids, param completeness, funnel ordering, client-vs-server duplication).

---

## 10. Anti-patterns (avoid)
1. Logging every click. 2. Encoding dimensions in event names (`funnel_report_created` × N → use
`report_created` + `report_type`). 3. One generic `feature_used` for everything. 4. Firing outcomes
on clicks. 5. Duplicating automatic events (double-counted page views/sessions). 6. Treating GA4 as
the billing ledger. 7. Registering every parameter as a custom dimension. 8. Sending object IDs as
report dimensions. 9. Sending free text. 10. Changing event semantics without a migration/new event.
11. Marking too many key events. 12. Using custom timestamps/session ids as dimensions.

---

## 11. Definition of done
An event is production-ready only when: its business question + dependent metric are documented; its
name/semantics follow the selection hierarchy; its exact trigger is testable; params have types +
allowed values; privacy classification approved; passes DebugView/Realtime; critical counts
reconcile with the authoritative system; custom definitions + key-event settings configured when
required; an owner is assigned.

---

## 12. How Tartini AI applies all of this — product reference (not official GA4)

> This section is Tartini-specific implementation guidance, **not** an official GA4 requirement.
> Google's requirements (§0–§11) and the PII rules (§8) remain authoritative and non-negotiable.


Encoded in `ga-rules.js` + enforced by the Candidate gate (`candidate-validation.js`, `google_tag_damaged`):
1. **Additive-only** — never remove/rewrite a working GA install; never touch the GA loader.
2. **The Measurement ID** — a repository that already reads it from its environment keeps that; a NEW
   Google tag writes it once, as a constant beside the tag, the way Google's own install code does
   (it is public, and an environment variable nobody set would make the tag send nothing). A new tag
   adds no dependency: `next/script` in Next.js, Google's gtag.js snippet elsewhere.
3. **Recommended events + intent mapping** — map the INTERACTION to the official name: an
   add-to-cart interaction → `add_to_cart`, starting checkout → `begin_checkout`, a confirmed
   order → `purchase`; custom `snake_case` only when none fits (§1).
4. **snake_case, no ids/variables in names, no PII params** (§2, §8).
5. **Ecommerce schema** — `purchase` on the server-confirmed order with `transaction_id`, `value`
   (excl. tax/shipping), `currency`, `items[]` (§7).
6. **Plain GA4 delivery** — the repository's own thin first-party helper (e.g. `trackEvent` →
   `window.gtag('event', …)`) when it has one; otherwise a direct `gtag('event', …)` call is standard.
   A tracking-plan + custom-dimensions checklist go in the PR body.
7. **Trigger on the meaningful state transition** (§4.1) — prefer the server-confirmed outcome; for a
   page-effect event (e.g. `begin_checkout` fired from a checkout-page `useEffect`) that is a
   page-level event in the preview.

**SDK-vs-user-code boundary:** The site owns its standard analytics tracking code: explicit `trackEvent`
helper calls and the optional Tartini Autocapture root delegate component. The agent edits site-level
tracking code only via Candidate diffs; it never damages or alters the base Google tag loader script.

**Agent source boundary:** Tracking uses the same Tartini AI MCP control plane as Tables and Dashboard.
The model never touches the host or GitHub. It works in its turn's sandbox: a code workspace filled with
the exact Candidate (`open_code_workspace`), where OpenCode's read, search and edit tools are confined to
that directory and its shell runs only read-only git and the project's own build, test, lint and
dependency commands, with no network. What it writes reaches the Candidate only through
`finish_event_implementation`. `GitHubRepository` is the only production source provider. Tartini AI owns exact revision, Candidate replay, validation, approval-gated
publication and receipts. This does not change the analytics rules or SDK-vs-user-code boundary.
Canonical
architecture: `../overall/unified-toastia-mcp.md`.

**One Assistant entry (implemented):** a user question, source inspection, Event change and PR
request all enter one Tartini AI (`project_assist`) turn. The Agent may answer or use one or more scoped
tools; there is no LLM intent resolver in front of it. Event creation, update, enabling autocapture,
Event removal and rebuild use high-level MCP tools over one deterministic Event lifecycle service.
Server policy, not model interpretation, owns confirmation and external effects. See
`tracking-assistant-single-agent-mcp.md`.

**The assistant creates/updates/removes on request — it NEVER refuses.** A direct, sufficiently
grounded request enters the Event lifecycle immediately; it never
creates an open recommendation card or asks for a second Add click. "What should I track?" is an
advisor question whose recommendations remain ephemeral: the Tracking Assistant's own judgment from
the facts, the source and one written policy
([`tracking-recommendation-policy.md`](./tracking-recommendation-policy.md)) — the foundation first
for a general question, and a direct answer, reasoning hypothetically, when someone explicitly asks
what else to track beyond it. Explicit acceptance of one becomes an ordinary `create_tracking_event` (or
`enable_autocapture`) tool call. An operation record may be written at tool execution for
audit/idempotency, but ordinary chat is not first classified into a command row. Never say
"answer-only" / "can't add" / "open a panel".
(Playbook Rule 12.)

An explicitly named valid custom event is allowed even when it is absent from the GA4 recommended
vocabulary. Recommend a standard name when it fits, but do not silently replace or reject the
user's name. Deterministic validation still enforces lower snake case, reserved-name/prefix rules,
duplicate active-spec rules, parameter limits, and no PII.

**Standard GA4 delivery and decoupled Preview:** Tartini AI writes standard, idiomatic code without
a private binding protocol. Elements carry no Tartini attribute and event payloads carry no Tartini
field. Website Preview uses a best-effort 4-tier locator over source-derived hints (`id` →
`tag + safeText` → `tag + stableClasses` → `unresolved`) to highlight likely target elements in the
DOM; it never wraps or replaces `window.gtag`, and it is not an event debugger: arrival is GA4's own
answer.

Code/diff completion, GA4 implementation validation, runtime target locator resolution, visualization,
and deployed execution are separate receipts. Preview target resolution failure NEVER blocks Candidate
finish or PR publication. The assistant must not claim an event is visible merely because its code was
written, nor describe a preview box as proof of deployed analytics delivery.

**Invariants are rules; implementation technique is a preference.** A tracking change keeps the
application behaving exactly as before (rendering, styling, routing, workflows, and its server/client
character), keeps each event's meaning, delivers plain GA4, and leaves the Google tag and every other
event's tracking intact. Within that, prefer — in this order — the code path the trigger already runs,
an existing compatible boundary (component, hook, helper), a minimal local adaptation such as a small
leaf client component where the framework leaves no other way, and a structural change only when
nothing smaller works. Those are engineering decisions for the implementer, reported after the fact; a
person is asked only about meaning, visible product behaviour, privacy, new dependencies, material
architecture or performance changes, or irreversible data choices. Migrating off Tartini's retired
`data-toastia-event` listener follows the same ladder; the shared listener is deleted once no event
depends on it, and a migration is not complete while the listener still sends the event.

---

## 13. Official Google references
[Set up events](https://developers.google.com/analytics/devguides/collection/ga4/events) ·
[Recommended events](https://developers.google.com/analytics/devguides/collection/ga4/reference/events) ·
[Automatically collected](https://support.google.com/analytics/answer/9234069) ·
[Enhanced measurement](https://support.google.com/analytics/answer/9216061) ·
[Measure pageviews](https://developers.google.com/analytics/devguides/collection/ga4/views) ·
[Block a page_view event (iframes)](https://support.google.com/analytics/answer/10271001) ·
[Google tag configuration](https://developers.google.com/analytics/devguides/collection/ga4/reference/config) ·
[Parameters with every event](https://developers.google.com/analytics/devguides/collection/ga4/event-parameters) ·
[Event parameters](https://developers.google.com/analytics/devguides/collection/ga4/event-parameters) ·
[Naming rules](https://support.google.com/analytics/answer/13316687) ·
[Collection limits](https://support.google.com/analytics/answer/9267744) ·
[Custom dimensions & metrics](https://support.google.com/analytics/answer/14240153) ·
[User-ID](https://developers.google.com/analytics/devguides/collection/ga4/user-id) ·
[Key events](https://support.google.com/analytics/answer/13128484) ·
[DebugView](https://support.google.com/analytics/answer/7201382) ·
[Avoid sending PII](https://support.google.com/analytics/answer/6366371) ·
[Data redaction](https://support.google.com/analytics/answer/13544947) ·
[BigQuery Export](https://support.google.com/analytics/answer/9358801) ·
[Analytics Admin API](https://developers.google.com/analytics/devguides/config/admin/v1/rest) ·
[Enhanced Measurement Settings resource](https://developers.google.com/analytics/devguides/config/admin/v1/rest/v1alpha/EnhancedMeasurementSettings)
