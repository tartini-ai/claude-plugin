# How to do the work

Part of the ga4-bigquery-consent skill.

A consent change touches few files, but a repository can be large. A turn that reads everything first
runs out of room before it writes anything, and a summary of its context keeps the files it wrote and
loses what it only read.

- **Read only these.** The consent module (or the manager's set-up), the file that loads the Google tag,
  the privacy policy's cookie section, and the tests that name the consent module (search for its file
  name). In a large file, search for the exact symbol and read the lines around it; never read a large
  file whole. The region needs no server code (write-the-change.md): do not read the server for it.
- **Put the opt-out link in from the consent module.** The module runs on every page that can load
  analytics, so it can add "Your privacy choices" to the page's footer itself: one file changed instead
  of every page.
- **Write the whole change before you run anything:** the consent module, the tag loader, the privacy
  policy's cookie section and the consent tests. Then run the project's tests once, fix what fails, and
  save. Do not run the tests first to see where they stand.
- **When the first change is saved, end the turn with what the person needs,** in their language: what
  changed; what they do next (review the draft, publish it, merge the pull request, deploy: nothing
  changes for visitors before that, and until the platform's region header exists every visitor is asked
  first, as today); how to check it once it is live (verify.md, a few lines); and the second change, offered in
  a sentence: what it adds, and that you write it once they say yes.
- **The server's log line and the platform settings are the second change,** written once the first is
  saved and the person has said yes to it, in the order below. Until then, do not look for the deploy
  script or the platform's settings.
- **Keep notes as you go** in `.tartini/notes.md` in your working directory: a line each time you find a
  place you will change (the file and its lines) or decide something, before you read further, and a line
  each time you write a file. It is never part of the change.
- **If your context is summarized mid-change,** you have lost neither the person's answer nor your work:
  read your notes first; read_conversation shows their words (the turn you are answering is marked current);
  Tartini AI's notice says what is already saved in the draft and which files you have written for the change
  that is open. In the workspace the saved draft is committed, so `git status` and `git diff` show only the change you are writing now, never
  the first change again: a saved change is done. Carry on with the next file to write. Never end the turn with a plan, or
  with a question they have already answered.

## The second change, in this order

Three small pieces. Write each one as soon as you know what goes in it, then go on to the next.

1. **Begin it once,** with begin_draft_correction. It stays open until finish_event_implementation answers,
   through any summary of your context: do not begin it a second time. `git status` in the workspace lists
   only what you have written for it, so an empty one means nothing is written yet, not a conflict.
2. **The log line, first.** Search for the one place the server answers a request for a page (its static
   file handler or its page route) and read only the lines around that match, never the server file
   whole. Add the line there at once, the way the server already writes a structured log line
   (write-the-change.md says what it holds), and note the file and where.
3. **The platform settings, second.** Search once for code that already configures the load balancer's
   headers or a log sink (Terraform, a deploy step that sets them) and add them there. Where there is none,
   do not search further: write ONE new script beside the deploy script (for example
   `scripts/setup-consent-platform.sh`) in one go, from platform-commands.md, idempotent and with a dry
   run. Each step reads what is set before it changes anything and creates only what is missing (a
   backend's existing headers are kept), and the dry run shows what it would do. It needs no other script
   of the repository as a pattern. Note it.
4. **The one call, third.** Search the deploy script for where its last step runs, read those lines, and
   add the one line that runs the new script. Never read the deploy script whole.
5. **Then the tests, once.** Run the project's whole test script and read only what failed: a test that
   pins the deploy script or the server says there what it expects. Fix what your change broke, then
   finish_event_implementation. Do not read the tests before you write, to guess what they will say.

You never run it: it is applied by the person's next deploy, and your reply says so, with the dry run they
can run first. With no deploy script at all, give the person platform-commands.md's commands with their
names.
