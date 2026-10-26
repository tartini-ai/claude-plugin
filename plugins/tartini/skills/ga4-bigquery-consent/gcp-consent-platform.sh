#!/bin/sh
# gcp-consent-platform.sh: the Google Cloud half of the ga4-bigquery-consent skill. Copy it into the repository
# byte for byte, beside the deploy script, and call it from there. Every value is a flag: nothing in this file is
# edited.
#
# Each run sets what is missing and keeps everything already there:
#   1. the response header X-Client-Region:{client_region} on the load balancer's backend service, for the
#      site's consent module, and with --request-header the same request header, for a server whose page-load
#      log line writes the region; the backend's other custom headers are kept;
#   2. a raw log dataset whose partitions expire after 30 days;
#   3. a Cloud Logging sink of the log filter's entries into that dataset, with partitioned tables;
#   4. BigQuery Data Editor on that dataset for the sink's writer identity, and BigQuery Data Viewer on it for
#      the reader service account: on the dataset only, never on the project.
# It reads everything before it writes anything, and stops on a conflict (the dataset in another location, the
# sink writing elsewhere) with nothing changed. Then it reads everything back.
#
# A dry run unless --apply is given: it reads what is set and prints each change --apply would make, as the
# command. With --apply a write that fails stops it with a non-zero exit, and so does a read back that does not
# show the change. It runs with any POSIX sh (dash, macOS's bash 3.2).
#
#   sh gcp-consent-platform.sh --project PROJECT --backend BACKEND_SERVICE --location LOCATION \
#     --dataset DATASET --sink SINK --log-filter 'FILTER' --reader SERVICE_ACCOUNT_EMAIL \
#     [--request-header] [--apply]
#
# It needs gcloud and bq, signed in as an account that may update the backend service, create a dataset and a
# log sink in the project, and grant roles on that dataset.
set -eu

NAME=gcp-consent-platform
REGION_HEADER='X-Client-Region:{client_region}'
EXPIRATION_MS=2592000000
NL='
'

usage() {
  cat <<'EOF'
usage: sh gcp-consent-platform.sh --project PROJECT --backend BACKEND_SERVICE --location LOCATION
         --dataset DATASET --sink SINK --log-filter FILTER --reader SERVICE_ACCOUNT_EMAIL
         [--request-header] [--apply]
A dry run unless --apply is given.
EOF
}
usage_error() { printf '%s: %s\n' "$NAME" "$1" >&2; usage >&2; exit 2; }
fail() { printf '%s: %s\n' "$NAME" "$1" >&2; exit 1; }
say() { printf '%s\n' "$1"; }

# --- The flags
APPLY=0
REQUEST_HEADER=0
PROJECT='' BACKEND='' LOCATION='' DATASET='' SINK='' LOG_FILTER='' READER=''
set_flag() {
  case $1 in
    --project) PROJECT=$2 ;;
    --backend) BACKEND=$2 ;;
    --location) LOCATION=$2 ;;
    --dataset) DATASET=$2 ;;
    --sink) SINK=$2 ;;
    --log-filter) LOG_FILTER=$2 ;;
    --reader) READER=$2 ;;
    *) usage_error "unknown flag: $1" ;;
  esac
}
while [ "$#" -gt 0 ]; do
  case $1 in
    --apply) APPLY=1 ;;
    --request-header) REQUEST_HEADER=1 ;;
    -h | --help) usage; exit 0 ;;
    --*=*) set_flag "${1%%=*}" "${1#*=}" ;;
    --project | --backend | --location | --dataset | --sink | --log-filter | --reader)
      if [ "$#" -lt 2 ]; then usage_error "$1 needs a value"; fi
      set_flag "$1" "$2"
      shift ;;
    *) usage_error "unknown argument: $1" ;;
  esac
  shift
done

# A flag's value, required and made only of the characters it may hold.
check() {
  if [ -z "$2" ]; then usage_error "$1 is required"; fi
  case $2 in *[!$3]*) usage_error "$1 has a character it cannot hold: $2" ;; esac
}
check --project "$PROJECT" '[:lower:][:digit:].:-'
check --backend "$BACKEND" '[:lower:][:digit:]-'
check --location "$LOCATION" '[:alnum:]-'
check --dataset "$DATASET" '[:alnum:]_'
check --sink "$SINK" '[:alnum:]_.-'
check --reader "$READER" '[:alnum:]@._-'
case $READER in *?@?*.gserviceaccount.com) ;; *) usage_error "--reader is a service account's email: $READER" ;; esac
if [ -z "$LOG_FILTER" ]; then usage_error "--log-filter is required"; fi

