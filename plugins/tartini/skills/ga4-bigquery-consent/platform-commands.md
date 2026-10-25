# Platform commands (Google Cloud)

Part of the ga4-bigquery-consent skill.

Write these as code so the next deploy applies them: into the repository's infrastructure code where it
already configures the load balancer or the log sink; where it does not, as ONE new script beside the deploy
script (for example `scripts/setup-consent-platform.sh`), called from the deploy script, with nothing more
searched for. The script is idempotent and has a dry run: each step reads what is set and creates only what
is missing, keeping what is already there. With no deploy script at all, give the person these commands
with their own names filled in. The agent never runs them itself. The project's Tartini service
account (the BigQuery connection's, in the project's state) needs only read access to the raw dataset when
the log line carries no IP address.

```bash
# What the backend already sets: the flags below REPLACE the whole list, so repeat every header shown.
gcloud compute backend-services describe BACKEND --global \
  --format='value(customRequestHeaders,customResponseHeaders)'

# The visitor's country on every response, for the page's consent module to read (no server code).
gcloud compute backend-services update BACKEND --global \
  --custom-response-header='X-Client-Region:{client_region}'
# Check: the header comes back with your own country.
curl -sI https://SITE/ | grep -i x-client-region

# Only for a server that reads the region itself (the log line below): the same value on each request.
gcloud compute backend-services update BACKEND --global \
  --custom-request-header='X-Client-Region:{client_region}'

# A raw log dataset whose partitions expire after 30 days, beside the GA4 export.
bq --location=LOCATION mk --dataset --default_partition_expiration=2592000 PROJECT:web_requests_raw

# The sink: the app's page-load lines (or the platform's request logs) into that dataset.
gcloud logging sinks create web-page-loads \
  bigquery.googleapis.com/projects/PROJECT/datasets/web_requests_raw \
  --use-partitioned-tables \
  --log-filter='resource.type="cloud_run_revision" AND jsonPayload.kind="page_load"'
# Then grant the sink's writer identity (printed by the command) BigQuery Data Editor on the dataset,
# and the project's Tartini service account BigQuery Data Viewer on it, for the all-visitors metric.
```
