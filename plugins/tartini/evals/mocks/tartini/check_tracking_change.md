---
expect:
  projectId: prj_petal
  branch: string
  baseSha: /^[0-9a-f]{40}$/
  patch: string
---
{"ok":true,"tool":"check_tracking_change","data":{"passed":true,"findings":[],"checked":"the patch applied exactly to the base commit, and each event it sends checked against its definition","tests":"This repository has no test script."}}
