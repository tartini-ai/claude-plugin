# Website Preview — Visualization Playbook (Agent Reference)

**Purpose.** The Website Preview is Tartini AI's core selling point: for EVERY tracked
analytics event it must show *where and when* it fires, best effort, on any site, with
**no hardcoded per-event guess map** — and it is never a condition of tracking correctness. This
document is a **task reference** the agent consults when describing events, analysing GA4 automatic
events or debugging preview rendering:
(a) the Core Reference Heuristics below, and (b) the ledger of real mistakes we hit, so we
generalize from the root cause instead of repeating them. It is **guidance, not a hard
policy** — always ground the result in the actual code, runtime evidence, and the user's
request; apply the heuristics with judgment.

> **Runtime migration note:** Preview evidence, rendering and retry semantics remain unchanged.
> OpenCode + OpenRouter replaces model/coding runtime calls only; it does not become Preview evidence
> and cannot bypass deterministic revision, locator, runtime or provider checks. See
> `opencode-openrouter-runtime.md`.

Everything is driven by one canonical per-event preview record. Event ownership,
visualization type, analysis state, and cardinality are separate dimensions — never collapse one
into another:

```json
{
  "name": "begin_checkout",
  "owner": "custom | ga4_auto",
  "implementation": { "state": "implemented | incomplete | missing", "missingParameters": [] },
  "description": {
    "when": "User starts checkout after reviewing cart",
    "where": "/cart",
    "logs": ["currency", "value", "items"],
    "why": "Checkout button trigger"
  },
  "target": {
    "mode": "element | page",
    "route": "/cart",
    "cardinality": "single | collection | unknown",
    "locators": [
      { "tag": "button", "id": "checkout-btn", "safeText": "checkout",
        "stableClasses": ["checkout", "primary"], "file": "src/Cart.jsx", "line": 42, "routes": ["/cart"] }
    ],
    "selector": null,
    "locatorReason": null
  },
  "analysis": {
    "state": "pending | retrying | resolved | unresolved | failed",
    "attempt": 1
  }
}
```

`locators` are a custom event's best-effort hints, read from the element its call is bound to and
never stored; `selector` is a GA4 automatic event's provider-adapter rule. Which tier (`id`,
`tag_text`, `tag_classes`) matched — or `unresolved` — is decided at runtime, in the page, and
reported beside the box. The spec also carries `draft_source_sha`, `runtime_source_url`,
`interaction_autocapture` and `provider_automatic_events`.

The server builds this record by joining the latest source revision, the event/trigger
contract, provider configuration, and runtime DOM evidence. `run.html` and the bookmarklet render its
canonical projection. The Core Reference Heuristics below document the deterministic locator and
the GA4 analysis; no prompt carries them. Tartini AI's Tracking guide carries "What the person sees in
the Website Preview" (`app/agent-references.js`), and `read_guide` returns any other section whole.

`code` is diagnostic evidence, not a third visualization type. If a code-fired event truly has no DOM or
page target (e.g. background job or pure server state), list its file:line honestly as non-visual; never
turn it into a fake page-level event.

### Permanent product contract

1. **Preview is decoupled from correctness.** Preview is an auxiliary visualization and testing tool.
   A locator miss ("No visual target resolved") NEVER fails a Candidate transaction and NEVER blocks
   Pull Request creation, review, or merge.
2. **Pure gtag canonical path, no private markers.** Tartini AI writes standard GA4 tracking code
   (`trackEvent` -> `window.gtag('event', name, params)`). No Tartini-namespaced attribute
   (`data-toastia-*`), payload field (`__toastia*`) or `tb_` identity is written into customer
   source code, and `candidate-validation.js` refuses a change that introduces one.
3. **4-Tier best-effort DOM locator** (`public/target-resolver.js locatePreviewTarget`), over hints
   read from source by `preview-locator.js`:
   - **Tier 1 (`id`, 1.0):** the element's literal `id`.
   - **Tier 2 (`tag_text`, 0.8):** tag + normalized, number-free static text (only if unambiguous for a single target).
   - **Tier 3 (`tag_classes`, 0.6):** tag + stable author-written classes (only if unambiguous).
   - **Component element (`component_props`, 0.5):** a call bound to a component (`<Link>`,
     `<ui.Button>`) has no readable DOM tag, so its hint is the STATIC evidence written on it that a
     component forwards to the element it renders — static text, stable classes of a static
     className, and static `href` (or the static prefix of a template href) / `aria-label` / `title` /
     `name` / author `data-*`. It matches only an element that carries EVERY piece, among the elements
     an interaction can be bound to (controls, links, forms — never a heading or wrapper). See Rule 5.
   - **Tier 4 (`unresolved`, 0):** zero matches, only hidden matches, or ambiguous multiple matches.
   Ambiguous matches never pretend to be resolved. Hints are never stored: there is no locator table
   and no tool that edits one.
4. **Google owns transport, and the Preview is not an event debugger.** No Preview surface — relay,
   PR preview, live frame, bookmarklet — overrides, wraps or replaces `window.gtag` or
   `dataLayer.push`, and no bridge reads the dataLayer or observes network traffic. Every surface runs
   `customer code -> window.gtag -> Google tag -> GA4`, so an interaction in the Preview is a REAL
   event in the customer's GA4 property, carrying the preview's hostname. **Website Preview
   visualizes where tracking applies; it does not act as a GA4 runtime event debugger.** There is no
   Event Inspector: to confirm an event arrived, use GA4 Realtime, DebugView or
   the BigQuery export on a PR Preview or production. The old relay dry run
   (`public/analytics-dry-run.js`) is deleted too; never bring back a recorder, a passive network
   observer or a gtag tap for this.
5. **There are exactly two visualization modes:** `page` and `element`. Page-level means the
   verified trigger belongs to the route/document/viewport as a whole. Element-level means one or
   more concrete DOM elements fire the event and receive boxes.
6. **All click-triggered events are element-level.** Locate the real actionable element, navigate
   to its route, safely satisfy reversible preconditions, scroll it into view, and pulse its box.
   If locator cannot find the element, report `no visual target on this page` without degrading the
   event's semantic classification.
7. **Collections render every real match.** Locating focuses one verified example; rendering
   locates and boxes all matching triggers matching the locator pattern or GA4 runtime rule.
8. **Descriptions are projections of structured facts.** `when` comes from the trigger/provider
   contract, `where` from verified runtime routes and targets, `logs` from the real custom call or
   provider schema, and `why` from the handler or business-state relationship.
9. **Website Preview and the bookmarklet consume the same canonical spec and source
   revision.** They must agree on mode, route, boxes, description, progress, errors, and locator state.
10. **Rendering never waits for AI when deterministic evidence exists.** Locator derivation and
    resolution, GA4 rule matching, route observation, match counting, geometry, and box drawing are
    deterministic code. AI is reserved for custom-event descriptions, the GA4 automatic-event class
    analysis, safe navigation help, and natural-language explanation — it never locates a custom
    event.

---

## What the person sees in the Website Preview (for Tartini AI)

What Tartini AI tells a person about the Preview beside their Tracking draft, in their words:

- It shows their real site with the tracked events drawn on it. A **solid box** marks an element an
  event in the code the live site is built from fires on; a **dashed box** marks one that is new in
  this draft — the live site cannot send it until the Pull Request is merged and deployed.
