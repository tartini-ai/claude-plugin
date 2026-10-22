---
type: llm
---

PASS if the final reply names add_to_cart and newsletter_sign_up as the custom events the code sends, names Tartini Autocapture's auto_ events (at least auto_click), and names page_view as an event the Google tag collects by itself, keeping these kinds apart.
FAIL if the reply names a custom event that the code and the tool results do not have, leaves out add_to_cart or newsletter_sign_up, or presents page_view as a custom event the code sends.
