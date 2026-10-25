---
name: setup
description: Connect a repository to Tartini AI and find out what its analytics project has connected, such as the sign-in to Tartini AI (or its API key, TARTINI_API_KEY, for scripts and CI), which Tartini AI project this git remote belongs to, GitHub, Google Analytics 4 and BigQuery access, and signing in to Google's BigQuery MCP. Use it when someone starts analytics work in a repository for the first time, asks what is connected or set up, wants GA4, Google Analytics or BigQuery set up for a site, or when a Tartini AI or BigQuery tool fails with 401, permission denied or not connected, even if they never mention Tartini.
user-invocable: false
metadata:
  channels: mcp, plugin
---

# Set up Tartini AI for this repository

Tartini AI keeps this project's analytics: its tracking definitions, Measurement Plans, metrics and connections. Its rules and guides live on its server, so this skill is only the order of the calls.

1. Find the repository: run `git remote get-url origin`.
2. Call `get_started` with that remote. It says who is signed in, which Tartini AI project this repository is, what that project has connected, the rules every task follows, and which guides and skills there are. Follow its rules.
   - A 401, or "Sign in: in Claude Code, run /mcp and choose tartini": Claude Code is not signed in to Tartini AI, or the sign-in ended (it lasts up to 90 days, and ends after 30 days without use, or when it was disconnected). Tell the person to run `/mcp`, choose the Tartini AI server (`plugin:tartini:tartini` with the plugin, or the name they gave it with `claude mcp add`, usually `tartini`), then Authenticate, and sign in with Google in the browser and press Allow. Someone who added Tartini AI with an API key for scripts gets the same 401 when the key was revoked: they generate a new one on tartini.ai (Settings, Claude Code). Never ask anyone to paste a key or a token into the chat or a file. Stop here until it works.
3. Choose the project:
   - one project matches the repository: use its id as `projectId` in every project tool;
   - none matches: `list_projects_overview`; if none of those is this site, offer `create_project`, and create it only when the person agrees;
   - several match: ask the person which one.
4. Check what is connected with `get_project_state`. For a missing connection, call `connect_tracking` (GitHub) or `connect_bigquery` and pass on the tartini.ai link it returns: the person connects it there. Never guess a value the person did not give, such as a repository, a Measurement ID or a website address.
5. Query and write BigQuery with Google's BigQuery MCP, as the person: the plugin's `bigquery` server, or the one they added themselves. If its tools do not connect, or there is none, the person needs `gcloud auth login` and these roles on the Google Cloud project: MCP Tool User, BigQuery Job User and BigQuery Data Viewer. https://tartini.ai/docs/claude-code#bigquery-mcp says how to add it without the plugin, and the other way to sign in, with an OAuth client of their own.
6. Before any work in an area, read its guide with `read_guide({ domain })`. Where a guide and this skill differ, follow the guide.
