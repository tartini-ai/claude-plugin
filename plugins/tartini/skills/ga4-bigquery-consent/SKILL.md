---
name: ga4-bigquery-consent
description: Design how a website asks visitors for cookie consent and still measures its traffic with Google Analytics 4 and BigQuery. Read it before recommending or changing a cookie banner, a consent manager, Google Consent Mode, which visitors are counted, or a traffic total that does not depend on consent (server or CDN logs in BigQuery), and when a person asks why GA4 shows fewer visitors than they expect.
metadata:
  channels: web, mcp, plugin
---

# GA4 + BigQuery and cookie consent

How a site asks for consent decides who GA4 can see: a site that asks everyone before any analytics runs
sees only the visitors who click Accept. This skill is the practice Tartini AI recommends, in order: find
out what the site does today, decide what fits its visitors, tell the person and wait for their answer,
then write the change. It is not legal advice, and saying so is part of telling the person.

## When to use it

When the request or the work touches a cookie banner or consent manager, Google Consent Mode, whether
analytics runs before, after or without a visitor's choice, GPC or an opt-out link, where visitors are,
GA4 numbers that look too low, or a page-view count that does not depend on consent. Not for an ordinary
event: a new event goes through whatever consent the site already has.

## Essentials

- **Find out first, from the code and the data** (find-out-first.md): the consent mechanism (none, the
  site's own module, a consent manager, Consent Mode), when the Google tag starts relative to it, what the
  visitor can do, what the privacy policy and the project's consent tests promise, where the visitors are,
  where the site runs, and whether GA4 exports to BigQuery. Ask the person only what neither can answer.
- **Decide from decide.md's table, and say why.** For a site asking everyone whose visitors are mostly
  outside Europe: region-aware. Consent first in the EEA, the UK, Switzerland and wherever the region is
  unknown; elsewhere collect by default, with an opt-out link and GPC honoured. The person decides.
- **Tell the person, then wait** (tell-the-person.md): what the site does today and what it costs them,
  the recommendation, the first change (consent) and the second (a total that does not depend on
  consent), the risks, and that this is common practice, not legal advice. A pressed option is their
  answer. The second change waits for its own yes, asked once the first is saved.
- **The first change is one change** (write-the-change.md): the consent module, the tag loader, a footer
  link "Your privacy choices" added by the module itself, the privacy policy's cookie section and the
  project's consent tests, together. The region comes from the edge (`X-Client-Region` on Google Cloud's
  load balancer), read with one same-origin request; no answer within half a second means consent first.
  GPC is an opt-out. The Google tag is only added to, never wrapped or taken away.
- **The second change, the server's total** (do-the-work.md's order, platform-commands.md's commands): one
  structured log line where the server sends a page, and the platform settings (the header, a log sink, a
  dataset) as code. Where the repository has no infrastructure code for the load balancer or the log sink,
  do not search for it: add ONE new idempotent script with a dry run beside the deploy script, call it from
  the deploy script, and stop there. Write each piece as soon as you know it: the log line, the script, then
  the one call, found by searching the deploy script, never reading it whole. You never run it; the
  person's next deploy does.
- **Work in few files** (do-the-work.md): read only the consent module, the tag loader, the privacy
  policy's cookie section and the tests that name the module, by search; write the whole change, run the
  project's tests once, fix what is yours, and save. Keep notes in `.tartini/notes.md`. A saved change is
  done: in the workspace it is committed, and `git status` shows only the change you are writing now.

## The files of this skill

Each is a file beside this one, read whole when a step needs it: with your read tool at the skill's base
directory, or on Claude Code's channel with read_skill({ name: "ga4-bigquery-consent", file: "<file>" }).

- find-out-first.md: what to read in the code and the data before deciding.
- decide.md: the recommendation table, the consent-first regions and the UK's 2026 change.
- tell-the-person.md: what to say before writing anything, and when to wait.
- write-the-change.md: the region from the edge (with the decision code), GPC, the opt-out link, Consent Mode, the log line.
- do-the-work.md: how to do the work in few files, the second change's order, and how to carry on after a summary.
- bigquery.md: what the GA4 export holds, logs into BigQuery and the two metrics.
- verify.md: how to check it once it is live.
- platform-commands.md: the Google Cloud commands, and where they go as code.
- sources.md: the sources, checked on 2026-10-22.