command -v gcloud >/dev/null 2>&1 || fail "gcloud is not installed"
command -v bq >/dev/null 2>&1 || fail "bq is not installed (it comes with the Google Cloud CLI)"

ERR_FILE=$(mktemp "${TMPDIR:-/tmp}/$NAME.XXXXXX") || fail "could not make a temporary file"
trap 'rm -f "$ERR_FILE"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- Reading, showing and writing
# A read: what it printed in OUT, what it printed on stderr in ERR, its exit status in RC. Never a write.
read_cmd() {
  RC=0
  OUT=$("$@" 2>"$ERR_FILE") || RC=$?
  ERR=$(cat "$ERR_FILE")
}
# One argument as a shell word a person can paste.
quote() {
  case $1 in
    '' | *[!A-Za-z0-9_./:=@,%+-]*) printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")" ;;
    *) printf '%s' "$1" ;;
  esac
}
show() {
  line=''
  for arg in "$@"; do line="$line${line:+ }$(quote "$arg")"; done
  printf '%s' "$line"
}
CHANGES=0
# A write: run with --apply, otherwise only shown.
write() {
  CHANGES=$((CHANGES + 1))
  if [ "$APPLY" = 1 ]; then
    say "   run: $(show "$@")"
    "$@" || { status=$?; fail "this write failed (exit $status): $(show "$@")"; }
  else
    say "   would run: $(show "$@")"
  fi
}

# --- What is there
# The backend's custom headers of one kind (customResponseHeaders or customRequestHeaders), one a line in
# HEADERS: with --flatten gcloud prints each on its own line, whatever it holds (a ';' or ',' included), and
# a single empty line when the backend has none.
headers_of() {
  read_cmd gcloud compute backend-services describe "$BACKEND" --global --project="$PROJECT" \
    --flatten="$1" --format="value($1)"
  if [ "$RC" != 0 ]; then fail "could not read the backend service $BACKEND: $ERR"; fi
  HEADERS=$OUT
}
# What a list says about the region header, in REGION (set, other or missing), and the list it becomes in NEXT:
# every other header kept, in its order, then REGION_HEADER; KEPT counts them. gcloud's update REPLACES a list,
# so every header is passed back.
plan_region() {
  NEXT='' REGION=missing KEPT=0 ours=0 others=0
  while IFS= read -r header; do
    if [ -z "$header" ]; then continue; fi
    hname=$(printf '%s' "${header%%:*}" | tr '[:upper:]' '[:lower:]')
    if [ "$hname" = x-client-region ]; then
      hvalue=$(printf '%s' "${header#*:}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [ "$hvalue" = '{client_region}' ]; then ours=$((ours + 1)); else others=$((others + 1)); fi
    else
      NEXT=$NEXT$header$NL
      KEPT=$((KEPT + 1))
    fi
  done <<EOF
$1
EOF
  if [ "$ours" = 1 ] && [ "$others" = 0 ]; then REGION=set
  elif [ "$ours" != 0 ] || [ "$others" != 0 ]; then REGION=other
  fi
  NEXT=$NEXT$REGION_HEADER
}
# DATASET_JSON is the dataset as bq shows it, without white space, or empty when it does not exist. A missing
# dataset is bq's exit 2 with "Not found: Dataset" on stdout, wrapped over lines; any other failure is an error.
read_dataset() {
  read_cmd bq --project_id="$PROJECT" show --format=json "$PROJECT:$DATASET"
  if [ "$RC" = 0 ]; then DATASET_JSON=$(printf '%s' "$OUT" | tr -d ' \t\r\n'); return 0; fi
  if printf '%s %s' "$OUT" "$ERR" | tr '\n' ' ' | grep -q 'Not found: Dataset'; then DATASET_JSON=''; return 0; fi
  fail "could not read the dataset $PROJECT:$DATASET: $OUT $ERR"
}
# One top-level string or number of the dataset, unquoted ('' when absent).
dataset_field() {
  printf '%s' "$DATASET_JSON" | sed -n "s/.*\"$1\":\"\{0,1\}\([^\",}]*\)\"\{0,1\}[,}].*/\1/p"
}
# Whether the dataset's access list gives role $1 (its BigQuery name; $2 is the same role's IAM name) to the
# email $3: an entry is the text between braces, so the order of the keys inside it does not matter.
holds_role() {
  printf '%s' "$DATASET_JSON" | tr '{}' '\n\n' | grep -F -e "\"role\":\"$1\"" -e "\"role\":\"$2\"" \
    | grep -q -F -e "\"$3\"" -e ":$3\""
}
upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
DESTINATION="bigquery.googleapis.com/projects/$PROJECT/datasets/$DATASET"
# One field of the sink in SINK_FIELD, with SINK_FOUND=1, or SINK_FOUND=0 when there is no such sink: gcloud's
# exit 1 with NOT_FOUND on stderr. Any other failure is an error.
sink_field() {
  read_cmd gcloud logging sinks describe "$SINK" --project="$PROJECT" --format="value($1)"
  if [ "$RC" = 0 ]; then SINK_FOUND=1; SINK_FIELD=$OUT; return 0; fi
  case $ERR in *NOT_FOUND*) SINK_FOUND=0; SINK_FIELD=''; return 0 ;; esac
  fail "could not read the sink $SINK: $ERR"
}
# The sink's writer identity in WRITER, a member a role can be granted to (kind:email).
read_writer() {
  sink_field writerIdentity
  WRITER=$SINK_FIELD
  case $WRITER in *:?*@?*) ;; *) fail "the sink $SINK has no writer identity to grant a role to: '$WRITER'" ;; esac
}

