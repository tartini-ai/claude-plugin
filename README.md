# Tartini AI plugin marketplace for Claude Code

This repository is the Claude Code marketplace `tartini-ai`. It holds one plugin, `tartini`, which connects Claude Code to Tartini AI (GA4 tracking definitions, Measurement Plans and metrics) and to Google's BigQuery MCP. What the plugin does, how to install it, and exactly what it sends, stores and reads are in [plugins/tartini/README.md](plugins/tartini/README.md).

```bash
claude plugin marketplace add tartini-ai/claude-plugin
claude plugin install tartini@tartini-ai
```

## What is here

| Path | What it is |
| --- | --- |
| `.claude-plugin/marketplace.json` | The marketplace: its name, its owner and the one plugin entry |
| `plugins/tartini/.claude-plugin/plugin.json` | The plugin's manifest |
| `plugins/tartini/.mcp.json` | The two remote MCP servers: `tartini` and `bigquery` |
| `plugins/tartini/scripts/gcloud-token` | The `bigquery` server's headersHelper: the Authorization header from `gcloud auth print-access-token` |
| `plugins/tartini/skills/` | Four thin skills (`setup`, `tracking`, `metrics`, `measurement-plan`) and the `ga4-bigquery-consent` stub, which reads its text from Tartini AI's server |
| `plugins/tartini/commands/` | `/tartini:plan`, `/tartini:track`, `/tartini:status`, `/tartini:doctor` |
| `plugins/tartini/evals/` | Cases for `claude plugin eval`, with mocks of the three MCP servers |
| `server.json` | The Tartini AI MCP server's entry for the MCP Registry. Not published |
| `LICENSE`, `NOTICE` | Apache License 2.0, and the open source work this plugin follows |

## For maintainers

- **No knowledge in the plugin.** The guides, rules and references stay on Tartini AI's server (`get_started`, `read_guide`, `read_skill`). A skill or command here says only the order of the calls. The description of `skills/ga4-bigquery-consent` copies the description of the server's skill of the same name; change both together.
- **Validate** both the marketplace and the plugin, since a marketplace run does not open a plugin's own files: `claude plugin validate --strict .` and `claude plugin validate --strict plugins/tartini`.
- **The repository name** `tartini-ai/claude-plugin` appears in this README, in `plugins/tartini/README.md` and in `plugins/tartini/.claude-plugin/plugin.json` (`repository`). The marketplace's plugin entry uses a relative path and needs no change if the repository is renamed.
- **The MCP Registry entry** (`server.json`) is checked against the registry's published schema. It is published with `mcp-publisher`, with `tartini.ai` proved by DNS or HTTP, only when the server is live.
- **Evals** call Claude Code's own model; see [plugins/tartini/evals/README.md](plugins/tartini/evals/README.md) for how to run them.
- Keep human-facing text free of em dashes.
