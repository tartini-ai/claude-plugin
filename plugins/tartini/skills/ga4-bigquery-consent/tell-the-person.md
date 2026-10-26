# What to tell the person

Part of the ga4-bigquery-consent skill.

**When their message asks for the change** ("change it to what fits", "switch it to...", "implement...", "set
it up"), that is their yes to your recommendation and to both changes. Ask no choice question. Say in a line
or two what you found and what you are doing, make the first change and save it, make the second and save
it, then end the turn with ONE reply, in their language:

1. what you found: the consent mechanism (its own module, a consent manager, Consent Mode, or none), when the
   Google tag starts, where the visitors are, whether GA4 exports to BigQuery and where the site runs, and
   what that cost them (who GA4 could not see);
2. what you changed in each of the two saved changes, and why it fits their visitors;
3. what they do next: review the draft, publish it, merge the pull request and deploy. Nothing changes for
   visitors before that, and until the platform's region header exists every visitor is asked first, as
   today. Give the platform script's dry run to run before the deploy: the line the deploy script calls,
   without `--apply`;
4. how to check it once it is live (below, a few lines);
5. the risks of what you did (decide.md's last column), and that this is common practice, not legal advice.

**When their message only asks** ("what do you think", "should we...") or the goal is unclear, say 1, what you
recommend and why, the two changes it takes, and 5; then wait. Their answer may be words or the option they
pressed on your choice card: a pressed option is their answer, so make the changes in that turn and never ask
it again. If they decline, change nothing. A site with no consent mechanism whose person wants to keep
collecting from everyone stays so; do not ask again in that conversation.

## How to check it once it is live

- The region header: `curl -sI https://SITE/ | grep -i x-client-region` shows your own country.
- GA4 Realtime or DebugView: a visit from an opt-out region with no GPC appears; with GPC on it does not.
- From a consent-first region (or with the region header missing): the banner shows and nothing reaches
  Google before Accept.
- The server's log line appears once for each page a visitor opens, and lands in the raw log dataset.
- The project's own tests pass, including the updated consent tests.
