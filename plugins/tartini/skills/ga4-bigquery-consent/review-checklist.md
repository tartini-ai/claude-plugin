# Review checklist

Part of the ga4-bigquery-consent skill.

What a correct consent change has: one rule per item, each checked on its own and given its own ledger line,
`checklist.ga4-bigquery-consent.<n>`. Each item says where to look, and ends with the rule it checks, as the
file and the rule's bold title. Check each item in every place it names (every document that loads the
module: a top page, and a page framed in it), reading each place in context, never in one sample. An item
the change does not touch (the server's change draws no banner) is N/A, with why. A save waits for one
reviewer that traces the request's outcome (each data scenario of the proposal, from the scripts a page loads,
in order, to what the Google tag and each tool send, region by region, in the top page and in a page framed in
it, and to the server's line) and one per
group not marked advisory (the red lines), all started in one message; a reviewer gives ledger lines only to the
items its lens names. A group marked advisory is reviewed when there is time, one reviewer each: what it finds is
fixed or listed in your reply, and holds no save.

## The region and the decision (advisory)

1. The region is read from the edge's header, with one same-origin request before anything is shown, or handed over by the server from the platform's request header where the edge cannot add one; never the browser's time zone or language, a third-party lookup or a cookie. Look: the module's region lookup. (write-the-change.md: The region comes from the edge)
2. No header, an empty value, an error, or no answer within half a second means consent first. Look: the lookup's timeout, its catch and what an empty value returns. (write-the-change.md: The region comes from the edge)
3. Consent comes first in the 27 EU countries, Iceland, Liechtenstein, Norway, the UK and Switzerland, and in the EU's places with codes of their own (GP, GF, MQ, YT, RE, MF, AX, IC, EA). Look: the module's list of regions. (write-the-change.md: The region comes from the edge)
4. Nothing of the banner is drawn before the decision has its answer, so a visitor in a region that collects by default never sees it. Look: where the banner is mounted, against where the region is awaited. (write-the-change.md: The region comes from the edge)
5. Collecting by default is never stored as the visitor's choice: the next page decides again. Look: every write to the choice's storage. (write-the-change.md: The region comes from the edge)
6. The default decision gives the site's own gate its answer for the page without storing it: in a region that collects by default, with nothing stored, a loader registered through the gate runs, on the first page and the next. Look: how the gate releases what waits (only on a stored answer, or on any decision), against what the default branch calls. (write-the-change.md: The gate the site already has)

## GPC and a stored choice (advisory)

7. GPC (`navigator.globalPrivacyControl === true`) opts out wherever the site collects by default, and the visitor is not asked to undo it. Look: the branch that collects by default. (write-the-change.md: GPC)
8. A stored Reject always wins; a stored Accept wins, except one given while GPC was off, once GPC is on, where the site collects by default; an Accept given with GPC on is stored with that fact and counts. Look: where the stored choice is read, and what an Accept stores. (write-the-change.md: GPC)
9. What Accept and Reject store follows the site's own rules as before (Accept records only the categories the site uses, by the site's own derivation), and the test that pins such a rule still pins it. Look: what each choice writes, against the base's code and its tests. (write-the-change.md: Keep what a choice records)

## The link and the banner (advisory)

