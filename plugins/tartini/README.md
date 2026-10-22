# Tartini AI for Claude Code

Tartini AI keeps a website's analytics in one project: its GA4 tracking definitions, its Measurement Plans, its metrics, and its connections to GitHub, Google Analytics and BigQuery. This plugin lets Claude Code use that project from your own repository. Claude writes the tracking code and opens the pull request as you; Tartini AI keeps the definitions and checks the change. Claude queries your BigQuery with Google's own BigQuery MCP, with your own Google permissions.

If you already use Tartini AI on tartini.ai, it is the same account and the same projects.

> The plugin is not published yet. The Tartini AI MCP server (`mcp.tartini.ai`) is not live yet either.

## Install

1. **Get an API key.** Sign in on [tartini.ai](https://tartini.ai), open [Settings, Claude Code](https://tartini.ai/settings.html#claude-code) and generate a key. It starts with `tartini_` and is shown once. New to Tartini AI? [Sign up here](https://tartini.ai/?ref=claude-code).
2. **Put the key in your shell profile** (for example `~/.zshrc` or `~/.bashrc`), then open a new terminal:

   ```bash
   export TARTINI_API_KEY="<your key>"
   ```

   - Use exactly the name `TARTINI_API_KEY`. In an MCP server's headers, Claude Code reads `ANTHROPIC_API_KEY` and its other credential names as empty, so a key stored under one of them never reaches Tartini AI.
   - Keep the key out of every file in a repository. Never add the server with `claude mcp add --scope project`: that writes the server into the repository's `.mcp.json` for everyone who clones it.
3. **Install the plugin:**

   ```bash
   claude plugin marketplace add tartini-ai/claude-plugin
   claude plugin install tartini@tartini-ai
   ```

   Or, inside a Claude Code session: `/plugin install tartini --marketplace tartini-ai/claude-plugin`.
4. **Sign in to Google** for BigQuery (next section), then start Claude Code in your repository and run `/mcp`. You should see `plugin:tartini:tartini` and `plugin:tartini:bigquery` connected.

If `plugin:tartini:tartini` does not connect, run `claude mcp list`: a warning about `TARTINI_API_KEY` means the variable is not set in the terminal that started Claude Code. Tartini AI answers a wrong or revoked key with a 401 that names the page where you generate a new one.

## BigQuery, through Google's BigQuery MCP

The plugin's `bigquery` server is Google's remote MCP server at `https://bigquery.googleapis.com/mcp`. It runs every query as you, with your own Google Cloud permissions, and bills the Google Cloud project you name. Tartini AI never sees these queries or your Google token.

Your Google account needs these roles on the Google Cloud project that holds the data:

- MCP Tool User (`roles/mcp.toolUser`)
- BigQuery Job User (`roles/bigquery.jobUser`)
- BigQuery Data Viewer (`roles/bigquery.dataViewer`)

The BigQuery MCP server is on as soon as the BigQuery API is enabled in that project.

### Sign in with gcloud (the default)

Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and run:

```bash
gcloud auth login
```

Each time Claude Code connects to the `bigquery` server, and again after Google answers 401 or 403, it runs the plugin's `scripts/gcloud-token`. That script runs `gcloud auth print-access-token` and hands Claude Code only one header, `Authorization: Bearer <token>`. `gcloud` must be on the `PATH` of the terminal that starts Claude Code. This path has not been tested against Google's server yet.

### Sign in without gcloud: an OAuth client of your own

Google's remote MCP servers support neither Dynamic Client Registration nor Client ID Metadata Documents, so Claude Code cannot sign in with the server's address alone. Use an OAuth client from your own Google Cloud project instead:

1. In the Google Cloud console, open **APIs & Services, OAuth consent screen** and set it up if the project has none (Internal when every user is in your Google Workspace; with External, add each user as a test user).
2. Open **APIs & Services, Credentials, Create credentials, OAuth client ID** and choose **Desktop app**. Copy the client ID (it ends in `.apps.googleusercontent.com`) and the client secret. A Desktop app client needs no redirect URI.
3. Add the server for yourself only, and type the secret when Claude Code asks for it:

   ```bash
   claude mcp add --transport http --scope user --client-secret \
     --client-id <your-client-id>.apps.googleusercontent.com \
     bigquery-oauth https://bigquery.googleapis.com/mcp
   ```

4. Run `/mcp`, select `bigquery-oauth` and sign in with Google in the browser. In the same list, turn off `plugin:tartini:bigquery`, so Claude uses only the server you added.

If Google's sign-in page says a scope is missing, add the server with its scope set instead:

```bash
claude mcp add-json --scope user bigquery-oauth \
  '{"type":"http","url":"https://bigquery.googleapis.com/mcp","oauth":{"clientId":"<your-client-id>.apps.googleusercontent.com","scopes":"https://www.googleapis.com/auth/bigquery"}}' \
  --client-secret
```

This path has not been tested against Google's server yet either.

### Keep BigQuery read only

Of the BigQuery MCP's tools, only `execute_sql` can change data. Claude shows you the complete statement before any write and never deletes or overwrites a source table. To make writes impossible for your account whatever is asked, add the IAM deny policy in Google's guide [Prevent read-write MCP tool use](https://docs.cloud.google.com/mcp/prevent-read-write-tool-use).

## Optional: Google's Google Analytics MCP

`/tartini:doctor` reads GA4 through Google's own [Google Analytics MCP](https://github.com/googleanalytics/google-analytics-mcp), which runs on your machine and only reads. Without it, the doctor marks its GA4 checks "not checked". To add it, give your Application Default Credentials the Analytics read-only scope, then add the server for yourself:

```bash
gcloud auth application-default login \
  --scopes https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/cloud-platform
claude mcp add analytics-mcp --scope user -- pipx run --spec analytics-mcp==0.8.0 analytics-mcp
```

It is not part of this plugin, and Tartini AI never sees what it reads.

## What you get

Skills, which Claude uses on its own when your request matches, even when you never say "Tartini":

| Skill | When Claude uses it |
| --- | --- |
| `setup` | Starting analytics work in a repository, checking what is connected, a key or permission problem |
| `tracking` | Adding, changing or listing GA4 events, Tartini Autocapture, the Google tag |
| `metrics` | Questions about your numbers, and defining, checking or saving a metric |
| `measurement-plan` | What to measure for a launch, a page, a checkout, a campaign or an experiment |
| `ga4-bigquery-consent` | Cookie banners, consent managers and Google Consent Mode. Its text is read from Tartini AI's server |

Commands you type:

| Command | What it does |
| --- | --- |
| `/tartini:plan [what to measure]` | Writes or revises a Measurement Plan |
| `/tartini:track [what to track]` | Adds or changes tracking |
| `/tartini:status` | Shows the project, its connections, the tracking on this branch, metrics and plans. Reads only |
| `/tartini:doctor [GA4 property id]` | Health-checks the Google tag, Autocapture, what GA4 received in the last 7 days, custom dimensions and the BigQuery export. Checks first and changes nothing, then asks which fixes to make |

Every task starts the same way: Claude calls `get_started` with your repository's git remote, reads the area's guide from Tartini AI with `read_guide`, and queries data with Google's BigQuery MCP. The guides and rules stay on Tartini AI's server, so this plugin carries no copy of them.

## If you already use Tartini AI on the web

Generate the key with the same Tartini AI account. Tartini AI finds your project from the repository's git remote, and the events, plans and metrics you made on the web are there. A tracking change made from Claude Code is shown on its run page as "Made in Claude Code", and a metric saved from Claude Code as "Saved from Claude Code", waiting for you to confirm it. Claude Code's conversations are not shown on tartini.ai. Calls from Claude Code run no Tartini AI model and use no Credits.

## Security and privacy: what the plugin connects to, sends, stores and reads

The plugin connects to exactly two remote services.

### 1. Tartini AI's MCP server, `https://mcp.tartini.ai/mcp` (Tartini AI LLC)

- **Sent with every request:** your API key, in the `Authorization` header.
- **Sent when Claude calls a tool:** the tool's arguments. These are your repository's git remote (owner/repo), your git branch name, project ids, tracking event definitions (names, parameters, when they fire), Measurement Plan text, metric names, definitions and SQL, and a pull request number. When Claude checks a tracking change, it also sends the base commit and the diff of your local change (`git diff`).
- **Stored by Tartini AI:** what you ask it to keep. That is the tracking event definitions, Measurement Plans and their versions, metrics and their versions (marked as saved from Claude Code), the pull request you link (its number, link and head commit) and the result of the last check (each finding's file, line and rule, its time and base commit). It does not keep the diff or any of your code. It also records when your key was last used, counts calls per key to limit their rate, and keeps an internal record of each call that changes something, so that a retried call does not change it twice.
- **Read by Tartini AI, on its side:** your GitHub repository at the commits Claude names, and the pull requests you link, through the Tartini AI GitHub App with a read-only token. When you connected BigQuery on tartini.ai, it also reads BigQuery metadata, checks a metric's SQL with a dry run and computes your metrics each day, as your project's own Tartini AI service account.
- No model runs on Tartini AI for these calls, and they use no Credits. Tartini AI sends your key nowhere, and the key is in no log.

### 2. Google's BigQuery MCP server, `https://bigquery.googleapis.com/mcp` (Google)

- **Sent:** a Google access token for your own Google account (from `gcloud`, or from your own OAuth client's sign-in), and the SQL, dataset and table names Claude asks for.
- **Stored:** nothing by the plugin. Google keeps its usual job history and audit logs under your Google Cloud terms.
- Queries run with your own permissions and are billed to the Google Cloud project you name. Tartini AI never sees this traffic or your token.

### On your machine

- `scripts/gcloud-token` runs only when Claude Code connects to the `bigquery` server. It runs `gcloud auth print-access-token` and prints the header to Claude Code. It writes nothing, caches nothing and sends nothing itself.
- The skills and commands are instructions for Claude. They ask Claude to run git commands (`git remote get-url origin`, `git branch --show-current`, and for tracking changes `git merge-base` and `git diff`) and, for tracking work, to edit files, run your project's tests and open a pull request with git and `gh`. Claude Code asks your permission as usual.
- The plugin stores nothing: no configuration file, no cache and no telemetry. Your key stays in your environment variable.
- The `evals/` folder holds test cases for `claude plugin eval`. A normal session never loads them.

## Support

Write to hello@tartini.ai. Privacy policy: [tartini.ai/privacy](https://tartini.ai/privacy). Terms: [tartini.ai/terms](https://tartini.ai/terms).

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for the open source work this plugin follows.