# --- The changes
# The update of one list: $1 its flag, $2 the whole new list, one header a line.
update_headers() {
  flag=$1 list=$2
  set -- gcloud compute backend-services update "$BACKEND" --global --project="$PROJECT"
  while IFS= read -r header; do
    if [ -n "$header" ]; then set -- "$@" "$flag=$header"; fi
  done <<EOF
$list
EOF
  write "$@"
}
# $1 the state (set, other, missing), $2 the new list, $3 the headers kept, $4 the flag, $5 what it is called here.
region_header() {
  case $1 in
    set) say "$5: already set."; return 0 ;;
    missing) say "$5: missing; it is added and the backend's $3 other header(s) are kept." ;;
    other) say "$5: X-Client-Region is set to another value; it becomes $REGION_HEADER and the $3 other header(s) are kept." ;;
  esac
  update_headers "$4" "$2"
}
# BigQuery's own dataset-level grant (DCL), so the role is on this dataset alone.
grant_sql() { printf 'GRANT `%s` ON SCHEMA `%s.%s` TO "%s"' "$1" "$PROJECT" "$DATASET" "$2"; }
grant() { write bq --project_id="$PROJECT" --location="$LOCATION" query --use_legacy_sql=false "$(grant_sql "$1" "$2")"; }
# $1 the role's BigQuery name, $2 its IAM name, $3 the member (kind:email), $4 what it is called here.
dataset_role() {
  if [ -n "$DATASET_JSON" ] && holds_role "$1" "$2" "${3#*:}"; then say "$4: already granted."; return 0; fi
  say "$4: missing; granted on the dataset only."
  grant "$2" "$3"
}

# --- The run: everything is read, and a conflict refused, before the first write.
if [ "$APPLY" = 1 ]; then say "$NAME: applying."; else say "$NAME: a dry run; nothing is changed (--apply makes the changes below)."; fi
say "   project $PROJECT, backend service $BACKEND, raw log dataset $PROJECT:$DATASET in $LOCATION, sink $SINK"

headers_of customResponseHeaders
plan_region "$HEADERS"
RESPONSE_STATE=$REGION RESPONSE_NEXT=$NEXT RESPONSE_KEPT=$KEPT
if [ "$REQUEST_HEADER" = 1 ]; then
  headers_of customRequestHeaders
  plan_region "$HEADERS"
  REQUEST_STATE=$REGION REQUEST_NEXT=$NEXT REQUEST_KEPT=$KEPT
fi
read_dataset
if [ -n "$DATASET_JSON" ]; then
  FOUND_LOCATION=$(dataset_field location)
  if [ -z "$FOUND_LOCATION" ]; then fail "could not read the location of the dataset $PROJECT:$DATASET"; fi
  if [ "$(upper "$FOUND_LOCATION")" != "$(upper "$LOCATION")" ]; then
    fail "the dataset $PROJECT:$DATASET is in $FOUND_LOCATION, not $LOCATION: give --location its location, or another --dataset"
  fi
fi
sink_field destination
if [ "$SINK_FOUND" = 1 ]; then
  if [ "$SINK_FIELD" != "$DESTINATION" ]; then fail "the sink $SINK writes to $SINK_FIELD, not $DESTINATION: give another --sink"; fi
  sink_field filter
  SINK_FILTER=$SINK_FIELD
  read_writer
fi

region_header "$RESPONSE_STATE" "$RESPONSE_NEXT" "$RESPONSE_KEPT" --custom-response-header \
  "1. The response header $REGION_HEADER"
if [ "$REQUEST_HEADER" = 1 ]; then
  region_header "$REQUEST_STATE" "$REQUEST_NEXT" "$REQUEST_KEPT" --custom-request-header \
    "2. The request header $REGION_HEADER"
