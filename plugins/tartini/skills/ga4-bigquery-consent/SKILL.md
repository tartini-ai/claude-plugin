---
name: ga4-bigquery-consent
description: Design how a website asks visitors for cookie consent and still measures its traffic with Google Analytics 4 and BigQuery. Read it before recommending or changing a cookie banner, a consent manager, Google Consent Mode, which visitors are counted, or a traffic total that does not depend on consent (server or CDN logs in BigQuery), and when a person asks why GA4 shows fewer visitors than they expect.
metadata:
  channels: web, mcp, plugin
---

# GA4 + BigQuery and cookie consent

How a site asks for consent decides who GA4 can see: a site that asks everyone before any analytics runs
sees only the visitors who click Accept. This skill is the practice Tartini AI recommends: find out what the
site does, decide what fits its visitors, propose it, and make it once the person agrees. It is not legal
advice, and the reply says so.

## When to use it

When the request or the work touches a cookie banner or consent manager, Google Consent Mode, whether
analytics runs before, after or without a visitor's choice, GPC or an opt-out link, where visitors are,
GA4 numbers that look too low, or a page-view count that does not depend on consent. Not for an ordinary
event: a new event goes through whatever consent the site already has.

## Essentials

- **Propose first; build on the person's yes.** A request to change it ("change it to what fits", "set it
  up") gets a proposal first: find out all that both changes need, decide, and end the turn on the proposal
  (tell-the-person.md), changing nothing (no begin_draft_correction, no edit; an item for the changes on your
  todo list is cancelled, "waiting for the person's yes"). Their yes ("ok, implement it", with or without
  changes) starts the work, one change per turn, each saved: the first in the turn of their yes, the second in
  the job Tartini AI continues with (do-the-work.md), nothing decided or investigated again. A question ("what
  do you think", "should we") or an unclear goal gets the recommendation and waits too.
- **Find out first, from the code and the data** (find-out-first.md): the consent mechanism, when the
  Google tag starts, what the privacy policy and the consent tests promise, where the visitors are, where
  the site runs, and whether GA4 exports to BigQuery. Ask only what neither can answer.
- **Decide from decide.md's table.** For a site asking everyone whose visitors are mostly outside Europe:
  region-aware. Consent first in the EEA (with the EU's outermost regions and Åland), the UK, Switzerland
  and wherever the region is unknown; elsewhere collect by default, with an opt-out link and GPC honoured. A person who wants to keep collecting from
  everyone is kept so, with the risks said once.
- **The first change, consent** (write-the-change.md): its acceptance tests first (the proposal's data
  scenarios, on the site's real scripts in one page); then the consent module, the tag loader, a "Your
  privacy choices" link the module adds beside the site's privacy-policy links, the policy and the tests. The region comes from the edge (`X-Client-Region` on Google Cloud's load balancer), read with one
  same-origin request before anything is shown; no answer within half a second means consent first. The
  default decision starts what the site's own gate holds back, without storing a choice. The policy, and every
  public page, states per region what the code does. Notes for the person stay in your reply.
- **The second change, the server's total** (do-the-work.md): one log line for each page the server sends,
  written when its response finishes, and the platform settings. On Google Cloud they are this skill's
  reviewed script, copied whole beside the deploy script and called once from it as one of its steps, with
  flags from facts (platform-commands.md); never write cloud automation yourself. You never run it: the
  person's next deploy does, after its dry run.
- **Work in few files** (do-the-work.md): in the proposal's turn, find out with one call to your exploration
  subagent; in the yes turn, read only the lines the proposal's implementation notes name, write each piece as
  soon as you know it, run the project's tests once per change, and keep notes in `.tartini/notes.md`.

## Review checklist

The items are review-checklist.md, beside this file: one rule each, numbered for the reviewer's ledger
(`checklist.ga4-bigquery-consent.<n>`), each saying where to look, in groups under its headings. Read it before
you write each change. A save waits for one reviewer that traces each data scenario of the proposal and one per
group not marked advisory (the red lines), all started in one message; an advisory group's review holds no
save.

## Reply checklist

Two replies, in the person's language (tell-the-person.md). When their message asks for the change, the turn ends on the proposal and changes nothing:

1. What you found: the consent mechanism, when the Google tag starts, where the visitors are (in users, never events; only those GA4 counted, on a site that asks everyone the consenting few; the first and last day the data covers; with tens of users "not enough to tell", never "mostly"), whether GA4 exports to BigQuery and where the site runs, and what that cost them (who GA4 could not see).
2. The one architecture you recommend and why it fits their visitors, never a menu: what visitors get in each region, each analytics tool and how it is turned on and off, the opt-out link, the server's total and its platform settings (what is created, a rough cost).
3. The two changes, and the files or areas each touches.
4. The risks, a line each (a wrong region estimate, a VPN or travel, is taken as the region it names; only a missing or late answer asks first), and that this is common practice, not legal advice.
5. One line asking them to agree or to say what to change; then, last and brief, the implementation notes: for each change, its files and where the code goes, as file:line, and its acceptance tests, a line each.

After their yes, one change per turn: the turn that saves the first ends with one line of what was saved and what is next; the one that saves the last ends with:

6. What each saved change does; the tests in counts, never a test's name.
7. What they do next: review the draft, publish it, merge the pull request and deploy. Nothing changes for visitors before that, and until the region header exists every visitor is asked first. The platform script's dry run, to run before the deploy: the deploy script's line, without `--apply`, every value filled in from what you read, so it runs as pasted (no shell variable they have not set).
8. How to check it once it is live, in a few lines.
9. The risks of what you did, as in 4.

When their message only asked your opinion: 1 to 4; then wait.

## The files of this skill

Each is a file beside this one, read whole when a step needs it: with your read tool at the skill's base
directory, or on Claude Code's channel with read_skill({ name: "ga4-bigquery-consent", file: "<file>" }).

- find-out-first.md: what to read in the code and the data before deciding.
- decide.md: the recommendation table, the consent-first regions and the UK's 2026 change.
- tell-the-person.md: the proposal, the yes, the replies, and how to check it once live.
- write-the-change.md: how each part of both changes is written, and their tests.
- do-the-work.md: the proposal's turn, then one change per turn, in few files, and after a summary.
- platform-commands.md: the Google Cloud script, its flags, its cost, and other hosts.
- review-checklist.md: one numbered item per rule, in groups, for you and the reviewers.
- gcp-consent-platform.sh: the Google Cloud script itself, copied byte for byte.
- bigquery.md: what the GA4 export holds, logs into BigQuery and the two metrics.
- sources.md: the sources.
