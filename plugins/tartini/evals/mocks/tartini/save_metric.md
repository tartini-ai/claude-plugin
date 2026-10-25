---
expect:
  projectId: prj_petal
  name: string
  sql: string
---
{"ok":true,"tool":"save_metric","requested":["save the metric \"{{input.name}}\""],"changed":["saved version 1 of \"{{input.name}}\", computed from now on"],"data":{"metric":{"id":"met_new","name":"{{input.name}}","version":1,"status":"active","computedVersion":1},"created":true,"changed":true,"activated":true,"check":{"verified":true,"dryRun":{"accepted":true,"bytesProcessed":18874368}},"next":"It is active: its last 90 days are computed by the next daily pass, then one day a day."}}
