---
expect:
  projectId: prj_petal
  branch: string
  events: array
---
{"ok":true,"tool":"create_tracking_event","changed":["confirmed the events you sent on branch {{input.branch}}"],"data":{"branch":"{{input.branch}}","status":"confirmed","implementation":"in your pull request","next":"Write the code for these definitions in your local repository, run the project's whole test script, call check_tracking_change, open or push the pull request, then call link_pull_request."}}
