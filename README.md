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
| `plugins/tartini/skills/` | Five skills (`setup`, `tracking`, `metrics`, `measurement-plan`, `ga4-bigquery-consent`): the same files Tartini AI's server gives Claude Code with `read_skill`, copied from the server's repository. Do not edit them here |
| `plugins/tartini/commands/` | `/tartini:plan`, `/tartini:track`, `/tartini:status`, `/tartini:doctor` |
| [`knowledge/`](knowledge/) | Every domain guide (as Tartini AI and as Claude Code read it) and every reference document Tartini AI works from, for reading. Generated from Tartini AI's server; not installed with the plugin, because Claude Code reads guides live from the server |
| `plugins/tartini/evals/` | Cases for `claude plugin eval`, with mocks of the three MCP servers |
| `server.json` | The Tartini AI MCP server's entry for the MCP Registry. Not published |
| `LICENSE`, `NOTICE` | Apache License 2.0, and the open source work this plugin follows |

## For maintainers

- **No guides in the plugin.** The guides, rules and references stay on Tartini AI's server (`get_started`, `read_guide`); `knowledge/` is a generated copy for reading, outside the plugin, and is never edited here. The skills are the server's own, byte for byte, so someone who adds only the server reads the same skills with `read_skill`. `skills/` is generated from the server's repository: a change to a skill is made there and copied here, never made here. A command says only the order of the calls.
- **Validate** both the marketplace and the plugin, since a marketplace run does not open a plugin's own files: `claude plugin validate --strict .` and `claude plugin validate --strict plugins/tartini`.
- **The repository name** `tartini-ai/claude-plugin` appears in this README, in `plugins/tartini/README.md` and in `plugins/tartini/.claude-plugin/plugin.json` (`repository`). The marketplace's plugin entry uses a relative path and needs no change if the repository is renamed.
- **The MCP Registry entry** (`server.json`) is checked against the registry's published schema. It is published with `mcp-publisher`, with `tartini.ai` proved by DNS or HTTP, only when the server is live.
- **Evals** call Claude Code's own model; see [plugins/tartini/evals/README.md](plugins/tartini/evals/README.md) for how to run them.
- Keep human-facing text free of em dashes.
