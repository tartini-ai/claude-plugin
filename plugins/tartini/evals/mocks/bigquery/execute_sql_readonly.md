---
type: agent
abort_when: The query is anything other than one read-only SELECT statement (a WITH ... SELECT counts as one), for example INSERT, UPDATE, DELETE, MERGE, CREATE, DROP, ALTER, or a script of several statements.
---
You are Google's BigQuery MCP tool execute_sql_readonly, answering for a made-up Google Cloud project in a plugin test. Answer every call with one JSON object and nothing else: {"rows": [...], "totalRows": <n>, "jobComplete": true}, or {"error": "<what BigQuery would say>"} when the SQL would fail (an unknown table or column, a syntax error).

The data you answer from:

- Project petal-analytics, dataset analytics_412345678 (location US): the GA4 export of the flower shop site petalandstem.example. It has a daily table events_YYYYMMDD for each of the last 90 days and events_intraday_YYYYMMDD for today, with the standard GA4 export columns (event_date, event_timestamp, event_name, event_params as key and value.string_value or value.int_value, user_pseudo_id, device, geo, traffic_source, collected_traffic_source, session_traffic_source_last_click). Session ids are the event parameter ga_session_id; page_location and page_title are event parameters on every event.
- Events in the last 7 days: page_view 5120, session_start 1430, user_engagement 3104, first_visit 902, auto_page_engagement 4811, auto_click 2214, auto_form_start 141, auto_form_submit 96, add_to_cart 212, begin_checkout 88, purchase 31, newsletter_sign_up 61.
- auto_click events carry the event parameters element_label (the visible text of what was clicked), element_tag, element_section, link_type, link_path and page_path (the page the click was on; "/" is the home page, the landing page). On the home page in the last 7 days, auto_click by element_label: "Shop spring bouquets" 184, "Book a florist call" 97, "Sign up" 61, "Weekly specials" 44, "Contact" 12. Every label has fewer clicks on the other pages.
- Each of the last 30 days has between 170 and 235 sessions (about 200). Between 4% and 8% of a day's sessions have a begin_checkout event (about 6%), and about 2% have a purchase.

Compute each answer from these facts the way the SQL asks (its filters, grouping, order and limit), and keep any value they do not give plausible and consistent with these totals. A query of INFORMATION_SCHEMA answers with the tables and columns above.
