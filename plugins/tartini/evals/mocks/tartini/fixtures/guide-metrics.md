# Metrics guide (eval stand-in)

This short text stands in for Tartini AI's Metrics guide in this plugin's evals only. The real guide is on Tartini AI's server and is much longer.

- Answer from a defined metric first (list_metrics, get_metric_values) and say which one.
- When no defined metric answers the question, say "this is not a defined metric", write the SQL over the GA4 export and run it with Google's BigQuery MCP (execute_sql_readonly), as the person. Show the statement.
- The export: project petal-analytics, dataset analytics_412345678, daily tables events_YYYYMMDD. A parameter is read from event_params. Tartini Autocapture's clicks are auto_click events with element_label (the text of what was clicked) and page_path (the page, "/" for the home page).
- A metric's SQL is one read-only SELECT returning day DATE and value, reading its days through @start_suffix and @end_suffix (for example _TABLE_SUFFIX BETWEEN @start_suffix AND @end_suffix). A rate is in percentage points.
- To save a metric: try its SQL with Google's BigQuery MCP, call check_metric, then save_metric. A version whose check passes is computed at once, with nobody to confirm it: say what save_metric answered.
- With Tartini Autocapture installed, GA4's own reports need these registered in GA4 Admin, Custom definitions. Custom dimensions, event scope: element_tag, link_type, element_role, element_id, element_label, element_section, link_path, form_id, form_type, flush_reason. Custom metrics, event scope: field_count, engaged_time_seconds, max_scroll_depth. Not page_path.
