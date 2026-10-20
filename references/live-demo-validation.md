# Live demo validation — 2026-10-19

Created a fresh seven-day scratch org using the bundled PersonAccounts/Fundraising definition, including industriesSettings.enableFundraising. Alias: nonprofit-readiness-demo. Org ID: [local scratch identifier withheld]. The org is intentionally retained for demonstrations; it expires automatically after seven days.

Setup verified Organization identity and active ScratchOrgInfo provenance through the authenticated Dev Hub. Seeded five synthetic Account cohorts and 34 Contacts. GiftTransaction describe confirmed the nonprofit object is queryable.

All five live Contact measurement checks matched their saved fixtures:

| Cohort | Contacts | Email present | Repeated email rows | Live data score | Coverage |
|---|---:|---:|---:|---:|---:|
| poor | 4 | 1 | 0 | 50.0% | 100.0% |
| improving | 10 | 8 | 1 | 50.0% | 100.0% |
| pilot | 10 | 10 | 0 | 100.0% | 100.0% |
| blocked | 10 | 10 | 0 | 100.0% | 100.0% |
| unknown | 0 | 0 | 0 | 0.0% | 0.0% |

All populated cohorts had their Contacts linked to their seeded Account. Email values were read transiently for the duplicate indicator; only aggregate results were saved in ignored .local/live-results.json. Cohort scopes intentionally exclude unrelated org records, including any orphan Contacts elsewhere.

Local offline scenario/replay/rounding/threshold tests passed. Three unit tests passed for wrong-org rejection, missing scratch provenance rejection, and failing unlinked relationships. Skill structure validation passed.

Live staff and technical controls remain unknown. Saved technical/staff comparison scores are explicitly simulated. No Agentforce runtime, NPSP, production org, or end-to-end agent behavioral validation was performed. The narrow assessment MCP is planned, not implemented.