10. "Your privacy choices" is added by the consent module itself, on every page that can run analytics. Look: every page that loads the module or an analytics tag. (write-the-change.md: The opt-out link)
11. It sits beside every link to the privacy policy the site already shows as an item of a list of links: a footer's legal links, an account or settings menu (one drawn later too), a sign-in page's links. Look: search the site for links to the policy, and check each one in its list. (write-the-change.md: The opt-out link)
12. It is never added beside a policy link inside a sentence of running text, nor inside UI the consent module draws itself (its banner's own policy link). Look: each policy link in a paragraph of every page, and the banner after the module ran, rescans as the page changes included. (write-the-change.md: The opt-out link)
13. It has the same element and classes as its neighbours, the same attributes, role and tab order as the list's items, and the list's separator between it and its neighbour; nothing styles it apart, and it is never an unstyled native button. Look: the markup it adds beside each link, against its neighbours' markup and the text or element between them. (write-the-change.md: The opt-out link)
14. It appears once per document, however often the module runs. Look: the module's guard against a second link. (write-the-change.md: The opt-out link)
15. A fixed fallback link appears only on a page that shows the policy's link nowhere: styled to be seen, clear of the page's own fixed or sticky controls at every width, and under its dialogs. Look: the fallback's position, offsets and z-index, against the layout's fixed and sticky elements in each media query and its dialogs' z-index. (write-the-change.md: The fallback link)
16. The fallback is drawn only where no policy link will appear later, or removed when one does (a menu the page's shell draws after load). Look: which policy links the page's shell or menus draw after load, against when the fallback is drawn and whether anything removes it. (write-the-change.md: The fallback link)
17. Showing the choice again removes nothing and changes nothing until the visitor picks. Look: the link's handler. (write-the-change.md: Showing the choice again, and withdrawing)
18. The current answer is marked so a sighted visitor sees it (a label, or a style the stylesheet gives it), never only by an ARIA attribute or an unstyled class; with nothing stored in a region that collects by default, analytics on is marked. Look: the banner shown again, stored choice or none, and the stylesheet. (write-the-change.md: Showing the choice again, and withdrawing; The banner's words, per region)
19. Where the site collects by default, the choice the link shows says the site collects analytics by default and the visitor can turn it off; it never says "consent". The words follow the region whether or not a choice is stored, and with GPC on they say GPC turned analytics off. Look: each region's words, with and without a stored choice, and with GPC on. (write-the-change.md: The banner's words, per region)
20. Accept and Reject sit side by side with the same weight, nothing is pre-ticked, no scroll or close means yes, and withdrawing takes no more clicks than agreeing. Look: the banner's markup and styles. (write-the-change.md: Refusing is as easy as agreeing)

## A page framed by the same site (advisory)

21. A page shown in a frame of another page of the same site draws no link and no banner of its own. Look: the module's frame check, in a page that is framed. (write-the-change.md: A page framed by the same site)
22. A framed page that loaded the module reaches the top page's decision: in a default region, with nothing stored, it starts on its own load; the top page's Reject and Accept reach it (the denied update and each tool's opt-out; the update and each opt-in). Look: in every document that loads the module, the top page and a page framed in it. (write-the-change.md: A page framed by the same site)

## Withdrawing (advisory)

23. Reject sends the denied Consent Mode update at once. Look: the Reject handler. (write-the-change.md: Showing the choice again, and withdrawing)
24. Reject stops each tool that runs on consent, through the tool's own opt-out, and is stored. Look: the Reject handler, for each tool the site loads. (write-the-change.md: Showing the choice again, and withdrawing)
25. Accept turns back on everything a Reject turned off, a tool's own stored opt-out included. Look: the Accept handler, and what a page does with a stored Accept. (write-the-change.md: Showing the choice again, and withdrawing)

## Consent Mode and the Google tag (advisory)

26. `gtag('consent', 'default', …)` with every type denied runs before any command that sends data (`config`, `event`). Look: the order of the default, the loader and `config` on every page that loads the tag. (write-the-change.md: Consent Mode, with gtag's own commands only)
27. A choice sends `gtag('consent', 'update', …)` at once, and every later page sends it from the stored choice. Look: the path that applies a decision. (write-the-change.md: Consent Mode, with gtag's own commands only)
28. `analytics_storage` follows the analytics choice, and `ad_storage`, `ad_user_data` and `ad_personalization` follow the marketing choice: a region that collects by default, and a site with no advertising tag, never sends a granted ad type without a yes to marketing. Look: every consent update the module sends. (write-the-change.md: Consent Mode, with gtag's own commands only)
29. `gtag` and `dataLayer` are never wrapped, replaced or patched, and the stub the consent default needs is local to the module. Look: where the module defines its gtag. (write-the-change.md: Consent Mode, with gtag's own commands only; A global other code reads is a signal)
30. No global other code reads (`window.gtag`, a consent flag) is created or changed before it means leave to send, and every reader of each still behaves. Look: search for each global the change touches, and read each reader. (write-the-change.md: A global other code reads is a signal)
31. The Google tag is only added to: every loader, `config` command and `gtag` definition stays, and only when they run changes. Look: every removed line of the files that load the tag. (write-the-change.md: The Google tag is only added to, never taken away)

## Third-party calls (advisory)

32. Each third-party method the change calls that changes a tool's state (an opt-in, an opt-out, a reset) does what the installed version's source or docs say it does, for what it stores and what it sends. Look: the tool's installed source, call by call. (write-the-change.md: A third-party call does what its installed version does)
33. A tool call made on every page load sends nothing and changes nothing when the state is unchanged (PostHog: opt in only when opted out, without its `$opt_in` event). Look: what a page load runs, call by call. (write-the-change.md: A third-party call does what its installed version does)
34. A tool that loads after the consent module gets the choice where it starts (its loader reads the decision, or its own loaded callback applies it), so an Accept after a stored Reject turns it back on once it loads. Look: when each tool loads relative to the module, and what reads the choice as it starts. (write-the-change.md: A tool loaded later gets the choice where it starts)

## The privacy policy and public pages (advisory)

35. The policy's basis matches each region: consent where the site asks first; by default, with an easy opt-out and GPC honoured, elsewhere, with the basis named and never called consent. Look: the policy's text for each region, against the decision code. (write-the-change.md: The privacy policy says what the code does, region by region)
36. What the policy says "Your privacy choices", Reject and Accept do is what the code does, in a framed page too, and where the link is; never "stops everything at once" unless the code does. Look: each such sentence, against the handlers in the top page and a framed page. (write-the-change.md: The privacy policy says what the code does, region by region; A page framed by the same site)
37. Every sentence on every public page that the change makes untrue is changed (the policy's other paragraphs, a vendor list, the terms, a cookie table), so no two pages disagree, and a test that pins one pins the new one. Look: search each public page for the old behaviour's words ("before you accept", "only for visitors who accept"). (write-the-change.md: Every sentence the change makes untrue)
38. The policy says what Reject really stops: each tool's opt-out stops that tool, while a Google tag already loaded may keep sending cookieless pings until the next page; it never claims more. Look: the policy's sentences on Reject, against each tool's opt-out in the Reject handler. (write-the-change.md: Every sentence the change makes untrue)
39. The policy says what the server logs are for, what a line holds and how long the raw logs are kept. Look: the policy, against the log line and the platform script's expiry. (write-the-change.md: The privacy policy says what the code does, region by region)
40. Only the sentences the change makes untrue are changed, new paragraphs are added beside the old ones, and no paragraph about something else is replaced. Look: every removed line of the policy. (write-the-change.md: The privacy policy says what the code does, region by region)
41. No note meant for the person (not legal advice, a recommendation, a caveat, deployment status) is on a public page or in a public file. Look: every public page and public asset the diff touches, for advice and for status such as "until the region header exists". (write-the-change.md: Notes for the person stay with the person)

## The tests (advisory)

42. The acceptance tests load the site's real consent module, tag loader and vendor scripts in one fake page, in order, faking only the edges (region source, GPC, storage, each tool's network), and assert what the tag and each vendor receive; the module alone, or matching source text, proves nothing. Look: the tests' harness. (write-the-change.md: The acceptance tests come first, and run the real page)
43. They cover a consent-first region, a region that collects by default, an unknown region, a timeout, GPC, a stored choice, and a withdrawal then the next page. Look: a test for each case. (write-the-change.md: The acceptance tests come first, and run the real page)
44. They cover a page of the same site framed in the top page in each data scenario, the default region's first page among them (it starts on its own load), and the top page's Reject reaching it (the denied update and each tool's opt-out there), with no link drawn in the framed page. Look: the frame's tests, scenario by scenario. (write-the-change.md: The acceptance tests come first, and run the real page)
45. They cover a region that collects by default sending no `granted` ad type. Look: the default region's test, at every consent update. (write-the-change.md: The acceptance tests come first, and run the real page)
46. They cover a page load with the choice unchanged making no tool call that sends an event. Look: the test of a second page load. (write-the-change.md: The acceptance tests come first, and run the real page)
47. They cover, in a region that collects by default with nothing stored, a loader registered through the site's own gate running, on the first page and the next, not only the consent update sent. Look: the default region's test, for a loader registered through the gate and a second page load. (write-the-change.md: The acceptance tests come first, and run the real page; The gate the site already has)
48. They cover an Accept after a stored Reject turning a tool loaded later back on once it loads, in the real load order (the tool absent when the module runs). Look: that test's load order. (write-the-change.md: The acceptance tests come first, and run the real page; A tool loaded later gets the choice where it starts)
49. They cover the link added to a footer's list keeping the list's separator, and no link added beside a policy link inside a sentence or the banner. Look: the link's test. (write-the-change.md: The acceptance tests come first, and run the real page; The opt-out link)
50. The consent code, the link, the policy and the consent tests change together; a test that pinned the old behaviour is updated, never deleted, and no assertion still true is removed or loosened. Look: every removed line of every test file. (write-the-change.md: The consent change is one change)
51. The server's tests request the log line as a browser would: a page, and a `304` to a top-level document GET, are counted; a `304` to anything else, a frame, a prefetch, a HEAD, an asset, a 404 and a redirect are not. Look: the log line's test. (write-the-change.md: The server's tests run the log line)

## The server's log line (advisory)

52. One line per page opened: only a GET of a top-level document (`Sec-Fetch-Dest: document`, or the header absent), never a frame, a prefetch or prerender, a HEAD or an asset. Look: the middleware's checks of the request. (write-the-change.md: The server's log line counts each page it sends, once)
53. It is written when the response finishes, for a 2xx HTML response or a `304` to a request that says it is a top-level document, never a 404, a redirect, a dot-file or an error page. Look: the finish handler's status and type checks, against how the server caches its HTML (`ETag`, `Cache-Control`). (write-the-change.md: The server's log line counts each page it sends, once)
54. Its middleware is mounted before every route that answers a page, so every page passes through it. Look: the server's order of middleware, page routes and static files. (write-the-change.md: The server's log line counts each page it sends, once; do-the-work.md: The log line, first)
55. It is written in the server's own structured log shape (its severity and message fields). Look: an existing structured log line beside it. (write-the-change.md: The server's log line counts each page it sends, once)
56. It holds the page path, the region, `ref` and `utm_*`, the referring host and a bot verdict, and no IP address or full user agent. Look: the line it writes. (write-the-change.md: The server's log line counts each page it sends, once)

## The platform (advisory)

57. Where the repository already configures the load balancer's headers or a log sink as code, the settings are added there; otherwise gcp-consent-platform.sh is copied beside the deploy script byte for byte, never written or edited. Look: the copy's sha256 against the skill's. (do-the-work.md: The platform script, second; platform-commands.md: Google Cloud: the reviewed script)
58. It is called once, as one of the deploy script's own steps, through its step helper and after its final checks. Look: the deploy script around the call. (platform-commands.md: The one call; do-the-work.md: The one call, third)
59. Every flag of the call is a fact read (the backend, the GA4 export's location, the BigQuery connection's service account, `--request-header` when the line writes the region), and a value the deploy script holds is its own variable, never a literal. Look: the call's flags, against the deploy script's variables. (platform-commands.md: The one call)
60. Every grant is on the raw log dataset only, never a project role, and no write's failure is swallowed. Look: the script and the call. (platform-commands.md: Google Cloud: the reviewed script)

## Red lines

61. Where consent comes first, and where the region is unknown, nothing is sent before Accept, and nothing after a Reject: no request of the Google tag, no capture of any other tool, no analytics cookie or storage written. Look: every script a page loads before a choice, in its real order, and the Reject path. (write-the-change.md: Consent Mode, with gtag's own commands only)
62. No personal data leaves: no IP address or full user agent in the server's line, and no email, name or typed text in what any tool sends. Look: the line the server writes and every value the change sends. (write-the-change.md: The server's log line counts each page it sends, once)
