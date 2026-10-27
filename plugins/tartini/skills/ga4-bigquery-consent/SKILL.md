---
name: ga4-bigquery-consent
description: Design how a website asks visitors for cookie consent and still measures its traffic with Google Analytics 4 and BigQuery. Read it before recommending or changing a cookie banner, a consent manager, Google Consent Mode, which visitors are counted, or a traffic total that does not depend on consent (server or CDN logs in BigQuery), and when a person asks why GA4 shows fewer visitors than they expect.
metadata:
  channels: web, mcp, plugin
---

# GA4 + BigQuery and cookie consent

How a site asks for consent decides who GA4 can see: a site that asks everyone before any analytics runs
sees only the visitors who click Accept. This skill is the practice Tartini AI recommends, in order: find
out what the site does today, decide what fits its visitors, make the change the person asked for, and tell
them what it did. It is not legal advice, and the reply says so.

## When to use it

When the request or the work touches a cookie banner or consent manager, Google Consent Mode, whether
analytics runs before, after or without a visitor's choice, GPC or an opt-out link, where visitors are,
GA4 numbers that look too low, or a page-view count that does not depend on consent. Not for an ordinary
event: a new event goes through whatever consent the site already has.

## Essentials

- **A request to change it is the person's yes.** "Change it to what fits", "switch it to...", "implement
  it", "set it up": find out, decide, then make BOTH changes and save each, in this turn, with no choice
  question first, and end with one reply (tell-the-person.md). Only a question that asks your opinion
  ("what do you think", "should we") or an unclear goal gets the recommendation and waits for their answer.
- **Find out first, from the code and the data** (find-out-first.md): the consent mechanism, when the
  Google tag starts, what the privacy policy and the consent tests promise, where the visitors are, where
  the site runs, and whether GA4 exports to BigQuery. Ask only what neither can answer.
- **Decide from decide.md's table.** For a site asking everyone whose visitors are mostly outside Europe:
  region-aware. Consent first in the EEA (with the EU's outermost regions and Åland), the UK, Switzerland
  and wherever the region is unknown; elsewhere collect by default, with an opt-out link and GPC honoured. A person who wants to keep collecting from
  everyone is kept so, with the risks said once.
- **The first change, consent** (write-the-change.md): the consent module, the tag loader, a "Your privacy
  choices" link the module adds beside the site's privacy-policy links itself, the privacy policy and the
  consent tests, together. The region comes from the edge (`X-Client-Region` on Google Cloud's load balancer), read with one
  same-origin request before anything is shown; no answer within half a second means consent first. The
  policy states, per region, what the code does. Notes for the person stay in your reply.
- **The second change, the server's total** (do-the-work.md): one log line for each page the server sends,
  written when its response finishes, and the platform settings. On Google Cloud they are this skill's
  reviewed script, copied whole beside the deploy script and called once from it as one of its steps, with
  flags from facts (platform-commands.md); never write cloud automation yourself. You never run it: the
  person's next deploy does, after its dry run.
- **Work in few files** (do-the-work.md): find out first with one call to your exploration subagent, then
  read by search, write each piece as soon as you know it, run the project's tests once per change, and keep
  notes in `.tartini/notes.md`.

## Review checklist

The items are review-checklist.md, beside this file: the properties a correct consent change has, one rule
each, numbered for the reviewer's ledger (`checklist.ga4-bigquery-consent.<n>`), each saying where to look.
Read it whole before you write each change and again before its review: the reviewer checks every item, in
every document the code runs in (a top page, and a page framed in it).

## Reply checklist

The one reply that ends the turn, in the person's language (tell-the-person.md), when their message asked for the change:

1. What you found: the consent mechanism, when the Google tag starts, where the visitors are (in users, never events; only those GA4 counted, on a site that asks everyone the consenting few; "not enough to tell" with too few), whether GA4 exports to BigQuery and where the site runs, and what that cost them (who GA4 could not see).
2. What each saved change does, and why it fits their visitors.
3. What they do next: review the draft, publish it, merge the pull request and deploy. Nothing changes for visitors before that, and until the region header exists every visitor is asked first. The platform script's dry run, to run before the deploy: the deploy script's line, without `--apply`, every value filled in from what you read, so it runs as pasted (no shell variable they have not set).
4. How to check it once it is live, in a few lines.
5. The risks of what you did, and that this is common practice, not legal advice.

When their message only asked your opinion: 1, what you recommend and why, the two changes it takes, and 5; then wait.

## The files of this skill

Each is a file beside this one, read whole when a step needs it: with your read tool at the skill's base
directory, or on Claude Code's channel with read_skill({ name: "ga4-bigquery-consent", file: "<file>" }).

- find-out-first.md: what to read in the code and the data before deciding.
- decide.md: the recommendation table, the consent-first regions and the UK's 2026 change.
- tell-the-person.md: when a request is the yes, what the one reply says, and how to check it once live.
- write-the-change.md: the region from the edge (with the decision code), GPC, the link, framed pages and withdrawing, Consent Mode, third-party calls, the policy, the log line, the tests.
- do-the-work.md: both changes in one turn, in order, in few files, and how to carry on after a summary.
- platform-commands.md: the Google Cloud script, how to copy it and fill its flags, and other hosts.
- review-checklist.md: what a correct change has, one numbered item per rule, for you and the reviewer.
- gcp-consent-platform.sh: the Google Cloud script itself, copied byte for byte.
- bigquery.md: what the GA4 export holds, logs into BigQuery and the two metrics.
- sources.md: the sources.
