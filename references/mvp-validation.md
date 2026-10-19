# MVP validation — 19 October 2026

## Completed automated checks

The complete automated command passed against the prepared nonprofit scratch org:

```sh
python3 scripts/check_all.py --live
```

- 18 Python unit tests: output restrictions, input denial, privacy suppression, sanitized errors, current-org scope, license relevance/unlimited seats, and scratch setup safeguards.
- Versioned five-scenario scoring assertions: expected scores, unknown/not-applicable/empty cases, rounding, threshold edges, Critical gates and ordered recommendations.
- Screen-function assertions: priority thresholds, action shortcut scrolling/focus, missing results and reduced-motion behavior. The navigation assertions were added and run after the final full command; no Salesforce data/score logic changed afterward.
- 17 Salesforce tests: data scores, organization scope/orphans, access denial, read-only-assessor inability to create Tasks, task ownership/reuse/priority refresh, severity mapping, relevant licenses, and the synthetic deletion lifecycle.
- Live MCP stdio: initialization, refusal of export/raw parameters, default small-group suppression, and all five practice measurements.
- Live Salesforce screen/action and restricted connection agreement for current-user organization records.
- Live filtered license/feature inventory. Assignments are not claimed to prove feature activity.
- Live fictional-contact insertion/soft-deletion: fresh assessments included then excluded the contact. The test confirmed it remains recoverable from the Recycle Bin. This is not an end-to-end erasure pass.

Aggregate reports live in ignored `.local/`, including full-check-results.json, mcp-demo-results.json, salesforce-action-results.json and erasure-demo-results.json. No credentials or donor values are included in those reports. Tests require authenticated Salesforce CLI, Python 3 and Node (already required by the CLI).

## Separate browser checks

Verified in native Edge/Chrome through computer-use tools, against the real deployed Salesforce screen:

- Full available container width and four readiness cards in one row at the wide desktop viewport; no fixed content-width cap.
- Actual Run assessment reads Salesforce and displays 34 accessible Contacts, five missing emails, one repeated-email entry and a 50% data score.
- Data findings, filtered AI-related license rows, unknown staff/safeguard/erasure state, learning links and owner-specific recommendations are visible.
- High badges are amber and Medium badges blue, with visible spacing before the recommendation title. Critical/red and Low/green styles exist; no unsupported Critical finding is shown in the live results.
- View recommended actions is disabled before results, then scrolls to the action list and focuses its heading.
- Explicit task creation made five self-owned follow-ups; a second click created none and reused five. Priority refresh updated those existing five Tasks. Readback confirmed two standard High and three Normal priorities, exact assessment severity in every description, and a learning link in every Task.

This is desktop verification, not a completed mobile-device test. Salesforce Lightning Debug Mode was enabled for the practice user to avoid stale component caching during verification; this is not a production configuration recommendation.

## Active and unverified work

End-to-end erasure across real integrations, logs, backups, restore behavior, exports and retention rules is now an active High-priority to-do. The practice-org [configuration inventory](erasure-system-inventory.md) is complete and [concrete end-to-end test cases](erasure-test-cases.md) are recorded. The actual integration/log/backup inventory, authorized test connections and approved retention scope are still needed; a source-only deletion does not complete it.

Agentforce assistant activation/conversation, staff demonstrations, full runtime access/approval/stop controls, NPSP, record-level masking, actual feature-use telemetry and production-scale validation remain separate. The Agentforce-compatible action is deployed; an assistant conversation is not claimed as tested.

Simultaneous sessions can still race to create duplicate follow-ups. Existing exact subject matches are treated as the same open follow-up; broad historical task migration is not performed. Assessment scores apply only to the fixed MVP Contact checks and intended scope, not a complete organizational or legal compliance score.


## Expanded failure demonstration verification — 19 October 2026

`python3 scripts/check_all.py --live` passed after the optional 60-contact failure seed: 42 local tests, 17 Salesforce tests, fixed-group comparisons, organization action/connection agreement, capability inventory, and the fictional source-deletion lifecycle. The organization contains 94 visible contacts, with 39 populated emails, 34 account relationships, and 10 repeated-email rows. Its data score is 25%, with three failed data checks. Staff and safeguards remain unassessed.

Additional executable screen/Python comparisons against `demo/rubric.json` passed at the priority, scoring, and privacy threshold boundaries. Simulated staff and whole-system erasure findings produce separate prioritized actions and do not change the live assessment's unassessed categories.


## Live correction and restoration check — 19 October 2026

The live scratch exercise `python3 scripts/check_data_improvement.py` passed. Across 94 visible fictional contacts, correcting the guarded 60-contact failure set increased populated emails from 39 to 89, account relationships from 34 to 94, and reduced repeated-email rows from 10 to 1. Data score rose from 25% to 75%. The remaining repeated-email indicator belongs to the original five practice groups, so 100% is not expected. The exercise restored the original values and independently remeasured the baseline. Sanitized results are in ignored `.local/data-improvement-results.json`.

The expanded `python3 scripts/check_all.py --live` run has now passed end to end, including this exercise, all 52 local tests, all 17 Salesforce tests, connected scoring, capability inventory and the source-deletion lifecycle. Latest local verification passes 52 tests and the screen/Python threshold checks. Seven new tests cover data drift, correction, restoration after failures, atomic writes, wrong-org recovery and altered recovery-record IDs.
