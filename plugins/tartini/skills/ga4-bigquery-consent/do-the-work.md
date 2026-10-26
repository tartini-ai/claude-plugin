# How to do the work

Part of the ga4-bigquery-consent skill.

Both changes are made in the turn that was asked for them, one after the other. A repository can be large: a
turn that reads everything first runs out of room before it writes, and a summary of its context keeps the
files it wrote and loses what it only read. So read little, write each piece as soon as you know it, and
keep notes.

- **Read only these.** The consent module (or the manager's set-up), the file that loads the Google tag, the
  privacy policy's cookie section, and the tests that name the consent module (search for its file name). In
  a large file, search for the exact symbol and read the lines around it; never read a large file whole. The
  region needs no server code (write-the-change.md).
- **Keep notes as you go** in `.tartini/notes.md` in your working directory: a line for each place you will
  change (the file and its lines), each decision, and each file you write. It is never part of the change.

## The first change: consent

Begin it with begin_draft_correction. Write the whole change before you run anything: the consent module (it
adds the "Your privacy choices" link to the footer itself, so one file serves every page), the tag loader,
the privacy policy and the consent tests. Then run the project's whole test script once, fix what your
change broke, and call finish_event_implementation. Do not run the tests first to see where they stand.

## The second change: the server's total, in this order

Begin it once, with begin_draft_correction, as soon as the first is saved. It stays open until
finish_event_implementation answers, through any summary of your context: do not begin it a second time. An
empty `git status` means nothing is written yet, not a conflict.

1. **The log line, first.** Search for the one place the server answers a request for a page (its static file
   handler or its page route) and read only the lines around that match, never the server file whole. Add
   the line there at once, the way the server already writes a structured log line (write-the-change.md says
   what it holds and how a visit is counted once).
2. **The platform script, second.** Where the repository already configures the load balancer's headers or a
   log sink as code (Terraform, a deploy step that sets them), add the settings there. Otherwise, on Google
   Cloud, copy gcp-consent-platform.sh from this skill's base directory beside the deploy script, byte for
   byte (platform-commands.md). Never write it, or any cloud automation, yourself; never edit the copy.
3. **The one call, third.** Search the deploy script for where its last step runs, read those lines, and add
   the one line that runs the script with `--apply` and its flags (platform-commands.md). Never read the
   deploy script whole.
4. **Then the tests, once.** Run the project's whole test script and read only what failed: a test that pins
   the deploy script or the server says there what it expects. Fix what your change broke, then
   finish_event_implementation. Do not read the tests before you write, to guess what they will say.

You never run the platform script: the person's next deploy does, after its dry run. With no deploy script,
or on another host, write the log line and give the platform's settings in your reply (platform-commands.md).

## If your context is summarized mid-change

You have lost neither the person's request nor your work: read your notes first; read_conversation shows
their words (the turn you are answering is marked current); Tartini AI's notice says what is already saved in
the draft and which files you have written for the change that is open. In the workspace the saved draft is
committed, so `git status` and `git diff` show only the change you are writing now: a saved change is done.
Carry on with the next file to write. Never end the turn with a plan, or with a question their request
already answered.
