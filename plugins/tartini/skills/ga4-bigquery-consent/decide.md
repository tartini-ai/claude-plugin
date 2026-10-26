# Decide

Part of the ga4-bigquery-consent skill.

Recommend from this table, and say why. The person decides; if they choose otherwise, do what they chose
and say once what it risks.

| The site today | Visitors mostly in | Recommend | Say about the risk |
| --- | --- | --- | --- |
| No consent mechanism | anywhere | Keeping it as it is, collecting from everyone, is possible. Recommend at least the region-aware set-up below. | EEA, UK and Swiss visitors must be asked before analytics cookies are set. Several US states (California first) require an easy opt-out and honouring GPC when data is sold or shared. |
| Its own consent gate, asking everyone | the US or elsewhere outside Europe | Region-aware: ask first in the EEA, the UK and Switzerland, and wherever the region is unknown; everywhere else collect by default, with an opt-out link and GPC honoured. | US visitors are counted by default: the privacy policy must say so and the opt-out must be easy to find. |
| The same | Europe | Keep asking first. Add Consent Mode v2 signals (basic: nothing loads before a yes). | Visitors who decline stay invisible to GA4; a server or CDN log total (below) counts them. |
| A consent manager | anywhere | Use the manager's own region rules and its Consent Mode integration; register the tag with its API; never build a second banner. | The manager's settings live in its own dashboard, outside the code: tell the person where to change them. |
| Consent Mode already | anywhere | Check that the defaults run before the tag loads and that a choice sends an update. Basic or advanced is the person's choice. | Advanced sends cookieless requests before any choice, which several European authorities consider tracking that needs consent. GA4 models the missing visitors only past a threshold (at least 1,000 consent-denied events a day for 7 days, and at least 1,000 consenting users a day on 7 of the last 28 days, and even then not always), so a small site gets no modelled numbers from it. |
| Any of the above, with BigQuery | anywhere | Add a traffic total from server or CDN logs, aggregated (day, page, region, source, count) and without IP addresses, beside GA4. | Raw logs hold IP addresses: keep them short-lived, and say in the privacy policy what the server logs are for. |

Consent comes first for: the European Economic Area (the 27 EU countries, Iceland, Liechtenstein and
Norway), the United Kingdom, Switzerland, and any visitor whose region cannot be told. That is the area
Google's own EU user consent policy covers. A region lookup gives some places in the EU codes of their own,
and a list of countries alone collects from them by default: the EU's outermost regions Guadeloupe (GP),
French Guiana (GF), Martinique (MQ), Mayotte (YT), Réunion (RE) and Saint-Martin (MF), the Åland Islands
(AX, part of Finland), and, in the Unicode CLDR codes Google Cloud's load balancer gives, the Canary Islands
(IC) and Ceuta and Melilla (EA). The Azores and Madeira come as PT. Saint-Barthélemy (BL) left the EU in
2012, and Greenland (GL) and the Faroe Islands (FO) are outside it: they are not on the list.

One change to know: since 5 February 2026 UK law (the Data (Use and Access) Act 2025, in PECR) lets a site
use analytics without asking first when its only purpose is aggregate statistics to improve the site,
visitors are told clearly and can object simply and for free, and nothing goes to a third party except to
improve the service; advertising never qualifies. Whether a given GA4 set-up meets that is a judgement for
the person and their adviser, so keep the UK consent-first unless they decide it does.