- A **page-level event** (GA4's `page_view`, a custom event fired when a page renders) is a **chip** in
  the strip above the page — filled when the live site sends it, outlined and dashed when it is new in
  this draft. An element event with no box on this page is listed in the strip below it.
- With Tartini Autocapture installed (proved `verified` in the code), every element it observes gets
  an `auto_click` box. Form submissions and page engagement have no boxes: they are page-level signals.
- **The Preview is not an event debugger.** It shows WHERE tracking applies, not whether an event
  arrived; that is GA4's own answer — Realtime, DebugView, later the BigQuery export. Once a change is
  live, Tartini AI asks it in the conversation, one call each: which deployed pages load the tag
  (`check_site_tag_coverage`) and what GA4 received after the person's visit (`read_ga4_received_events`,
  GA4's Data API) — `tracking-assistant-single-agent-mcp.md` §4.x‴. Neither runs in the Preview.
- **A click in the Preview is a real GA4 event**: the page runs its own Google tag, so it reaches the
  customer's property with the Preview's hostname. That is why production metrics filter hostnames.
- A box that cannot be found on this page is said plainly ("no visual target on this page"); it never
  blocks the draft, its checks or its Pull Request.

## Core Reference Heuristics

> You explain WHERE and WHEN each analytics event fires and help navigate to one example,
> **grounded only in the supplied code, provider contract, and runtime evidence**. You do not draw
> boxes and you never replace deterministic evidence with a guess.
>
> 1. **First identify the owner.** For a custom event, classify from its real trigger contract and
>    code. For GA4 Auto / Enhanced Measurement, use the supplied provider rule/configuration and
>    runtime matches; never pretend its event name means every visually similar control is tracked.
> 2. **Classify custom events from the REAL trigger, not the event name.** Read the code to decide what the
>    event fires on: a whole-page render/effect → `target.mode:"page"`; a specific element →
>    `"element"`. A server/callback with no visual target remains an honest non-visual diagnostic,
>    not a third visualization mode and not a page-level fallback. The same analytics name can be
>    different types on different sites. Most wrong renders come from classifying by vocabulary
>    instead of by this project's trigger.
> 3. **Source-derived 4-tier locator.** Derive element locators directly from inspected source code
>    (DOM ID, tag + normalized text, or tag + stable classes). If Preview cannot resolve the element
>    in current DOM, report `unresolved` honestly; never guess or fake a match. Locator failure is non-blocking.
> 4. **A GA4 analysis candidate must match the RENDERED DOM.** An `onClick={fn}` / `@click` / `on:click`
>    handler in React/Vue/Svelte is a framework prop, **not a DOM attribute** — `[onclick*="fn"]`
>    matches NOTHING there. Use `[onclick*="fn"]` ONLY for literal inline HTML `onclick="fn(...)"`.
>    For a framework handler pick a rendered attribute: className, id, `data-*`, role, or an
>    `href` pattern (`a[href^="/product/"]`).
> 5. **List/collection events box EVERY item.** A collection locator resolves and highlights all
>    matching triggers in the current view. A GA4 automatic collection uses every live DOM match
>    returned by its provider adapter. Locating may focus one example; rendering never stops after that example.
> 6. **Whole-page triggers are CHIPS, not boxes** — but decide by the verified trigger, not the name.
>    An event fired from a page load / render / `useEffect` → `visualize:"page"` with the right
>    `page`; the UI lists it in the page strip like `page_view`. Do NOT assume a named event always has one
>    type: the SAME event name can be page-level on one site (fired from a success/render effect)
>    and element-level on another (fired from a control), and a list event can be page-level or
>    per-item. Decide from THIS project's real trigger, never from the name. Never box a random
>    element for a page-level event.
> 7. **GA4 automatic targets come from provider/runtime rules, never Tartini markers.** Page/session
>    events are chips; viewport behaviors are page indicators; element-related Enhanced
>    Measurement events are boxed only when the versioned GA4 adapter verifies each current DOM
>    match under the known configuration. Unknown GA4 Admin configuration remains unknown. An
>    explicit Admin `disabled` result never starts AI location work and never draws an active box.
>    If no usable snapshot exists, do not remove the event: preserve the current full-catalog
>    provider/runtime/AI fallback and label its result as unverified configuration evidence.
> 8. **Gated elements get `preconditions` — SAFE actions only.** Emit ordered auto-drive steps
>    (goto/click) to reach the observable state (empty cart → add item → cart → box the checkout
>    button). Navigation and **reversible** reveals (open a menu/modal, add a test item, fill a
>    field) are allowed. **Never** emit a step that executes an irreversible/consequential action:
>    completing a purchase, submitting payment, deleting, publishing, sending an invitation/message.
>    Stop the auto-drive BEFORE any final/irreversible action — box the trigger, don't fire it.
> 9. **Enclosing trigger = the function that WRAPS the call, not the call line.** Walk ABOVE
>    the firing line; a call such as `gtag('event', … reduce(fn(){…}))` is NOT a declaration.
> 10. **Never fabricate a precise location.** Not ready → `retrying` with the real
>    attempt/error. A click/element target that cannot yet be found remains element-level and is
>    retried; it never becomes a whole-page highlight. A conclusive non-visual event may show its
>    file:line outside the visualization modes. No hardcoded per-event map.
> 11. **Cardinality is a SHAPE, not a count.** `single` means FIXED targets — not the repeated items
>     of a list/map/loop — and one event may have SEVERAL of them, in different components; box every
>     one. `collection` means repeated items from one list/map/loop; box them all, with a stable
>     per-item identity. The only count that is always an error is ZERO. What IS still an error is one
>     INFERRED locator (an AI candidate) standing for several elements of a fixed target: a guess that
>     matched four things has not identified one. Never silently box the first.

---

## The one question that decides everything: what does the event fire on?

| Fires on… | `visualize` | Preview shows |
|---|---|---|
| a **page load / render / effect** (whole page) | `page` | a labelled **chip** in the strip above the page (like the GA4 auto chips) |
| a **specific element** (button / link / form / card) | `element` | a **box** on that element (every match) |
| a **server/callback** with no visual target | none (diagnostic) | the file:line and reason; never a fake page chip or box |

---

## Rules (detail)

### Rule 1 — Selectors MUST match the RENDERED DOM (framework-aware) — the #1 recurring bug
```jsx
<Link href={`/product/${slug}`} onClick={selectItem} className="card">  // React/Next
```
`onClick={fn}` is a JSX prop; the rendered `<a>` has **no `onclick` attribute** → `[onclick*="selectItem"]`
matches zero elements. Use a rendered attribute (`.card`, `a[href^="/product/"]`, `data-*`, id, role).
This applies to a GA4 class analysis's selector; a custom event's hints are read structurally from the
bound tag (Rule 6) and never written as CSS by a model.

### Rule 2 — List / collection events box EVERY item
For a custom collection event, the collection locator resolves and highlights all matching triggers
in the current view; for a GA4 automatic event, use every live match returned by the provider adapter.
`drawOverlays` boxes every verified match.

### Rule 3 — Page-level events are CHIPS, not boxes
`visualize:"page"` + correct `page`; the client lists it like `page_view`/`session_start`,
gated to that page via the bridge's reported `path`. Never box a random element or leave a transient pulse.
**No indicator is drawn over the page.** Page chips (GA4's always-on events, a custom page-level
event on its page) sit in a strip of their own ABOVE the frame (`#previewPageStrip`), and element
events with no box here in a strip BELOW it (`#previewElementStrip`); both are part of the layout,
are rebuilt on every redraw, and take no room when empty. The layers over the frame carry boxes
only. (The GA4 chips used to be pinned over the frame's top-left — on the site's logo and nav.)

### Rule 4 — Element events auto-drive to their observable state
`preconditions` = ordered `goto`/`click` to reach a gated element (hidden step, empty cart). If a step
can't run, fall back to `goto page` — never strand the user.

### Rule 5 — 4-Tier DOM Locator, and nothing that touches analytics
- **Tier 1 (`id`):** Unique DOM id from source inspection.
- **Tier 2 (`tag_text`):** Tag + exact normalized safe text match (only if unambiguous for single targets).
- **Tier 3 (`tag_classes`):** Tag + stable CSS classes (only if unambiguous).
- **Component element (`component_props`, 0.5 — below every exact-tag tier):** the call is bound to
  a component, whose rendered tag the source cannot name. The hint carries the component's name (for
  a person; it is NEVER matched — no `if name === 'Link'` exists anywhere) and its static forwarded
  props (`preview-locator.js forwardedAttrs`: `href` equals or static-prefix, `aria-label`, `title`,
  `name`, author `data-*`; plus static text and stable classes). The runtime matches them as a
  CONJUNCTION on one element: an `href` hint only among `[href]` elements, any other only among the
  shared actionable controls plus forms. Cardinality decides how many may match: a declared single
  target exactly one; a collection every match; an undeclared one several only when they are
  identical copies of one element (same tag, same class attribute — what one JSX element inside a
  repeated component renders). A match containing another match is ambiguous. A component from
  node_modules works the same way, because only the props written in THIS repository are read. A
  retired Tartini marker (`data-toastia-*`, a `tb_` id) and any computed value are never evidence;
  a component with nothing static on it keeps reason `component_element` and draws no box.
  **What it cannot rule out:** a second, identical-looking element (same tag, classes and static
  props) that the page renders from code that does NOT send the event is indistinguishable at
  runtime — the same limit the exact-tag tiers have.
