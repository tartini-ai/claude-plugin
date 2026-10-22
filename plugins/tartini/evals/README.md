# Eval cases for `claude plugin eval`

Seven cases check that the plugin leads Claude to the right flow. Each one calls Claude Code's own model, so they cost plan usage or API spend. They are run on purpose, never as part of validation.

| Case | Prompt | What it checks |
| --- | --- | --- |
| `add-tracking` | Add tracking so we know when someone clicks the Sign up button on the home page. | the `tracking` skill fires; `get_started` before `read_guide`; the Tracking guide is read; the event is defined on the work branch after the guide |
| `save-conversion-metric` | Save a conversion-rate metric for this project: the share of sessions that start checkout. | the `metrics` skill fires; `get_started` first; the SQL is tried with Google's BigQuery MCP; `check_metric` before `save_metric`; the reply says it waits for review |
| `events-in-project` | Which events does this project have? | the `tracking` skill fires; `get_started` before `get_tracking_state`; the answer keeps code events, Autocapture and automatic events apart |
| `landing-button-clicks` | Which landing-page button was clicked most this week? | the `metrics` skill fires; `get_started` first; `list_metrics` before the query; the number comes from Google's BigQuery MCP |
| `ga4-health-check` | Health-check my GA4 setup. | `/tartini:doctor` fires on its own; it reads GA4 and the BigQuery export, finds nothing wrong on healthy answers and changes nothing |
| `doctor-no-page-view` | `/tartini:doctor` | on a GA4 answer with no `page_view`, it reports that problem, its fix, and asks which fixes to make |
| `doctor-dimension-not-registered` | `/tartini:doctor` | on a property where `element_label` is not registered, it reports that problem, its fix, and asks which fixes to make |

## Run them

From this plugin's folder:

```bash
claude plugin eval . --scaffold --allow-tools "Bash(git *)" Write Edit
```

- `--scaffold` runs each case's `scaffold.sh`, which builds a small flower shop site in the run's empty workspace: a git repository with the remote `flower-shop-demo/storefront`, on the branch `signup-tracking`. Every case has an identical copy, because a case's script must be in its own directory.
- `--allow-tools "Bash(git *)"` lets Claude read the git remote and branch. `Write` and `Edit` let it write the tracking code in `add-tracking`. Bash runs under Claude Code's OS sandbox, so a Linux runner needs `bubblewrap` and `socat`.
- Add `--threshold 0.8` or another pass mark, `--model` and `--judge-model` to pin the models, and `--max-cost-usd` for a ceiling.

## What answers the tools

No real server starts. Every tool call is answered from `mocks/`:

- `mocks/tartini/`: Tartini AI's tools, for one made-up project (`prj_petal`, Petal and Stem). `read_guide` and `read_skill` answer with short stand-ins in `mocks/tartini/fixtures/`, never the real guides, which stay on Tartini AI's server. Several mocks check their input with `expect:` (for example `get_started` must be given this repository's remote, and project tools must name `prj_petal`), and a call that does not match ends the run with score 0.
- `mocks/bigquery/`: Google's BigQuery MCP. `execute_sql_readonly` is an agent mock that answers from a fixed made-up warehouse and ends the run if a query is not one read-only SELECT. There is no `execute_sql` mock, so the writing tool is not offered at all.
- `mocks/analytics-mcp/`: Google's Google Analytics MCP, which the person adds to Claude Code themselves; it is not part of this plugin. The two doctor cases override one file each in their own `mocks/`.

Before a run, check the dates in `mocks/bigquery/list_table_ids.md` and `mocks/tartini/list_metrics.md`: the doctor compares the export's newest daily table with today, so tables from weeks ago read as an export that stopped.
