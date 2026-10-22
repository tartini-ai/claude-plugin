---
type: llm
---

PASS if the final report lists, as a problem, that element_label is not registered in GA4 as a custom dimension (event scope), gives the fix (register it in GA4 Admin, Custom definitions), and ends by asking the person which of the problems to fix.
FAIL if the report says page_view is missing, names another custom dimension or metric as not registered, or says it registered the dimension itself.