- **Tier 4 (`unresolved`):** Zero matches or ambiguous multiple matches remain unresolved.
- **No interceptor:** no bridge touches `window.gtag` or the dataLayer, and there is no
  `toastia:analytics_event` / `toastia:getAnalyticsEvents` message any more. Every event the previewed
  page sends reaches GA4 as it would on the live site.
- **Tartini Autocapture:** when the source proves it `verified`, the preview draws a dashed
  `auto_click` box on every element the component observes (`discoverAutocaptureTargets`: its own
  selector and skips). A click sends `auto_click` through the page's own gtag. A partial or absent
  install draws nothing. `auto_form_submit` and `auto_page_engagement` get no boxes and no locator:
  they are page- and form-level signals sent through the same gtag, and whether they arrived is GA4's
  answer (Realtime, DebugView, the BigQuery export), not the Preview's. The Autocapture layer is the
  ONLY way the Preview shows the bundle: no per-event "no visual target" pill is drawn for any of its
  three events (it once said "auto_click · no visual target" beside the auto_click boxes). A missing
  box elsewhere says the event "is still in the code", never "still tracked" — an event the draft adds
  is not sent by a live site that does not run it yet.
- **Boxes are measured in the layout they are drawn over.** The frame is sized by
  `public/preview-frame-size.js`: it GROWS only when the document overflows it (the relay's docH is
  `scrollHeight`, never smaller than the frame, so "docH + margin > frame" grew it on every redraw), and
  after ANY resize the run page measures again before drawing. On a `min-h-screen` flex page a resize
  moves the footer; drawing rects measured before it put the footer's auto_click boxes a row above the
  links. `app/test/preview-frame-size.test.js` simulates that layout.
- **A page whose height follows its viewport is shown at a visitor's viewport, never chased.** The
  frame IS the page's viewport, so on a page of `vh` units every growth makes the page taller again:
  tartini.ai's landing page (three `76vh` steps) grew 2.28× per redraw to the browser's 16,777,214px
  limit in twenty seconds, each step a longer layout — and a `min-h-screen` main between a header and
  a footer creeps by the two forever. The reading right after a growth decides it: still overflowing
  and taller than before means the page grew with the frame, so the frame goes back to the reference
  viewport (the pane's height, full screen included) and the page scrolls inside it, where the bridge's
  `toastia:scrolled` already redraws every box. Until the next navigation. The frame's height is read as
  a number (`heightOf`): `parseInt('1.67772e+07px')` is 1, which set the limit again on every redraw.
- **One answer per GA4 automatic event.** `gaAutoChipState(e)` feeds the chip row above the Preview and
  the tracked list: an always-on event's tooltip is its own meaning from `ga4-auto-semantics.js` (served as
  `providerAutomaticEvents.meanings` — only page_view fires on every page view), an event the analysis
  found nothing to fire is "nothing in this site fires it" in both rows and is not counted as tracked.
- **Bound to a component is not "bound to no element".** A custom event whose call sits on a component
  (`<Link>`) is drawn through its component hint (above) on the element the component renders — a
  `<Link href={`/product/${slug}`} className="card-img">` is boxed on every `<a href="/product/…"
  class="card-img">`. Only a component with NOTHING static written on it keeps reason
  `component_element` ("no box — its code is bound to <Link> in …, a component"), one of
  `preview-target.TRACKED_WITHOUT_BOX`. Disabled controls get no auto_click box (the browser sends
  them no click). The Deployments banner states the fact and never an App-owner-only instruction.
- **auto_click's placement is the Autocapture layer's boxes, for every reader.** After the per-event
  loop, the run page records the layer's boxes as `codeFoundBoxes[auto_click]`, so the tracked list, the
  legend, the details panel and "locate" all say "N on this page"; `auto_form_submit` and
  `auto_page_engagement` read "page-level — no element box". (The tracked list said "auto_click · no
  visual target" beside 67 auto_click boxes after the overlay pill alone had been fixed.)
- **Decoupled correctness:** Preview failure or locator misses NEVER fail Candidate transactions or
  block PR publication.

### Rule 6 — Associate target elements structurally, not by text proximity
Locators must be structurally derived from the component or JSX opening tag that owns the handler or
interaction. Never guess an association by grabbing classes or IDs from unrelated neighbouring elements
in the source file. A collection carries declared `cardinality:"collection"` and resolves all matching
instances.

### Rule 7 — Correct the enclosing trigger
`call-site-evidence.js classifyHandler` starts the declaration walk ABOVE the firing line (the call's
own line is tried only for the two assignment forms, so a one-line `const pick = () => track(…)` keeps
its name) and excludes string literals from a `name(params){` match, so an event's own call (with a
nested callback) isn't mistaken for a declaration.

### Rule 8 — Coordinate accuracy
Measure every target in ONE read pass and redraw on the signals that move it — the bridge's debounced
`toastia:domchanged`, scroll, resize and route change. Project iframe→parent coordinates through ONE
shared utility (don't duplicate per path). Don't wait for the whole page to be globally stable.
**The address bar follows the page.** The relay bridge pushes `toastia:navigated { path }` for a
new document's first page and for every pushState / replaceState / popstate / hashchange (the
history methods are observed — the page's own original always runs), and every `toastia:rects`
reply carries the same site path; the run page shows it (`followPreviewAddress`, text only). A
locate navigation adds nothing to the page's URL. The bar's label is "Tartini preview · …".

### Rule 9 — Never dead-end, never guess; no hardcoded map
Show `retrying` while a recipe computes. If an element target is not found, keep its element
classification and retry it; never pulse the whole page as if that were the target. If there is
conclusively no visual target, show the code evidence outside the visualization modes.
`CODE_EVENT_TRIGGERS` and every equivalent name→location fallback are forbidden.

### Rule 10 — The preview is an evidence artifact — chat-correctable
A wrong custom-event box means the code sends the event from the wrong element (or the hint is
ambiguous on this page). Chat correction is an update of the Event (`update_tracking_event`): the
reviewed code moves, and the hints are re-derived from the new code. It never creates a parallel
stored selector that could disagree with the code. A wrong GA4 automatic box means the provider
configuration/rule adapter or runtime evidence is wrong; it must not be "fixed" by writing anything
Tartini-specific into customer code.

### Rule 11 — Gotcha: the relay's extras are a STRING
The bridge protocol itself is a plain file (`public/preview-bridge-core.js`), read from disk by the
relay and by the site bridge's build, so it has no escaping trap. The relay's own extras
(`preview-relay.js bridgeScriptBody`) are still a template literal; regexes there need `\\` (a
single `\s` → mangled `s`, `\/?` → invalid `/?`). A mangled regex throws at load and silently kills
the ENTIRE relay bridge (getRects, the Autocapture layer, navigation). `node --check` won't catch it — `bridge-syntax.test.js` compiles the injected JS with
`new Function`. Double every backslash in the relay's regexes.

### Rule 11a — One protocol, two bridges, and a direct frame only after a handshake
Both bridges speak ONE protocol (`public/preview-bridge-core.js`, protocol 2): they answer only their
parent window at one origin, and only in a session. The run page makes a random session per preview
frame and pings (`toastia:ping { session }`); the bridge answers `toastia:pong { session, protocol: 2,
bridge, capabilities, path }`, and from then on every request carries that session and every reply
and notice echoes it. Nothing is observed before the handshake.

- **The relay bridge** is the protocol plus the relay's extras (keeping links in the relay, navigate,
  act, runtime observation, viewability), answering the app origin. The relay is the default view,
  before and after a merge.