else
  say "2. The request header: not asked for (--request-header adds it, for a server whose log line writes the region)."
fi

if [ -n "$DATASET_JSON" ]; then
  say "3. The dataset $PROJECT:$DATASET: already there, in $FOUND_LOCATION."
else
  say "3. The dataset $PROJECT:$DATASET: missing; created in $LOCATION, its partitions expiring after 30 days."
  write bq --project_id="$PROJECT" --location="$LOCATION" mk --dataset \
    --default_partition_expiration=$((EXPIRATION_MS / 1000)) \
    --description='Raw page-load log entries; each partition expires after 30 days.' "$PROJECT:$DATASET"
  if [ "$APPLY" = 1 ]; then read_dataset; fi
fi

if [ "$SINK_FOUND" = 1 ]; then
  say "4. The sink $SINK: already there, into $DESTINATION."
  if [ "$SINK_FILTER" != "$LOG_FILTER" ]; then say "   note: its filter is not --log-filter, and it is kept as it is: $SINK_FILTER"; fi
else
  say "4. The sink $SINK: missing; created into $DESTINATION, with partitioned tables."
  write gcloud logging sinks create "$SINK" "$DESTINATION" --project="$PROJECT" --use-partitioned-tables \
    --log-filter="$LOG_FILTER"
  if [ "$APPLY" = 1 ]; then
    sink_field destination
    if [ "$SINK_FOUND" != 1 ]; then fail "the sink $SINK was created but cannot be read back; run this again"; fi
    read_writer
  fi
fi

if [ "$SINK_FOUND" = 1 ]; then
  dataset_role WRITER roles/bigquery.dataEditor "$WRITER" "5. BigQuery Data Editor on the dataset for the sink's writer $WRITER"
else
  say "5. BigQuery Data Editor on the dataset for the sink's writer identity: known once the sink exists; --apply grants it then."
  CHANGES=$((CHANGES + 1))
  say "   would run: $(show bq --project_id="$PROJECT" --location="$LOCATION" query --use_legacy_sql=false \
    "$(grant_sql roles/bigquery.dataEditor 'WRITER_IDENTITY_OF_THE_SINK')")"
fi

dataset_role READER roles/bigquery.dataViewer "serviceAccount:$READER" "6. BigQuery Data Viewer on the dataset for the reader $READER"

if [ "$APPLY" != 1 ]; then
  say "Dry run: $CHANGES change(s) to make, and nothing changed. The same command with --apply makes them."
  exit 0
fi

# --- Read back
say "7. Read back:"
headers_of customResponseHeaders
plan_region "$HEADERS"
if [ "$REGION" != set ]; then fail "read back: the backend's response headers do not hold $REGION_HEADER"; fi
say "   response header $REGION_HEADER: set"
if [ "$REQUEST_HEADER" = 1 ]; then
  headers_of customRequestHeaders
  plan_region "$HEADERS"
  if [ "$REGION" != set ]; then fail "read back: the backend's request headers do not hold $REGION_HEADER"; fi
  say "   request header $REGION_HEADER: set"
fi
read_dataset
if [ -z "$DATASET_JSON" ]; then fail "read back: the dataset $PROJECT:$DATASET is not there"; fi
EXPIRATION=$(dataset_field defaultPartitionExpirationMs)
if [ -n "$EXPIRATION" ]; then
  say "   dataset $PROJECT:$DATASET in $(dataset_field location), its partitions expiring after $((EXPIRATION / 86400000)) day(s)"
else
  say "   dataset $PROJECT:$DATASET in $(dataset_field location); note: its partitions never expire, and raw logs can hold IP addresses"
fi
sink_field destination
if [ "$SINK_FOUND" != 1 ] || [ "$SINK_FIELD" != "$DESTINATION" ]; then fail "read back: the sink $SINK does not write to $DESTINATION"; fi
sink_field bigqueryOptions.usePartitionedTables
say "   sink $SINK into $DESTINATION, partitioned tables: ${SINK_FIELD:-False}"
read_writer
if ! holds_role WRITER roles/bigquery.dataEditor "${WRITER#*:}"; then fail "read back: the sink's writer $WRITER does not hold BigQuery Data Editor on the dataset"; fi
say "   BigQuery Data Editor on the dataset: $WRITER"
if ! holds_role READER roles/bigquery.dataViewer "$READER"; then fail "read back: $READER does not hold BigQuery Data Viewer on the dataset"; fi
say "   BigQuery Data Viewer on the dataset: serviceAccount:$READER"
say "Done: $CHANGES change(s) made, and everything read back as set."
