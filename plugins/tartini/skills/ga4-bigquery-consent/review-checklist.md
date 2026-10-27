# Review checklist

Part of the ga4-bigquery-consent skill.

What a correct consent change has: one rule per item, each checked on its own and given its own ledger line,
`checklist.ga4-bigquery-consent.<n>`. Each item says where to look, and ends with the rule it checks, as the
file and the rule's bold title. Check each item in every place it names (every document that loads the
module: a top page, and a page framed in it), never in one sample. An item the change does not touch (the
server's change draws no banner) is N/A, with why. A large change may have one reviewer per group below.

## The region and the decision

1. The region is read from the edge's header, with one same-origin request before anything is shown, or handed over by the server from the platform's request header where the edge cannot add one; never the browser's time zone or language, a third-party lookup or a cookie. Look: the module's region lookup. (write-the-change.md: The region comes from the edge)
2. No header, an empty value, an error, or no answer within half a second means consent first. Look: the lookup's timeout, its catch and what an empty value returns. (write-the-change.md: The region comes from the edge)
3. Consent comes first in the 27 EU countries, Iceland, Liechtenstein, Norway, the UK and Switzerland, and in the EU's places with codes of their own (GP, GF, MQ, YT, RE, MF, AX, IC, EA). Look: the module's list of regions. (write-the-change.md: The region comes from the edge)
4. Nothing of the banner is drawn before the decision has its answer, so a visitor in a region that collects by default never sees it. Look: where the banner is mounted, against where the region is awaited. (write-the-change.md: The region comes from the edge)
5. Collecting by default is never stored as the visitor's choice: the next page decides again. Look: every write to the choice's storage. (write-the-change.md: The region comes from the edge)

## GPC and a stored choice

6. GPC (`navigator.globalPrivacyControl === true`) opts out wherever the site collects by default, and the visitor is not asked to undo it. Look: the branch that collects by default. (write-the-change.md: GPC)
7. A stored Reject always wins; a stored Accept wins, except one given while GPC was off, once GPC is on, where the site collects by default; an Accept given with GPC on is stored with that fact and counts. Look: where the stored choice is read, and what an Accept stores. (write-the-change.md: GPC)

## The link and the banner

8. "Your privacy choices" is added by the consent module itself, on every page that can run analytics. Look: every page that loads the module or an analytics tag. (write-the-change.md: The opt-out link)
9. It sits beside every link to the privacy policy the site already shows: a footer's legal links, an account or settings menu (one drawn later too), a sign-in page. Look: search the site for links to the policy, and check each one. (write-the-change.md: The opt-out link)
10. It has the same element and classes as its neighbours, and nothing styles it apart; it is never an unstyled native button. Look: the markup it adds, and the stylesheet rules its neighbours match. (write-the-change.md: The opt-out link)
11. It appears once per document, however often the module runs. Look: the module's guard against a second link. (write-the-change.md: The opt-out link)
12. A fixed fallback link appears only on a page that shows the policy's link nowhere: styled to be seen, clear of the page's own fixed or sticky controls, and under its dialogs. Look: the fallback's position, offsets and z-index, against the layout's fixed and sticky elements. (write-the-change.md: The opt-out link)
13. Showing the choice again removes nothing and changes nothing until the visitor picks. Look: the link's handler. (write-the-change.md: Showing the choice again, and withdrawing)
14. The current answer is marked so a sighted visitor sees it (a label, or a style the stylesheet gives it), never only by an ARIA attribute or a class nothing styles. Look: the banner's markup when shown again, and the stylesheet. (write-the-change.md: Showing the choice again, and withdrawing)
15. Where the site collects by default, the choice the link shows says the site collects analytics by default and the visitor can turn it off; it never says "consent". Look: the words each region's visitor is shown. (write-the-change.md: The banner's words, per region)
16. Accept and Reject sit side by side with the same weight, nothing is pre-ticked, no scroll or close means yes, and withdrawing takes no more clicks than agreeing. Look: the banner's markup and styles. (write-the-change.md: Refusing is as easy as agreeing)

