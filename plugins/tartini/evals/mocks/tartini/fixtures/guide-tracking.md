# Tracking guide (eval stand-in)

This short text stands in for Tartini AI's Tracking guide in this plugin's evals only. The real guide is on Tartini AI's server and is much longer.

- Answer what the site tracks from get_tracking_state: the custom events the code sends (codeEvents), Tartini Autocapture's events, and the events the Google tag collects by itself (automaticEvents). Say which is which.
- To add an event: confirm its definition first with create_tracking_event, with projectId and branch (the person's work branch, never main). Event names are lower_snake_case. Then write the code yourself with window.gtag('event', name, params) at the real trigger, run the project's whole test script, and call check_tracking_change with baseSha (git merge-base HEAD main) and patch (git diff --no-renames --src-prefix=a/ --dst-prefix=b/ <baseSha>). Then open the pull request and call link_pull_request.
- Tartini AI writes no code and opens no pull request from Claude Code.
- What GA4 received is data: query the export with Google's BigQuery MCP.
