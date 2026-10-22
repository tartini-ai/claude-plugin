---
expect:
  projectId: prj_petal
  name: string
  sql: string
---
{"ok":true,"tool":"save_metric","changed":["saved {{input.name}} as version 1, waiting for review"],"data":{"metric":{"id":"met_new","name":"{{input.name}}","version":1,"status":"pending","origin":"claude_code"},"page":"https://tartini.ai/metric.html?project=prj_petal&id=met_new","note":"Pending until a person presses Confirm on its page on tartini.ai."}}