## A page framed by the same site

17. A page shown in a frame of another page of the same site draws no link and no banner of its own. Look: the module's frame check, in a page that is framed. (write-the-change.md: A page framed by the same site)
18. The top page's Reject and Accept reach a framed page that loaded the module: on a Reject it sends the denied update and each tool's opt-out, on an Accept the update and each opt-in (a `storage` listener on the consent key, a message, or a reload of the frame). Look: in every document that loads the module, the top page and a page framed in it. (write-the-change.md: A page framed by the same site)

## Withdrawing

19. Reject sends the denied Consent Mode update at once. Look: the Reject handler. (write-the-change.md: Showing the choice again, and withdrawing)
20. Reject stops each tool that runs on consent, through the tool's own opt-out, and is stored. Look: the Reject handler, for each tool the site loads. (write-the-change.md: Showing the choice again, and withdrawing)
21. Accept turns back on everything a Reject turned off, a tool's own stored opt-out included. Look: the Accept handler, and what a page does with a stored Accept. (write-the-change.md: Showing the choice again, and withdrawing)

## Consent Mode and the Google tag

22. `gtag('consent', 'default', …)` with every type denied runs before any command that sends data (`config`, `event`). Look: the order of the default, the loader and `config` on every page that loads the tag. (write-the-change.md: Consent Mode, with gtag's own commands only)
23. A choice sends `gtag('consent', 'update', …)` at once, and every later page sends it from the stored choice. Look: the path that applies a decision. (write-the-change.md: Consent Mode, with gtag's own commands only)
24. `analytics_storage` follows the analytics choice, and `ad_storage`, `ad_user_data` and `ad_personalization` follow the marketing choice: a region that collects by default, and a site with no advertising tag, never sends a granted ad type without a yes to marketing. Look: every consent update the module sends. (write-the-change.md: Consent Mode, with gtag's own commands only)
25. `gtag` and `dataLayer` are never wrapped, replaced or patched, and the stub the consent default needs is local to the module. Look: where the module defines its gtag. (write-the-change.md: Consent Mode, with gtag's own commands only; A global other code reads is a signal)
26. No global other code reads (`window.gtag`, a consent flag) is created or changed before it means leave to send, and every reader of each still behaves. Look: search for each global the change touches, and read each reader. (write-the-change.md: A global other code reads is a signal)
27. The Google tag is only added to: every loader, `config` command and `gtag` definition stays, and only when they run changes. Look: every removed line of the files that load the tag. (write-the-change.md: The Google tag is only added to, never taken away)

## Third-party calls

28. Each third-party method the change calls that changes a tool's state (an opt-in, an opt-out, a reset) does what the installed version's source or docs say it does, for what it stores and what it sends. Look: the tool's installed source, call by call. (write-the-change.md: A third-party call does what its installed version does)
29. A tool call made on every page load sends nothing and changes nothing when the state is unchanged (PostHog: opt in only when opted out, without its `$opt_in` event). Look: what a page load runs, call by call. (write-the-change.md: A third-party call does what its installed version does)

## The privacy policy and public pages

30. The policy's basis matches each region: consent where the site asks first; by default, with an easy opt-out and GPC honoured, elsewhere, with the basis named and never called consent. Look: the policy's text for each region, against the decision code. (write-the-change.md: The privacy policy says what the code does, region by region)
31. What the policy says "Your privacy choices", Reject and Accept do is what the code does, in a framed page too, and where the link is; never "stops everything at once" unless the code does. Look: each such sentence, against the handlers in the top page and a framed page. (write-the-change.md: The privacy policy says what the code does, region by region; A page framed by the same site)
32. The policy says what the server logs are for, what a line holds and how long the raw logs are kept. Look: the policy, against the log line and the platform script's expiry. (write-the-change.md: The privacy policy says what the code does, region by region)
33. Only the sentences the change makes untrue are changed, new paragraphs are added beside the old ones, and no paragraph about something else is replaced. Look: every removed line of the policy. (write-the-change.md: The privacy policy says what the code does, region by region)
34. No note meant for the person (not legal advice, a recommendation, a caveat) is on a public page or in a public file. Look: every public page and public asset the diff touches. (write-the-change.md: Notes for the person stay with the person)

## The tests

35. The consent tests load the module itself with a fake region source (a header, none, no answer in time, an error), a fake GPC flag and fake storage; a test that only matches source text proves nothing. Look: the tests' harness. (write-the-change.md: The consent tests run the module)
36. They cover a consent-first region, a region that collects by default, an unknown region, a timeout, GPC, a stored choice, and a withdrawal then the next page. Look: a test for each case. (write-the-change.md: The consent tests run the module)
37. They cover the top page's Reject reaching a page of the same site framed in it that loaded the module (the denied update and each tool's opt-out there), with no link drawn in the framed page. Look: the frame's test. (write-the-change.md: The consent tests run the module)
38. They cover a region that collects by default sending no `granted` ad type. Look: the default region's test, at every consent update. (write-the-change.md: The consent tests run the module)
39. They cover a page load with the choice unchanged making no tool call that sends an event. Look: the test of a second page load. (write-the-change.md: The consent tests run the module)
40. The consent code, the link, the policy and the consent tests change together; a test that pinned the old behaviour is updated, never deleted, and no assertion still true is removed or loosened. Look: every removed line of every test file. (write-the-change.md: The consent change is one change)
41. The server's tests request the log line as a browser would: a page, and a `304` to a top-level document GET, are counted; a `304` to anything else, a frame, a prefetch, a HEAD, an asset, a 404 and a redirect are not. Look: the log line's test. (write-the-change.md: The server's tests run the log line)

## The server's log line

42. One line per page opened: only a GET of a top-level document (`Sec-Fetch-Dest: document`, or the header absent), never a frame, a prefetch or prerender, a HEAD or an asset. Look: the middleware's checks of the request. (write-the-change.md: The server's log line counts each page it sends, once)
43. It is written when the response finishes, for a 2xx HTML response or a `304` to a request that says it is a top-level document, never a 404, a redirect, a dot-file or an error page. Look: the finish handler's status and type checks, against how the server caches its HTML (`ETag`, `Cache-Control`). (write-the-change.md: The server's log line counts each page it sends, once)
44. Its middleware is mounted before every route that answers a page, so every page passes through it. Look: the server's order of middleware, page routes and static files. (write-the-change.md: The server's log line counts each page it sends, once; do-the-work.md: The log line, first)
45. It is written in the server's own structured log shape (its severity and message fields). Look: an existing structured log line beside it. (write-the-change.md: The server's log line counts each page it sends, once)
46. It holds the page path, the region, `ref` and `utm_*`, the referring host and a bot verdict, and no IP address or full user agent. Look: the line it writes. (write-the-change.md: The server's log line counts each page it sends, once)

## The platform

47. Where the repository already configures the load balancer's headers or a log sink as code, the settings are added there; otherwise gcp-consent-platform.sh is copied beside the deploy script byte for byte, never written or edited. Look: the copy's sha256 against the skill's. (do-the-work.md: The platform script, second; platform-commands.md: Google Cloud: the reviewed script)
48. It is called once, as one of the deploy script's own steps, through its step helper and after its final checks. Look: the deploy script around the call. (platform-commands.md: The one call; do-the-work.md: The one call, third)
49. Every flag of the call is a fact read (the backend, the GA4 export's location, the BigQuery connection's service account, `--request-header` when the line writes the region), and a value the deploy script holds is its own variable, never a literal. Look: the call's flags, against the deploy script's variables. (platform-commands.md: The one call)
50. Every grant is on the raw log dataset only, never a project role, and no write's failure is swallowed. Look: the script and the call. (platform-commands.md: Google Cloud: the reviewed script)
