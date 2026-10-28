# How to do the work

Part of the ga4-bigquery-consent skill.

The work is a proposal, then one change per turn (tell-the-person.md): the turn of the request finds out and
ends on the proposal, changing nothing; the turn of the person's yes makes and saves the first change, and the
job Tartini AI continues with makes and saves the second. A repository can be
large: a turn that reads everything first runs out of room before it writes, and a summary of its context
keeps the files it wrote and loses what it only read. So the finding out is the proposal's, and the turn that
writes reads little, writes each piece as soon as it knows it, and keeps notes.

## The proposal's turn: find out

- **Find out first with one call.** Ask your exploration subagent once (on the web, Tartini AI's explorer
  through task; in Claude Code, its Explore agent), with every code question of find-out-first.md in its
  prompt: where the consent module (or the manager's set-up) is, how its gate releases the loaders that wait
  for a category (only on a stored answer, or on any decision), the file that loads the Google tag and every
  other reader of the globals the consent change touches (`window.gtag`, `dataLayer`), every place that links
  the privacy policy (a footer's list, an account or settings menu, a sign-in page) with the list's separator
  and its items' markup, which of them a shell or menu draws after load, and the policy links inside running
  text or the banner, the layout's fixed or sticky controls at every width (its media queries) and its dialogs'
  z-index, the pages a page of the site shows in a frame, the privacy policy's cookie section and every other
  public page that describes the old behaviour, the tests that name the consent module or pin those sentences,
  the installed version of each tool the module calls and when each loads relative to the module, the deploy
  script's step helper, its final checks and the backend its load balancer sends the site to, the order in
  which the server mounts its middleware, its page routes and its static files, the shape of the structured log
  line it already writes (where, and its fields), and how it caches its HTML (`ETag`, `Cache-Control`). It
  searches in its own context and answers with file:line facts and short excerpts. The data questions (where
  the visitors are, the BigQuery export) are your own tools'.
- **Then propose, and change nothing.** Decide from what it answered (decide.md), and put what the changes
  need of its answer into the proposal's implementation notes, as file:line (tell-the-person.md). Your notes
  file and the explorer's answer do not outlive this turn; the proposal, in the conversation, does.

## The yes turn: build what was agreed, one change per turn

- **One change per turn.** The turn of their yes makes the first change (consent), saves it, and ends with one
  line saying what was saved and what comes next. On the web, begin it with begin_draft_correction naming the
  second change in remainingChanges: that, not your todo list, is what makes Tartini AI continue the plan in a new
  job of this conversation (its message starts SERVER CONTINUATION), which begins the second with
  remainingChanges: [], saves it and ends with the reply (tell-the-person.md). In that job the first change is
  already saved: begin the second. In Claude Code, carry on with the second yourself once the first is saved.
- **The proposal is the spec.** The architecture they agreed and its implementation notes are your reply just
  before their yes, in the conversation so far (and through read_conversation where you have it); their yes may
  change some of it. Do not decide again or investigate again. Your todo list is this turn's own work, and starts at
  writing: the change's acceptance tests, its files, its review, the tests and its save.
- **Read only these.** The lines you will change, by the lines the implementation notes name. Never read a
  large file whole. A place the notes do not name is found by search, not by reading around it; a proposal with
  no notes (it answered a question) gets the one explorer call above first. The region needs no server code
  (write-the-change.md).
- **The request, for every subagent,** is the person's message that asked for the change and the architecture
  they agreed, word for word from the proposal: their yes alone says nothing to a worker or a reviewer.
- **Keep notes as you go** in `.tartini/notes.md` in your working directory: a line for each place you will
  change (the file and its lines), each decision, and each file you write. It is never part of the change.

## The first change: consent

Begin it with begin_draft_correction (on the web with the second change in remainingChanges). **Its acceptance
tests first** (write-the-change.md): one test per data scenario of the proposal, each loading the site's real
consent, tag and vendor scripts together in one page, in the order and at the moments the pages load them, with
the region answering late too, and asserting what the Google tag and each tool receive; run them, and they fail.
Write the whole change before you run anything else: the consent module (it adds the "Your privacy choices" link
beside the privacy policy's links itself, so one file serves every page), the tag loader, the privacy policy and
every public page it makes untrue, and the consent tests. The change is done when the acceptance tests pass.

These files and this skill's rules together seldom fit one context. When they will not, keep the plan
yourself and split the change into parts that share no file, each written by a worker (on the web, Tartini
AI's worker through task; in Claude Code, a subagent of its own): for example the consent module and its
tests; the tag loader and the other readers of the globals it touches; the privacy policy, the other public
pages and the tests that pin their sentences. Give each worker the request (above) word for word, its files,
the rules of write-the-change.md and the review-checklist.md items its files must meet by number, the
implementation notes for those files, and its focused tests; start them all in one message. Their reports say
what each changed; read the change itself with `git diff`, never the files again. Then have the change
reviewed: one reviewer that traces the request's outcome, each data scenario from the scripts a page loads to
what the tag and each tool send, region by region, and one per group of review-checklist.md not marked advisory
(the red lines), all started in one message; a reviewer of an advisory group only when there is time. Fix what
they found (a part's findings go back to that part's worker, continued with its task_id), run the project's
whole test script once, fix what your change broke, and call finish_event_implementation with reviewAnswers
answering every FAIL line and finding that holds the save; an advisory finding you did not fix goes in your
reply. Do not run the whole test script first to see where it stands.

## The second change: the server's total, in this order

Begin it once, with begin_draft_correction and remainingChanges: [] (it is the plan's last), in the job that
continues after the first is saved (in Claude Code, once you saved the first). Its acceptance
test first: the server's test requests pages as a browser would and finds one line per top-level page view, and
none for a frame, an asset, a 404 or a redirect (write-the-change.md). The change stays open until
finish_event_implementation answers, through any summary of your context: do not begin it a second time. An
empty `git status` means nothing is written yet, not a conflict.

1. **The log line, first.** Where the server mounts its middleware, ahead of the first route that answers a
   page, is in the implementation notes, or found by search: read only the lines around that match, never the
   server file whole. Mount the line's middleware there at once, so that every page passes through it, and
   write the line when the response finishes, the way the server already writes a structured log line
   (write-the-change.md says what it holds and which responses count).
2. **The platform script, second.** Where the repository already configures the load balancer's headers or a
   log sink as code (Terraform, a deploy step that sets them), add the settings there. Otherwise, on Google
   Cloud, copy gcp-consent-platform.sh from this skill's base directory beside the deploy script, byte for
   byte (platform-commands.md). Never write it, or any cloud automation, yourself; never edit the copy.
3. **The one call, third.** The deploy script's step helper and its final checks are in the implementation
   notes, or found by search: read those lines, and add the one step that runs the script with `--apply`
   and its flags, through that helper, after the final checks (platform-commands.md). Never read the deploy
   script whole.
4. **Then the review and the tests, once each.** Have it reviewed the same way (one reviewer that traces the
   request's outcome, from the request a browser sends to the line written, and one for the red lines, in one
   message); fix what they found. Run the project's whole
   test script and read only what failed: a test that pins the deploy script or the server says there what it
   expects. Fix what your change broke, then finish_event_implementation with reviewAnswers answering every
   FAIL line and finding. Do not read the tests before you write, to guess what they will say.

You never run the platform script: the person's next deploy does, after its dry run. With no deploy script,
or on another host, write the log line and give the platform's settings in your reply (platform-commands.md).

## If your context is summarized mid-change

You have lost neither the person's request nor your work: read your notes first; read_conversation shows
their words and the proposal they agreed to (the turn you are answering is marked current); Tartini AI's notice says what is already saved in
the draft, what the workspace holds since it (each file and its lines, as git shows them, your workers'
included) and where the explorer's last answer and each worker's report are kept (`.tartini/`): read those
rather than asking again or reading the files. In the workspace the saved draft is
committed, so `git status` and `git diff` show only the change you are writing now: a saved change is done.
Carry on with the next file to write. In the yes turn, never end with a plan, or with a question the
proposal or their yes already answered.
