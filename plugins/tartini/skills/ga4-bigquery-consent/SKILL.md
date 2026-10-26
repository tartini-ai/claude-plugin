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
  region-aware. Consent first in the EEA, the UK, Switzerland and wherever the region is unknown; elsewhere
  collect by default, with an opt-out link and GPC honoured. A person who wants to keep collecting from
  everyone is kept so, with the risks said once.
- **The first change, consent** (write-the-change.md): the consent module, the tag loader, a footer link
  "Your privacy choices" added by the module itself, the privacy policy and the consent tests, together.
  The region comes from the edge (`X-Client-Region` on Google Cloud's load balancer), read with one
  same-origin request; no answer within half a second means consent first. The policy states, per region,
  what the code does. Notes for the person stay in your reply.
- **The second change, the server's total** (do-the-work.md): one log line where the server sends a page,
  counted once per visit, and the platform settings. On Google Cloud they are this skill's reviewed script,
  copied whole beside the deploy script and called from it with flags from facts (platform-commands.md);
  never write cloud automation yourself. You never run it: the person's next deploy does, after its dry run.
- **Work in few files** (do-the-work.md): find out first with one call to your exploration subagent, then
  read by search, write each piece as soon as you know it, run the project's tests once per change, and keep
  notes in `.tartini/notes.md`.

## Review checklist

- The Google tag, its loaders and its `config` commands are only added to: none is removed or wrapped.
- Every consent-first region (the EEA, the UK, Switzerland) and an unknown or missing region ask first.
- A stored choice wins; collecting by default is never stored as the visitor's choice.
- GPC is honoured as an opt-out wherever the site collects by default.
- "Your privacy choices" reopens the choice on every page that can run analytics.
- The privacy policy's basis matches each region: consent where it asks first; collected by default with an easy opt-out and GPC elsewhere, never called consent; what the server logs are for.
- No note meant for the person (not legal advice, a recommendation, a caveat) is on a public page.
- The project's consent tests pin the new behaviour; none was deleted.
- One page load per visit: the log line counts a top-level document GET only, never a frame, a prefetch or a HEAD, and holds no IP address.
- On Google Cloud the platform half is gcp-consent-platform.sh, byte for byte, called once from the deploy script with flags read from facts.
- Every grant is on the raw log dataset only, never a project role, and no write's failure is swallowed.

## The files of this skill

Each is a file beside this one, read whole when a step needs it: with your read tool at the skill's base
directory, or on Claude Code's channel with read_skill({ name: "ga4-bigquery-consent", file: "<file>" }).

- find-out-first.md: what to read in the code and the data before deciding.
- decide.md: the recommendation table, the consent-first regions and the UK's 2026 change.
- tell-the-person.md: when a request is the yes, what the one reply says, and how to check it once live.
- write-the-change.md: the region from the edge (with the decision code), GPC, the opt-out link, Consent Mode, the privacy policy, the log line.
- do-the-work.md: both changes in one turn, in order, in few files, and how to carry on after a summary.
- platform-commands.md: the Google Cloud script, how to copy it and fill its flags, and other hosts.
- gcp-consent-platform.sh: the Google Cloud script itself, copied byte for byte.
- bigquery.md: what the GA4 export holds, logs into BigQuery and the two metrics.
- sources.md: the sources.
