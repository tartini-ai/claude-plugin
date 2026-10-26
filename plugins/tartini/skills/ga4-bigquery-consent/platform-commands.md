# The platform settings

Part of the ga4-bigquery-consent skill.

## Google Cloud: the reviewed script

gcp-consent-platform.sh, beside this file, is the whole Google Cloud half (the region header, the raw log
dataset, the sink and the two dataset-level grants): idempotent, a dry run unless given `--apply`, stopping on
any write that fails, and tested against gcloud's and bq's real outputs. Copy it beside the deploy script (at
the repository's root when there is none), never retype it:

    cp <this skill's base directory>/gcp-consent-platform.sh scripts/gcp-consent-platform.sh

The base directory is the one your skill tool named when it loaded this skill. Where you read the skill with
read_skill instead, write the text read_skill gives for this file unchanged, and check that `shasum -a 256` of
the copy prints the sha256 it gave. Never change a line of the copy: every value is a flag.

**The one call**, in the deploy script after the site is deployed, each flag a fact you read:

    sh scripts/gcp-consent-platform.sh --apply --project PROJECT --backend BACKEND_SERVICE \
      --location LOCATION --dataset web_requests_raw --sink web-page-loads \
      --log-filter 'resource.type="cloud_run_revision" AND jsonPayload.kind="page_load"' \
      --reader SERVICE_ACCOUNT_EMAIL --request-header

- `--project`: the project the deploy script deploys to (its own variable for it).
- `--backend`: the global backend service the load balancer sends the site to, by its name in the repository.
- `--location`: where the GA4 export dataset is (get_project_state), so the two can be joined.
- `--reader`: the service account of the project's BigQuery connection (get_project_state).
- `--log-filter`: your log line's entries, on the resource type the site runs as (Cloud Run above).
- `--request-header`: when your log line writes the region. `--dataset`, `--sink`: names not in use yet.

The person runs the same line without `--apply` first: the dry run prints each change as its command.

## Other hosts, or no deploy script

There is no script: give the person the settings in your reply, as steps or commands with their own names.
The region header: Cloudflare, Vercel and CloudFront add one from their own country value with an edge rule
or function (write-the-change.md). The logs: bigquery.md. On Google Cloud with no deploy script, copy the
script all the same and give its call, the dry run first.