- **The site bridge** is one reviewed, dormant file in the customer's own code
  (`tartini-preview-bridge.js`, built from the same three files and pinned by hash). It returns at once
  on a normal visit; inside a frame it answers only `https://tartini.ai`, and only geometry (ping,
  getRects, getAutocapture): it never clicks, navigates, or sends back text, values, cookies or
  storage. It is added only after the person says yes (`add_preview_bridge` on the web; on Claude Code
  the install block `get_tracking_state` carries, written in the developer's own pull request).
- **A pull request's hosted preview** (Stage 2) is found from GitHub Deployments of the head the pull
  request is running, never another commit's, and needs the GitHub App's Deployments: read. The run
  page loads it in a hidden frame beside the relay and swaps it in only on a full protocol-2 pong;
  otherwise the relay stays and the reason is named. The label comes from the deployment record ("PR
  preview <sha7>"); the bridge only proves a current bridge answers.
- **The real site** is framed directly only when the relay cannot show it or the person asks ("Open
  the real site"), after the probe says the current bridge is served there, because a visit there is
  production traffic. A site that refuses to be framed stays on the relay: there is no separate-window
  mode.

## Cross-cutting Tartini AI behavior (NOT preview-location heuristics)

Rules 12–13 are **product/agent behaviors** that touch tracking, not rules for classifying or
locating a preview box. They're kept here for proximity but apply to the add/remove flow and the
patch agent, not to `buildDescribePrompt`.

**In force:** Chat-First Event semantics, the deterministic GA4 implementation gate
(`candidate-validation.js`) and the Candidate Transaction — an immutable exact-revision snapshot, server-owned
Candidate overlay, complete READY-plan replay, content-addressed Draft compare-and-swap and explicit
durable-state compensation. Tracking reaches source only through the shared Tartini AI MCP and
revision-aware Candidate tools; GitHub API services own exact-revision reads and expected-head
publication. There is no customer worktree, checkout or git-CLI publication path.

**In force:** Tartini AI has no LLM-backed pre-router. One `project_assist` invocation
receives the message, history, screenshot and interaction context, then answers or calls scoped
read/Event/PR tools. The Candidate Transaction and every Preview invariant
below remain unchanged. See
`tracking-assistant-single-agent-mcp.md`.

**In force now:** an explicit PR-review action in the same Assistant reads an existing PR comment,
persists its correction through the replayable Candidate plan (an Event command, or a durable
`review_adjustments` artifact in the same total plan order), pushes the same run branch with
remote-head protection, and replies only afterward. It does NOT use the legacy direct-commit
review-chat path. Ordinary chat and reply drafting have no GitHub side effect.

### Rule 12 — The AI assistant executes direct Event lifecycle requests — it NEVER refuses
The chat is not "answer-only". A direct, sufficiently grounded request to create, update (including
where it fires), remove, retry or rebuild an Event, or to install Tartini Autocapture, enters the
Event lifecycle immediately. It never creates an
open recommendation card and never requires a second Add click. An explicit request to accept a
previous advisor recommendation becomes the same ordinary `create_tracking_event` tool call. A question about
what to track is advisor-only; its recommendations remain ephemeral until accepted. The prompt must
never say "I'm answer-only", "I can't add", or "open the Suggested events panel" (there is no such panel).

**Acting is not the same as guessing.** Never refusing does NOT license acting on an unresolved
subject or destructive scope. In the single-agent target, the same Agent uses server context and
read tools, then either calls a high-level Event tool with stable Event Spec ids, or asks one
focused clarification. It
never fabricates identity. The Event tool and shared gateway validate the operation before any Event
Spec, Candidate or Draft mutation. An immutable Event Command may be recorded when a tool is really
invoked for audit/idempotency; it is not a model-generated routing envelope created before every
answer.

PR review uses the same agent entry and narrow PR tools, not a sibling LLM-classified intent. Read is
safe; reply/fix-and-reply still act only on the run's existing open PR under server policy and
confirmation. Review feedback never creates an Event, branch, adjustment run or second PR merely
because the Agent understood it as actionable.

**Acting is transactional.** An Event lifecycle operation opens the recorded base as an immutable
`RepositorySnapshot`, replays the complete helper + READY Event plan into one server-owned
`CandidateOverlay`, and gives the agent only scoped Candidate MCP tools for the requested
Add/Recapture. Every unaffected artifact is replayed mechanically; Remove proves the remaining plan
and invokes no agent. The validated plan is content-addressed and promoted by compare-and-swap before
any implementation/Spec/coverage state changes. Failure preserves the previous Draft id,
`runs.diff`, run status, coverage and READY artifacts; a confirmed Add remains visible with its real
implementation error, while a failed Remove changes no durable Event state. The Diff Review value is
the exact base-snapshot-to-Draft comparison recorded by the promotion transaction. The per-Event
composed artifacts survive as ATTRIBUTION (`composedDiff`) — they answer
"which Event contributed what" and tell a correction whether that one Event's implementation really
changed — and are never presented as the review value.
(Code: `app/candidate-engine.js` + `app/run-drafting.js`.) The transaction runs over a server-owned
Candidate overlay on an immutable snapshot; changing the physical engine never permits partial-plan
replay or model-owned publication.

### Rule 13 — Pure gtag implementation & standard code generation (no private markers)
When adding or updating events, Tartini AI writes standard, clean GA4 code via `trackEvent` -> `window.gtag('event', name, params)`:
- **No private DOM markers:** No `data-toastia-*` or any other Tartini attribute on elements.
- **No private payload fields:** No `__toastia*` field or other internal tracking metadata in event payloads.
- **No internal IDs in code:** No `tb_…` identity or other Tartini id is emitted or passed through props, state, context, or callbacks.
- **Trigger placement:** Click events are placed on their interactive controls; business outcomes (`purchase`, `sign_up`) are placed on the server/state confirmed success branch.
- **Page-level / effect custom events:** Placed in page or effect lifecycles without fake element targets.
- **GA4 Auto / Enhanced Measurement events:** Never re-implemented in code; tracked automatically by the Google tag.
- **Tartini Autocapture:** When `get_tracking_state` reports it absent or partial, Tartini AI recommends it once; on the user's yes, `enable_autocapture` stages the reviewed component verbatim (`[src/]components/TartiniAutocapture.tsx|.jsx`, or `tartini-autocapture.js` next to `index.html`) — or upgrades an exact official V1 there — and the turn mounts it once at the root, or writes nothing when it is already mounted (`auto_click`, `auto_form_submit`, `auto_page_engagement` -> `window.gtag`; never `page_view` or `scroll`). The component is never edited.
(Code: `app/event-implementation-spec.js`, `app/ga-rules.js`, `app/candidate-validation.js`, `app/autocapture-install.js`.)

### Rule 14 — Candidate Lifecycle & Non-Blocking Preview
1. **Candidate Transaction validates GA4 implementation correctness.** The Candidate finish gate
   (`candidate-validation.js`) verifies syntax regressions, the standard `gtag`/`window.gtag`/
   `trackEvent` call, Event Spec parameters and GA4 naming rules, the business trigger, no unrelated
   emissions, zero private markers and an intact Google tag. It does NOT read the Preview.
2. **Preview is decoupled and auxiliary.** Website Preview runs best-effort 4-tier locators
   (`id` → `tag + safeText` → `tag + stableClasses` → `unresolved`) and intercepts nothing. If a
   target cannot be resolved in current DOM, Preview displays
   `no visual target on this page` or `code/business-state triggered`. A locator miss NEVER fails
   the candidate, and NEVER blocks PR creation or merge.
3. **Invite review after every successful add.** When the Candidate Transaction finishes promotion,
   the assistant prompts the user to review the preview and diff. Adds run inside the turn (a durable
   Agent job) under per-run mutation serialization.
4. **User adjusts by telling the assistant.** The user describes changes in natural language or
   with screenshots. The assistant uses high-level tools (`update_tracking_event`, `rebuild_event_instrumentation`)
   to update the implementation.
5. **Code follows the adjustment.** Rebuild and retry operations update the candidate cleanly and
   re-verify standard GA4 implementation correctness.

### Rule 15 — Long operations STREAM named, periodic progress (never a bare spinner)
Adding/removing/updating events are real multi-minute agent runs. A single terminal "Working on it…"
spinner is a bug — the user can't tell if anything is happening, and blocking the whole batch inside one
HTTP request leaves the chat frozen until a manual refresh (both were real bugs). The contract:
- **Answer immediately**, then run the work in the **background** under per-run mutation
  serialization. Each mutation gets an isolated Candidate Transaction: a server-owned Candidate
  overlay and a compare-and-swap ref promotion, expressed by whichever provider owns the run's
  repository. Diff, revision, status and the draft generation update only after the relevant
  durable transition succeeds. Never hold a bulk
  operation inside one blocking request.
- **Show a live, NAMED checklist** the user can poll: which events are **done ✓**, which is **wiring now ⏳**,
  which are **queued ·**, plus **elapsed time** and the REAL cost so far, in Credits, from normalized
  runtime/provider events. Omit the cost when the provider did not report it; never invent it.
- **Finalize with a concrete summary** (what landed, what failed + how to retry, total time and
  Credits) and, after an add, **invite the user to review the preview** (Rule 14 step 2).
- **EVERY reply carries the SAME usage footer** — a consistent trailing line `⏱ <elapsed> · <N> Credits`
  on add/remove/question/fix replies alike (not just some). Elapsed always; Credits only when an agent
  actually ran and the provider reported its cost (`· cost not reported` when it did not), and never a
  token count. One shared `usageFooter()` so the format never drifts between paths.
(Code: the Tracking turn's own usage, accumulated per request;
`agentUsage(meta)` reads real provider-normalized usage/cost; per-request `usageAcc` +
`usageFooter()` on every `finish()`; the provider-neutral `AgentRuntime` exposes usage from text,
vision and coding calls. The Event Command background worker, its `commandProgress` store and
`GET /api/runs/:id/command-progress` are gone: one message is one invocation, and it writes the code
inside the turn the user is waiting on.)

### Rule 16 — EMPOWER the assistant; these docs are guidance, NOT a leash
The product goal is a **maximally capable** assistant that freely does the user's bidding across every
panel — add logging, remove logging, rename/retarget events (a box follows its code), install Tartini
Autocapture, edit the
**Diff Review**, drive the **Website Preview**. Never shrink that: no "I can only answer", no "I'm just the
Q&A side", no "open the panel yourself", no artificial capability boundary, no manual second click for
something the user already asked for. When the user asks, the assistant **acts** and the panels update.
These best-practice docs exist to make its output **better** (correct GA4 taxonomy, honest preview
locations, streamed progress) — they are **quality guidance, not permission gates**. The only lines that
stay are the few **user-PROTECTING deterministic guarantees** the user has explicitly endorsed — no PII
sent to GA4, additive-GA (never break existing tracking), and the preview auto-drive stops before an
irreversible real-world action (completing a purchase/payment). Those protect the user; they are not
limits on helpfulness. Everything else: bias hard toward doing it.

Two concrete anti-refusal rules this cashes out to:
- **A location fix NEVER dead-ends.** "I couldn't re-locate X — try describing where it should point" is a
  refusal and a bug. A box on the wrong element means the code fires from the wrong place, so the
  assistant calls `update_tracking_event` with the user's own words (and screenshot), reads the real
  source, moves the call to the element the user meant, and the Preview re-derives the box from the new
  code. There is no separate model pass that edits a stored selector — none exists. The reply is always
  "on it", never "I can't".
- **The assistant can SEE the pending diff.** It wrote the diff, so it must be able to answer about it. The
  Q&A state layer includes the real Diff Review text (`ga4AnswerFacts(…, diffText)`) — never deflect with "I
  can't see the diff, paste it to me". Read it and explain the exact lines/events/params.

### Rule 17 — NO EVENT-LEVEL HARDCODE for the preview box or locating (permanent, absolute)
The preview marker (box), page target, description, and "locate" auto-drive for ANY event come only
from verified project evidence:
1. **NEW element-level custom event:** the run diff's clean code and the hints of the element its call
   is bound to are primary. Preview resolves them in the live DOM via the 4-tier ladder; an element
   the live build does not render yet reads "no visual target on this page".
2. **EXISTING element-level custom event:** source-derived locator hints from current code.
3. **Page-level custom event:** its real trigger contract, call site, and runtime route are primary;
   it has no fake element target.
4. **GA4 Auto / Enhanced Measurement event:** the versioned provider rule, known GA4
   configuration, and current runtime DOM/state are primary; nothing is written into customer code for it.
5. **Tartini Autocapture:** one fixed root component; when verified, the preview draws the elements
   its click handling observes; each click sends `auto_click` through the page's own gtag — no
   per-event configuration. Its form-submission and page-engagement events are not drawn.
6. **Unresolved target:** If a locator cannot resolve in current DOM, Preview displays `no visual target on this page`
   or `code/business-state triggered`. It NEVER blocks Candidate completion or PR publication.

There is **NO per-event map** of button text, paths, or selectors — none, anywhere. **Deleted for good and
never to return:** `CODE_EVENT_TRIGGERS` (an ecommerce-event → button-text + route table),
`CODE_EVENT_FIRES`, `EM_CLASSES`/`EM_PAGE` (an auto-event-class → selector table), `PRODUCT_LINK`
(a detail-page href pattern), and `BTN`. Their SHAPE is what is banned — any name→location table,
under any variable name. Why: every site is different — checkout can be a drawer, a modal, a multi-step wizard, on any
path, in any language — so a built-in table is wrong for real sites and violates the product (this is
logging *visualization*; a hardcoded guess mislocates). Prompts may hand the AI **generic best-practice
PATTERNS** (e.g. "a gated element may need reveal steps — find the real trigger in the code"), **never a
specific site's event location**. A versioned GA4 provider adapter is allowed to encode Google's
documented collection semantics, but it must not contain site selectors/routes/copy and must honor
the real configuration. If evidence cannot resolve a location, enter the bounded retry/verification
lifecycle; only a conclusive result may report `unresolved`, and there is never a hardcoded fallback.
**An event's NAME may not decide its level, its cardinality or its page either.** Those come from the
structured **TriggerContract** (`app/trigger-contract.js`), merged once from real code > the contract
the user confirmed in chat > the GA4 provider contract > unknown. The GA4 standard-event table is
guidance for GENERATING new code, never a reading of existing code — treating it as evidence
reclassified an element the analysis really found in the source as a page-level event. And a
**source path is never a route**: `route`/`routes` hold browser URLs, `componentPath` holds the file,
and a component's routes come from the repository's real module graph (`snap.routeOwners` — imports,
`require`, dynamic imports, `<script src>`/`<link href>`, resolved by the ONE resolver,
`module-resolution.js`), never from its file path. A page inside a static root is the address it is
served at (`app/public/privacy.html` is `/privacy`, never `/public/privacy`).

(Code guards: the hard-rule comment blocks in
`app/public/run.html` and `app/event-locator.js`; enforced by review — reject any new name→location table.)

### Rule 18 — PREPARE INCREMENTALLY UP FRONT; never compute on click
The Website Preview opens with every tracked event represented, but deterministic/reused results
must render immediately. Preparation joins:
- custom event definitions and the locator hints of the elements their calls are bound to, read from
  the latest head's source with no model;
- GA4 provider contracts/configuration with the current runtime adapter results; and
- AI output only for a missing custom-event description, a GA4 class analysis, or safe navigation help.

Consequences:
- **Never compute on click.** Clicking an event button/legend row uses the prepared target index:
  navigate to a verified route, focus one example, and keep every match drawn.
- **Never block old results behind new work.** Adding events preserves all reusable descriptions,
  routes and boxes. Only the new or dependency-affected units show `analyzing`.
- **Every reply reports REAL cost, including the vision path.** The footer
  `⏱ <elapsed> · <N> Credits` takes the cost from normalized runtime/provider events, converted to
  Credits, never an estimate and never a token count. A runner that keeps only `session_id` in its
  meta silently degrades every reply to elapsed-only — which reads as "no model ran". Regression:
  `agent-usage.test.js`.
- **One grounded line per event.** Structured facts own `when`, `where`, `logs`, and `why`; AI may
  phrase them in the user's language but cannot add facts. A deterministic renderer remains usable
  when the model is unavailable.
- **Progress is honest and named** (Rule 16): a live checklist over the preview lists the real event
  names with per-unit state and an elapsed timer, plus a "show the preview now" escape hatch — never a
  bare spinner, never a trap.
- **Cache by real dependency, NEVER by the commit.** Description and location have separate
  signatures (`analysis-signature.js`), each over only what feeds it: a description over its own
  PROMPT (trigger contract, parameters, and per call site the file, trigger shape, routes and source
  window, plus its bound elements — never a line number, never another event in the same file);
  location (GA4 automatic classes only — a custom event has no location unit) over the class
  analysis's SEMANTIC key (`ga4-class-evidence.js`, `class-analysis-deps.js`): the Google tag's
  CONFIGURATION (never the whole file it sits in), its own Data Stream configuration, and the class's
  own constructs with the routes that render them — forms and submit handlers, links that can leave
  the site or fetch a file, players, search inputs, in markup or BUILT by the page's own script (a
  dialog's form, a destination set as the page loads) — or, for a page-level class, the routes. Never a
  file NAME, never the file list, never whole-file content: mounting Autocapture in the file that holds
  the Google tag re-bills nothing, and an existing page that gains a form invalidates the form classes
  although no path changed. The form classes are analysed from that evidence in ONE text call, not by
  an agent exploring the repository. The route inventory is not a
  dependency — validating a route is deterministic and free. **The source revision is provenance and
  must never be a cache key**: keying by it re-ran fifteen finished events every time two were added.
  An untouched event keeps its signature across commits and is reused, with `analysis.reused` set so
  no surface shows it as work in progress; an affected one gets a new signature and a fresh budget.
  Polls, page reloads, cache reads and DOM rescans spend no model attempts and create no jobs.
- **Deterministic before AI.** A custom event's source locators, and a page-scope contract's routes
  from the module graph, settle its target without a model. None of those may consume an attempt.
  Only descriptions and GA4 class analyses reach a model, and only for the events missing them.
- **Distinguish "nothing here" from "analysis broke".** A parseable answer saying the site has no video /
  no outbound link / no download is a REAL result → muted button, no box, the AI's reason shown on click.
  A timeout, unavailable model, unparseable reply, missing field, or internal error enters the retry
  lifecycle in Rule 20 — never dressed up as "this site has nothing" and never terminal before its
  bounded budget is exhausted.

### Rule 19 — FIRST USE is chat-first and truth-first
A first-time user judges the product in the first minute, on three panels at once. Treat them as
one contract (canonical: DESIGN.md §6.5):

1. **Event workspace** — scan shows the real current inventory and active Event Specs. It persists
   no recommendation cards and produces no business-event diff. With no Draft Diff, the UI invites
   the user to ask chat to create or change an Event.
2. **Website Preview** — every tracked event is represented immediately (Rule 18): custom events
   use their source-derived locator hints, GA4 automatic events use provider/runtime evidence, and
   AI writes descriptions and GA4 analyses only. Existing boxes remain visible while new work runs.
3. **AI chat** — a live model call per message that ACTS (Rules 12/16), can SEE the pending diff
   and any attached screenshot, and ends every reply with the shared usage footer (Rule 16).

Two failure modes to check for whenever you touch this area:
- **A confirmed Event disappearing because implementation failed** is a domain-model failure. Keep
  the Event Spec visible and report the implementation status separately.
- **One Event conflict dirtying the formal workspace or replacing the last valid Draft** is a
  transaction failure. The Candidate is discarded whole; READY artifacts, coverage, `runs.diff`,
  `head_sha`, the Draft branch SHA and the draft generation stay exactly as they were. A replay that
  cannot be placed exactly — no matching preimage, no rebasable recorded edit, and a three-way merge
  whose regions disagree — aborts the candidate and writes nothing, and a conflict is never a marker
  left inside a file.
- **A degraded footer** (`⏱ 21s` with no tokens) is indistinguishable from "no model ran" — if a
  model ran, its real numbers must appear.

### Rule 20 — Retry each incomplete analysis to a conclusive result, maximum 10 attempts
Description (every event) and location (GA4 automatic classes) are separately durable for each
dependency signature. The identity includes the project/event, analysis kind, relevant
trigger/dependency inputs, and analyzer/provider schema version; source revision is recorded as
provenance. The lifecycle is:

`pending → running → retrying → resolved | unresolved | failed`

- **Maximum 10 real computation attempts.** Attempt 1 is the initial computation; attempts 2–10
  are retries. Polls, page refreshes, two open surfaces, and callers that join a live lease consume
  zero attempts.
- **Three identical repeatable failures stop it early.** `unparseable`, `incomplete`, `ambiguous`
  and `timeout` recur when the same prompt is asked again, so three CONSECUTIVE ones end the identity
  as `failed` (`analysis-jobs.js` `deterministicLimit`). A transient failure (`unavailable`, `error`,
  a crashed lease) breaks the streak and keeps the whole budget. A changed dependency is a new
  identity with a fresh budget; an explicit re-analysis buys one more attempt.
- **Retry every technical or incomplete outcome:** timeout, model unavailable, invalid/unparseable
  output, missing description, missing location, ambiguous/unverified target, internal error, or a
  crashed lease. `failed` is terminal after attempt 10 for the same identity, or after three
  consecutive repeatable failures (above).
- **A conclusive answer stops retries.** `resolved` means the description is grounded and the page
  or element target passes deterministic validation. `unresolved` is also conclusive only when a
  valid analysis explicitly proves that this project has no applicable trigger or no visual target;
  silence and model failure are never `unresolved`.
- **Preserve partial success.** If the description succeeds but location fails, retain the
  description and retry location only; collection retries retain every already-verified target.
- **Durable, deduplicated, and backgrounded.** One cross-process lease owns each attempt. Website
  Preview and bookmarklet polls observe the same state. Use bounded exponential backoff with jitter
  and a maximum delay; do not hold the user behind a modal for all 10 attempts. Show partial results
  immediately and show `attempt N/10`, the last safe error, and the next retry time.
- **No hidden reset or global invalidation.** A manual refresh joins or schedules the same identity;
  it does not create a second budget. A new source revision creates new work only for units whose
  real dependency signature changed.

Ten attempts are a resilience ceiling, not permission to repeat identical work. The retry must
change something material when possible: narrower per-event context, a fresh model invocation,
validated rendered-DOM evidence, or only the missing field. Stop immediately on a conclusive result.

### Rule 21 — Two visualization modes; click precision and collection completeness
Visualization has exactly two modes:

| Mode | Verified visual target | Required UI behaviour |
|---|---|---|
| `page` | route/document/viewport lifecycle with no concrete actionable DOM trigger | render the event as a page-level button/chip for the verified route |
| `element` | one or more concrete DOM elements | navigate to the route, satisfy safe preconditions, scroll the target into view, and draw/pulse every verified box |

**The EMISSION mechanism never decides the mode** (DESIGN §9.7b). "When is the event sent?" and
"what visible origin does the preview represent?" are separate contracts. An event sent only once a
business state is CONFIRMED is *target-neutral*: it may be started by a concrete element, owned by a
page state, conclusively non-visual, or not yet understood, and the mechanism cannot tell those
apart. Such an event with a confirmed ELEMENT target is `element` — its call sits in the success
branch, and the control the visitor uses is named by the confirmed contract. When the call is not
written inside an element's handler the source has no bound element to read hints from, so the
Preview keeps the element mode and says "no visual target"; never answer `page`.

- A click-shaped TARGET is always `element`, whatever sends the event. Resolve the actual actionable
  leaf (`button`, link, control, or the element whose handler receives the click), not an arbitrary
  wrapper and never the page.
- An event name never determines the mode. For example, a generic click collector may box all
  buttons only when the real installed tracking configuration proves that those buttons actually
  trigger it. Do not assume that from the word "click"; a provider may collect only a narrower
  interaction such as outbound links.
- `single` says the targets are FIXED, not how many there are: several live matches are several
  deliberate targets and all of them are boxed. `collection` requires all live matches to be boxed.
  Zero matches is the failure. An INFERRED locator matching several for a fixed target is also a
  failure — it has not identified one — but never "take the first."
- For a collection, locating focuses one representative runtime match. Rendering queries the
  current DOM through the source locator hints (custom) or provider adapter (GA4 automatic) and draws
  every verified match. The displayed count must equal the number of real boxes.
- A missing element target keeps its element mode — a GA4 candidate stays `retrying`, a custom event
  reads "no visual target" — and is never demoted to page-level to make the UI look complete.

### Rule 22 — Bookmarklet parity and navigation lifecycle
The bookmarklet surface consumes the same canonical preview spec and renderer semantics as Website
Preview. While enabled on a document it must:

- consume the same source-derived locator hints, GA4 selectors, 4-tier resolver and reason
  vocabulary as Website Preview, and like it never touch the page's gtag or dataLayer;
- say in words, not only with a dashed border, that an event new in this Draft is sent only by a
  build that includes it — never by production before the Pull Request is merged and deployed;
- load the current route's page-level chips and every matching element box automatically;
- observe `history.pushState`, `history.replaceState`, `popstate`, hash changes, and relevant DOM
  mutations; on an SPA route change, cancel stale work, fetch/re-filter the canonical spec, wait for
  the new DOM, and redraw without another click;
- retain the enabled state for the lifetime of the tab/document, keep one singleton instance, and
  cleanly tear down observers, timers, requests, listeners, and boxes when disabled;
- render partial/retrying/failed states and collection counts exactly as Website Preview does;
- draw in the Website Preview's visual language, which is the reference: one distinction, in blue.
  A **solid** box is an event already in the code the run started from (the live site sends it); a
  **dashed** box is one that exists only in this run's Draft (the live site cannot send it until the
  Pull Request is merged). The same for the `auto_click` layer, drawn — and counted in the toolbar —
  only when the source proves Tartini Autocapture `verified`, and solid when the base already sends
  `auto_click` (a click-only earlier version counts: upgrading it does not make clicks new). The fact is the canonical spec's
  `logged`, never decided by a surface; an unknown answer is drawn solid. Box and tag carry the event
  name only. The bookmarklet cannot load the app stylesheet, so it restates the values;
  `app/test/overlay-visual-parity.test.js` reads both.

A bookmarklet on the configured live page may visualize tracking events by locating the
corresponding elements via the 4-tier locator ladder. It never guesses a selector or turns an
element event into a page chip. It adds only its own overlay root — never `innerHTML`, never a mark
on the customer's elements — and removes it on Close.

A plain JavaScript bookmarklet **cannot survive a full document navigation**: the browser destroys
its script context on the new page. Exact automatic parity across traditional multi-page navigation
therefore requires a persistent loader (the site bridge a person agreed to add, a browser
extension, or an explicitly installed userscript). Do not claim that a one-click bookmarklet alone
can do this. The bookmarklet can provide automatic SPA behavior now; the persistent-loader path is
the scalable design for full-page navigation.

### Rule 23 — ONE event, many call sites: never let one of them speak for the whole event

A tracked event is not "one file, one line, one handler, one element". The same event can fire from
several components, and each firing site has its own handler shape, its own routes and its own bound
element. Treating the first one as the event is what produced, for a single real event: two
identical chips and `CUSTOM · 2`, a description that described one component, and a lost element
(the first site was an inline arrow).

- **Identity is the event NAME.** One canonical event per name; `owner` is derived (a custom code
  event owns a name a GA4 automatic event shares) and `alsoAutoCollected` keeps that fact.
- **Count events, never call sites.** A chip row, a badge or a "currently tracked" total that counts
  parsed call sites is a bug. "Fires from N places" belongs in Event Details, with the list.
- **Locators are per element, de-duplicated.** Every element any call site is bound to contributes
  one hint; two sites bound to the same element are one hint, so sharing an element across components
  cannot double a count. Each hint is tried on its own, and the event's boxes are their union.
- **The description must cover every site**, and its cache signature must depend on every one of
  their files — otherwise editing the second component cannot invalidate a description that no longer
  describes it. When the sites genuinely mean different things, keep `perCallSite` rather than
  averaging them into one sentence.
- **Find the element the call is BOUND TO**, directly: the tag whose attribute list contains the call
  (inline), or the tag whose handler attribute references the declaration (named — same file first,
  then files that bind an exported handler). Read the hints from that tag. A tag that merely sits
  nearby is never an association.

### Rule 24 — The assistant can read the code, and a source-level answer must have read it

The one Tracking agent reads the run's exact revision in its code workspace: `open_code_workspace`
fills the turn's sandbox directory with the exact Candidate used by Event work (or, with no draft
chosen, the repository's current head), and OpenCode's own `read`, `glob`, `grep` and `list` work
there. It never reads a customer checkout outside that copy. Therefore "I cannot see your repository /
my working directory is empty / give me a path" is a refusal the system has no reason to produce and
must never be reintroduced.

Two honest limits stay: what the agent writes reaches the Candidate only through
`finish_event_implementation` and the reviewed Candidate transaction, never as an untracked source
write, and the Agent must not claim a revision it did not read. A source-level answer that opened nothing is rejected once — measured structurally, by counting
real tool calls, never by matching a phrase in the reply.

---

## 🗒 Mistakes ledger — real wrong renders and the fix

For the developers of the deterministic locator (`call-site-evidence.js`, `preview-locator.js`,
`public/target-resolver.js`): the agent does not locate anything and never reads this ledger — the
Tracking guide carries only "What the person sees in the Website Preview".

Every row is an event that rendered wrong in a real session. When a *new* event resembles one, apply the
same rule — don't special-case the name.

| Event | What rendered wrong | Root cause | Fix (rule) |
|---|---|---|---|
| a checkout-stage event | box landed in **blank space** | boxed by fuzzy text with no real anchor; the element was gated behind a state the preview never reached | text-filter the trigger; add `preconditions` that auto-drive to the state where it is observable (R4) |
| a per-item click event (React site) | **nothing boxed** when clicked; redirected to the wrong element | an `[onclick*="handlerName"]` selector does not exist in a React DOM (onClick is a JSX prop) | use a RENDERED attribute verified in that project's DOM — class / `data-*` / id / role / an href pattern (R1) |
| a repeated custom click | boxed **only one** card, not each item | the target defaulted to `single` instead of carrying the requested collection contract | carry the collection contract + stable instance identity; box every match (R2/R5) |
| a confirmed element event | event fired but box was misplaced | generated locator relied on fragile selector rather than unambiguous 4-tier confidence | use unique ID or exact safeText; a real click still sends the event through the page's own Google tag — confirm arrival in GA4 DebugView (R5/R13) |
| a collection viewable-impression | shown as a page chip or one random card | visualization was inferred from the event name instead of the confirmed trigger contract | preserve the collection contract, highlight all matches in view (R2/R3) |
| `select_promotion` | boxed wrong element | locator tag/classes matched multiple cards ambiguously | require unambiguous tag + safeText or DOM id in 4-tier locator (R5/R6) |
| `begin_checkout` | landed/candidate mis-derived; trigger came out as **`gtag`** | `enclosingTrigger` matched the gtag CALL line (nested `reduce(fn(){…})` made a spurious `){`) | walk above the firing line + exclude string literals from the param match (R7) |
| any landed event | element target silently fell back to guessed selector | no clear separation between confidence tiers | 4-tier locator model: unresolved remains honest; failure state does not block PR (R5) |
| whole preview | **blank / no boxes at all** ("preview non-functional") | a single-backslash regex in the injected bridge string → SyntaxError → dead IIFE | double backslashes; `bridge-syntax.test.js` regression (R11) |
| gated events (`add_payment_info`, `purchase`) | box on a **hidden** step | the step isn't visible until a prior click | `preconditions` click through to reveal it (R4) |
| `form_start` / `form_submit` (GA4 EM) | box floating in a **blank white page** | the `form` selector matched a footer/auth-gated form on a page that rendered mostly empty → a lone box in blank space | never present a box in blank space as confident; treat as `state_required` — navigate to a page where the form is genuinely visible, else show honest state (R3/R9/R12) |
| any added custom element event | event call missing in diff | agent failed to insert standard `trackEvent` call | verify standard `trackEvent` call exists in candidate diff at correct business trigger (R13/R14) |
| any Draft-only element event | locator unresolved on current page | element is on another route or gated behind state | report 'no visual target on this page' without failing candidate or blocking PR (R5/R14) |
| a GA4 automatic element-related event | box claimed to be a custom target | a private marker or site-specific selector was used to imitate Google's collection | use the versioned GA4 adapter + actual configuration/runtime matches (R5/R17) |
| the AI assistant | **refused** to create an Event after a direct request | the request was routed to an advisor/Q&A path instead of the Event Command gate | a grounded direct request creates the confirmed Event Spec and starts implementation without a second Add click (R12) |
| a confirmed custom Event | **disappeared** after its coding attempt failed | one suggestion row represented recommendation, business definition, workflow state, and patch | persist Event Spec separately from implementation; failure keeps the Event and prior valid patch (R19) |
| any reply with a screenshot | footer showed **`⏱ 21s` with no tokens/cost** — looked like no model ran | the vision runner kept only `session_id` in meta, dropping provider usage/cost | keep the whole normalized usage event in meta; real numbers or none (R16/R19) |
| an existing custom event | wrong element boxed | the element the code is bound to shares its text with others | the ladder falls through on ambiguity (R5); if the CODE fires from the wrong element, update the Event so the call moves (R10) |
| whole preview (address bar) | after /shop → a product page the bar still read **/shop** | the bar was written once when the frame opened; only "locate" rewrote it (with the preview origin and a `__toastia_preview` parameter) | the bridge pushes `toastia:navigated` (incl. pushState/replaceState/popstate/hashchange) and every measurement carries its path; the run page shows the site path as text (R8) |
| whole preview (chrome) | the address bar said **"toastia-preview · …"** | an old product name left in visible copy | visible copy says "Tartini preview"; internal message names (`toastia:*`) are not visible and stay |
| GA4 always-on chips (`page_view · GA4 auto`, …) | chips **covered the site's logo and nav** | page chips were absolutely positioned over the frame's top-left | page chips in a strip above the frame, element-status pills in a strip below it; nothing but boxes is drawn over the page (R3) |
| `select_item` on a Next.js /shop (call bound to `<Link>`) | **no box** — "bound to a component — no box" beside the very links it fires from | a component element contributed no hint unless it had a literal id: its rendered tag is unknowable, so its static props were thrown away too | a component hint of its static forwarded props (`href` prefix, classes, text, aria-label, data-*), matched as a conjunction on interactive elements of any tag at tier `component_props` (0.5); never a component-name rule (R5) |

---

## Pre-flight checklist when an event renders wrong
1. **Preview provenance?** Confirm `draft_source_sha === run.head_sha` and identify
   `runtime_source_url`.
2. **Owner?** GA4 automatic uses provider/config/runtime evidence; custom uses its code revision.
3. **Custom locator?** Check the hints the spec carries (is the call bound to an element at all?),
   then the ladder (id → tag+safeText → tag+stableClasses). Ambiguous matches remain `unresolved`
   without failing candidate finish.
4. **Classify visualization** (`page` / `element`; non-visual is a diagnostic outcome) from the
   verified trigger.
5. **Framework?** An AI candidate must not rely on a framework-only `onclick` prop (R1).
6. **Click?** It must remain element-level and target the actionable control (R21).
7. **Per-item?** Collection locator must highlight every matching trigger in the view (R2).
8. **GA4 auto?** Validate the provider rule and known configuration; never write anything into source for it.
9. **Gated?** Add safe `preconditions` (R4).
10. **Incomplete?** Preserve successful fields and verify the retry advances toward `N/10` (R20).
11. Fix the source contract, provider adapter, or general derivation — never add a site/event special case.
12. Verify on the real runtime DOM and after an SPA route change — **count the boxes/chips** on both
    Website Preview and bookmarklet (R22).

## Where the code lives
- `app/call-site-evidence.js` — the element each call of an event is BOUND TO (inline handler, or the
  tags whose handler references the named function), and its hints.
- `app/preview-locator.js` — reads one tag's hints (literal id, DOM tag, static text, stable classes;
  for a component element, its static forwarded props instead of a tag); never guesses one it cannot
  read.
- `app/public/target-resolver.js` — the 4-tier ladder (`locatePreviewTarget` / `resolveLocator`),
  `resolveSelector` for GA4 candidates, `discoverAutocaptureTargets`; executed in the page.
- `app/preview-target.js` — the ONE canonical visual target per event; `app/preview-spec.js` — the
  canonical spec (`spec_version: 10`) and the bookmarklet projection.
- `app/event-locator.js` — description prompts for custom events (no location analysis) and the
  shared grounding rules.
- `app/server.js` — `deriveTrackingForRun`, `eventEvidenceFor`, `previewAnalysisContext`,
  `buildRunPreviewSpec`, source snapshot and preview routes.
- `app/candidate-engine.js` — the owner of the Candidate Transaction: a server-owned overlay on an
  immutable snapshot, strict plan replay from versioned artifacts, per-Event attribution capture, the
  validated candidate becoming a revision, compare-and-swap ref promotion and rollback.
- `docs/overall/unified-toastia-mcp.md` — the shared MCP control plane, the Tracking tool pack, the
  provider-neutral repository/Candidate contracts, the GitHub API publication path and the one
  remaining Cloud-delivery step.
- `app/run-drafting.js` — the Candidate Transaction coordinator: read the plan, materialize, validate
  GA4 implementation correctness, promote, then ONE Firestore transaction (READY/retire, `head_sha`,
  the real-revision `runs.diff`, status).
- `app/public/run.html` — `drawOverlays` (boxes + chips), `runRecipe` (auto-drive), `finishRecipe`,
  `focusCodeEvent`, `samePreviewPage`, `findPageChip`.
- Preview bridges — `app/public/preview-bridge-core.js` (the ONE protocol: the session handshake,
  `toastia:getRects` with `locators` or `selector`, `toastia:getAutocapture`, and the
  `toastia:navigated` / `toastia:domchanged` / `toastia:scrolled` notices after a handshake);
  `app/preview-relay.js bridgeScriptBody` (the relay: that protocol plus `toastia:act`,
  `toastia:navigate`, runtime observation and viewability; no analytics interceptor);
  `app/tracking-template/tartini-preview-bridge.js` (the site bridge, built by
  `app/preview-bridge-versions.js` and placed per framework by `app/site-framework.js bridgeOf`);
  `app/preview-bridge-probe.js` (a pull request head's deployment, and what the probe reads); and
  `app/public/preview-bridge.js` (the bookmarklet overlay).
- Model policy: `locate` task = medium (`app/config.json` models) — custom-event descriptions and GA4
  class analyses; its answer is deterministically validated and re-attempted, and it is the
  highest-volume billed path.
