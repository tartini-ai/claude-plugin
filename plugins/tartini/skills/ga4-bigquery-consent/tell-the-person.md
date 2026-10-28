# What to tell the person

Part of the ga4-bigquery-consent skill.

## A request for the change gets a proposal first

**When their message asks for the change** ("change it to what fits", "switch it to...", "implement...", "set
it up"), answer it with a proposal and end the turn: the person approves the plan before it is built, and a
proposal is cheap to correct where a saved change is not. In this turn, find out all that both changes need
(find-out-first.md, in one call to your exploration subagent: do-the-work.md), decide (decide.md), and change
nothing: no begin_draft_correction, no Event tool, no file written in the code workspace but your notes. Your
todo list holds the finding out and the proposal; an item for the changes themselves is cancelled with
"waiting for the person's yes". Ask no choice question: the proposal recommends one architecture, and the
person agrees or says what to change.

The proposal is short, in their language, readable by someone who does not read code, and it is the spec the
next turn builds:

1. what you found: the consent mechanism (its own module, a consent manager, Consent Mode, or none), when the
   Google tag starts, where the visitors are, whether GA4 exports to BigQuery and where the site runs, and
   what that cost them (who GA4 could not see). Where the visitors are is in users, never events, and only
   those GA4 counted: on a site that asks everyone, the consenting few. Give the dates the data really covers
   (the first and last day it returned, not the window you asked for); with tens of users, give the counts
   and say "not enough to tell", never "mostly";
2. the ONE architecture you recommend and why it fits their visitors, never a menu of options: what visitors
   get in each region (decide.md); each analytics tool the site loads (the Google tag and any other) and how
   the change turns it on and off; the "Your privacy choices" link; and the server's total, with the platform
   settings it needs: what gets created and a rough cost (platform-commands.md);
3. the two changes, and the files or areas each one touches;
4. the risks, one line each (decide.md's last column), and that this is common practice, not legal advice.
   The region is the platform's estimate from the IP address: a wrong estimate (a VPN, travel) is taken as
   the region it names, and only a missing, late or failed answer asks first. Say only what the code will do;
5. one line asking them to agree, or to say what to change. Then, last and brief, the implementation notes
   the next turn builds from, as file:line facts: for the consent change, the consent module and where its gate
   releases what waits, the tag loader, each place the link goes, the privacy policy's sections and the tests
   that pin them; for the server's total, where the server mounts its middleware ahead of its pages, the shape
   of the structured log line it already writes, the deploy script's step helper and final checks, and the
   backend its load balancer sends the site to. And the acceptance tests each change is done when it passes,
   one line each: a default region (the Google tag and each tool start on the first page, a `page_view` with
   `analytics_storage` granted, no banner), the opt-out link and GPC (nothing sent), a consent-first and an
   unknown region (nothing before a choice, Accept starts both, Reject keeps them off), a framed page (the
   same decision as the top page: it starts on its own load where the top page collects by default, and
   follows Accept and Reject where the top page asks first), each in the pages' real load order with the
   region answering late too, and
   the server (one line per top-level page view, none for a frame, an asset, a 404 or a redirect).

## Their yes is the next turn

Their answer agreeing to it ("ok, implement it"), with or without changes, is the go-ahead for the proposal as
they amended it; a pressed option is their answer the same way, when they press one on your choice card. Ask
no question and decide nothing again. Make one change per turn (do-the-work.md): make the first change and save
it, and end that turn with one line saying what was saved and that Tartini AI goes on with the second. The job
Tartini AI continues with makes the second change and saves it, then ends with ONE reply, in their language:

1. what you changed in each of the two saved changes (what you found was in the proposal: a line of it is
   enough); the project's tests in counts (the latest whole run's totals), never a test's name;
2. what they do next: review the draft, publish it, merge the pull request and deploy. Nothing changes for
   visitors before that, and until the platform's region header exists every visitor is asked first, as
   today (that is for your reply, never for a public page).
   Give the platform script's dry run to run before the deploy: the line the deploy script calls, without
   `--apply`, with every value filled in from what you read, so it runs as pasted (no shell variable they
   have not set);
3. how to check it once it is live (below, a few lines);
4. the risks of what you did, as in the proposal's item 4, and that this is common practice, not legal
   advice.

If they decline, change nothing. A site with no consent mechanism whose person wants to keep collecting from
everyone stays so; do not ask again in that conversation.

## A question gets the recommendation

**When their message only asks** ("what do you think", "should we...") or the goal is unclear, say the
proposal's items 1 to 4 (the implementation notes are for a request); then wait. Their yes to it is the next
turn as above, which first finds out the code the changes need (do-the-work.md).

## How to check it once it is live

- The region header: `curl -sI https://SITE/ | grep -i x-client-region` shows your own country.
- GA4 Realtime or DebugView: a visit from an opt-out region with no GPC appears (the Google tag's script is
  requested on the first page, with nothing clicked); with GPC on it does not.
- From a consent-first region (or with the region header missing): the banner shows and nothing reaches
  Google before Accept.
- The server's log line appears once for each page a visitor opens, and lands in the raw log dataset.
- The project's own tests pass, including the updated consent tests.
