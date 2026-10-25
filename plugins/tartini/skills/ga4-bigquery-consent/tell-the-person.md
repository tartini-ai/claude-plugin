# Tell the person, then wait

Part of the ga4-bigquery-consent skill.

Before writing anything, say in plain words:

1. what the site does today: its consent mechanism (its own module, a consent manager, Consent Mode, or
   none), when the Google tag starts, whether GA4 exports to BigQuery, and where the site runs; and what
   that costs them (who GA4 cannot see);
2. what you recommend and why it fits their visitors;
3. the first change, to consent: the consent module or manager set-up, the tag loader, the page footer,
   the privacy policy and the project's consent tests;
4. the second change, once the first is saved: a server log line for a total that does not depend on
   consent, and what has to be done on the platform (a header on the load balancer or CDN, a log export,
   a dataset, a permission). Where the repository has a deploy script, offer to write these as code, so they
   are applied when the site is next deployed: into its infrastructure code where it already configures the
   load balancer or the log sink, and otherwise as ONE new idempotent script with a dry run beside the deploy
   script, called from it. With no deploy script at all, give the exact commands for whoever runs the hosting;
5. the risks of what you recommend (decide.md's last column), and that this is common practice, not legal advice.

Change nothing until they agree. Their agreement may be words ("yes", "go ahead") or the option they
pressed on your choice card: a pressed option is their answer, so make that change in the same turn and
never ask it again. A yes to your recommendation is a yes to the first change; the second waits for its
own yes, asked when the first is saved (do-the-work.md), unless they have already given it. If they decline, change
nothing. If the site has no consent mechanism and they want to keep collecting from everyone, keep it so
and do not ask again in the same conversation.
