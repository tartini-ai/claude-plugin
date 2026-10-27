# How to do the work

Part of the ga4-bigquery-consent skill.

Both changes are made in the turn that was asked for them, one after the other. A repository can be large: a
turn that reads everything first runs out of room before it writes, and a summary of its context keeps the
files it wrote and loses what it only read. So read little, write each piece as soon as you know it, and
keep notes.

- **Find out first with one call.** Ask your exploration subagent once (on the web, Tartini AI's explorer
  through task; in Claude Code, its Explore agent), with every code question of find-out-first.md in its
  prompt: where the consent module (or the manager's set-up) is, the file that loads the Google tag and
  every other reader of the globals the consent change touches (`window.gtag`, `dataLayer`), every place
  that links the privacy policy (a footer, an account or settings menu, a sign-in page) and its markup, the
  layout's fixed or sticky controls, the pages a page of the site shows in a frame, the privacy policy's
  cookie section, the tests that name the consent module, the installed version of each tool the module
  calls, the deploy script's step helper, its final checks and the backend its load balancer sends the site
  to, the order in which the server mounts its middleware, its page routes and its static files, and how it
  caches its HTML (`ETag`, `Cache-Control`). It searches in its own context and answers with file:line facts
  and short excerpts. The data questions (where the visitors are, the BigQuery export) are your own tools'.
- **Read only these.** The lines you will change in those files, by the lines its answer names. Never read a
  large file whole, and never the files it already answered. The region needs no server code
  (write-the-change.md).
- **Keep notes as you go** in `.tartini/notes.md` in your working directory: a line for each place you will
  change (the file and its lines), each decision, and each file you write. It is never part of the change.

## The first change: consent

Begin it with begin_draft_correction. Write the whole change before you run anything: the consent module (it
adds the "Your privacy choices" link beside the privacy policy's links itself, so one file serves every page),
the tag loader, the privacy policy and the consent tests. Then go through review-checklist.md's items for it
yourself, have the change reviewed and fix what the review found, run the project's whole test script once,
fix what your change broke, and call finish_event_implementation. Do not run the tests first to see where
they stand.

## The second change: the server's total, in this order

Begin it once, with begin_draft_correction, as soon as the first is saved. It stays open until
finish_event_implementation answers, through any summary of your context: do not begin it a second time. An
empty `git status` means nothing is written yet, not a conflict.

1. **The log line, first.** Where the server mounts its middleware, ahead of the first route that answers a
   page, is in the explorer's answer, or found by search: read only the lines around that match, never the
   server file whole. Mount the line's middleware there at once, so that every page passes through it, and
   write the line when the response finishes, the way the server already writes a structured log line
   (write-the-change.md says what it holds and which responses count).
2. **The platform script, second.** Where the repository already configures the load balancer's headers or a
   log sink as code (Terraform, a deploy step that sets them), add the settings there. Otherwise, on Google
   Cloud, copy gcp-consent-platform.sh from this skill's base directory beside the deploy script, byte for
   byte (platform-commands.md). Never write it, or any cloud automation, yourself; never edit the copy.
3. **The one call, third.** The deploy script's step helper and its final checks are in the explorer's
   answer, or found by search: read those lines, and add the one step that runs the script with `--apply`
   and its flags, through that helper, after the final checks (platform-commands.md). Never read the deploy
   script whole.
4. **Then the review and the tests, once each.** Go through review-checklist.md's items for this change, have
   it reviewed and fix what the review found. Run the project's whole test script and read only what failed:
   a test that pins the deploy script or the server says there what it expects. Fix what your change broke,
   then finish_event_implementation. Do not read the tests before you write, to guess what they will say.

You never run the platform script: the person's next deploy does, after its dry run. With no deploy script,
or on another host, write the log line and give the platform's settings in your reply (platform-commands.md).

## If your context is summarized mid-change

You have lost neither the person's request nor your work: read your notes first; read_conversation shows
their words (the turn you are answering is marked current); Tartini AI's notice says what is already saved in
the draft and which files you have written for the change that is open. In the workspace the saved draft is
committed, so `git status` and `git diff` show only the change you are writing now: a saved change is done.
Carry on with the next file to write. Never end the turn with a plan, or with a question their request
already answered.
