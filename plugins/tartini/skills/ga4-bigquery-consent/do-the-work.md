# How to do the work

Part of the ga4-bigquery-consent skill.

A consent change touches few files, but a repository can be large. A turn that reads everything first
runs out of room before it writes anything.

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
  saved and the person has said yes to it. Until then, do not look for the deploy script or the
  platform's settings. For the log line, find the one place the server sends a page (search for it) and
  add the line there (write-the-change.md). The platform settings go in as code (platform-commands.md): where the repository
  already configures the load balancer or the log sink (Terraform, a deploy step that sets them), in that code. Where it
  does not, do not search further: add ONE new script beside the deploy script (for example
  `scripts/setup-consent-platform.sh`), idempotent and with a dry run, call it from the deploy script, and say so in
  your reply. Each step creates only what is missing and reads what is set before it changes anything (a backend's
  existing headers are kept), and the dry run shows what it would do. You never run it: it is applied by the
  person's next deploy. With no deploy script at all, give the person platform-commands.md's commands with their names.
- **Keep notes as you go** in `.tartini/notes.md` in your working directory: the files and line ranges that
  matter, what you decided, what is saved and what is next. It is never part of the change.
- **If your context is summarized mid-change,** you have lost neither the person's answer nor your work:
  read your notes first; read_conversation shows their words (the turn you are answering is marked current);
  Tartini AI's notice says what is already saved in the draft and what the stage holds. In the workspace the
  saved draft is committed, so `git status` and `git diff` show only the change you are writing now, never
  the first change again: a saved change is done. Carry on from there. Never end the turn with a plan, or
  with a question they have already answered.
