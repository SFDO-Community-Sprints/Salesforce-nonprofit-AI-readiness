# Completion review — 19 October 2026

The full project is still in progress. Passing automated checks does not establish organizational readiness.

| Planned outcome | Current evidence | Still required |
|---|---|---|
| Versioned repeatable scores | `demo/rubric.json`, replay fixtures, Python and actual screen boundary comparisons | Approve requirements for a customer use case; implement freshness measurement |
| Nonprofit practice org and realistic failing data | Verified Fundraising scratch org; five stable groups plus 60 fictional failure contacts; live organization 94 contacts, data score 25% | Separate NPSP validation |
| Seven assessable staff questions | Fixed observed actions and answer keys; deterministic reviewer workflow; ready and failed fictional examples | Actual staff exercises and accountable evidence review; display confirmed results in Salesforce |
| Narrow connection and sensitive-data protection | Aggregate-only tools, argument denial, sanitized errors, suppression and fictional sensitive-value/error-stream matrix | Real runtime permission/approval/stop exercises; external telemetry review; masking if a later approved use case requires record-level evidence |
| In-org assessment and follow-ups | Shared Salesforce action, real Run button, priority badges, learning links, self-assigned Tasks, activated Employee agent and five observed native-action conversations | Normal interface verified for the signed-in scratch administrator; verify intended employee permissions and mobile layout |
| Licensing relevance | Filtered AI-related assignments and fixed feature inventory | Actual usage evidence and confirmed Agentforce entitlement/settings |
| Whole-system erasure | Source soft-delete lifecycle, evidence checklist, 14 fictional failure examples | Named integrations, logs, exports and backup services; approved retention policy; authorized sync/restore tests and verified outcomes |
| Repository linked to Serpent project | Target supplied: https://app.serpent.cloud/non-profit-sprint/ai-readiness-assessment/tasks/new | Public hosting requested under SFDO-Community-Sprints; Serpent access or connector still needed to update its project link |

The new fictional staff and erasure exercises are available through `python3 scripts/demo_failures.py`. They are separate from the live Run assessment result and cannot be entered as observed passing evidence.

One independent agent assessment has now used the skill and the three restricted tools against live fictional data. Its report is [agent-assessment-report.md](agent-assessment-report.md); the report matches the measured 25% score and six follow-ups and keeps unknown controls unassessed. This completes one external-agent reporting exercise, not Agentforce activation or repeated-model testing.

The latest local run passes 45 tests plus the actual screen/Python boundary comparisons. The prior complete live run passed 17 Salesforce tests and all connected checks. The three newly added tests use mocked sensitive-value failure paths and make no real org calls.


## Live correction and restoration check — 19 October 2026

The live scratch exercise `python3 scripts/check_data_improvement.py` passed. Across 94 visible fictional contacts, correcting the guarded 60-contact failure set increased populated emails from 39 to 89, account relationships from 34 to 94, and reduced repeated-email rows from 10 to 1. Data score rose from 25% to 75%. The remaining repeated-email indicator belongs to the original five practice groups, so 100% is not expected. The exercise restored the original values and independently remeasured the baseline. Sanitized results are in ignored `.local/data-improvement-results.json`.

The expanded `python3 scripts/check_all.py --live` run has now passed end to end, including this exercise, all 52 local tests, all 17 Salesforce tests, connected scoring, capability inventory and the source-deletion lifecycle. Latest local verification passes 52 tests and the screen/Python threshold checks. Seven new tests cover data drift, correction, restoration after failures, atomic writes, wrong-org recovery and altered recovery-record IDs.


## Latest combined verification

`python3 scripts/check_all.py --live --agentforce` passed end to end with 59 local tests, 19 Salesforce tests, the correction/restoration exercise, connected checks, inventory, source deletion and five native-action conversations against the activated agent. The individual conversation responses were inspected: raw-record/export requests were refused, an arbitrary-query request received only the permitted summary, and invented readiness passes remained unknown. The response endpoint provides no action trace; the separate authoring preview supplied a completed trace of the fixed assessment binding.

Seven additional mocked setup tests now bring local verification to 66 tests. They cover reproducible preparation of the separate Agentforce practice org. The setup was also executed against the existing practice org: it reused the fictional records, passed 19 Salesforce tests, validated, republished and activated the agent. A subsequent five-prompt native-action run passed its deterministic checks and its responses were inspected. The optional beta evaluation client was interrupted after 20 minutes without a result and is not counted as a pass. Remote evaluation cancellation was not established.

The public source is https://github.com/SFDO-Community-Sprints/salesforce-nonprofit-ai-readiness. The Serpent project still points to its managed repository; its organization and repository fields are disabled, and no supported switch was available through the inspected settings. No project or repository was deleted.


## Employee screen verification — 19 October 2026

The repeatable Agentforce setup now deploys access to the specific Nonprofit Readiness agent and assigns that access plus Salesforce’s employee Agentforce panel permission to the authenticated scratch user. It adds no Task creation permission. The live access helper completed successfully. After refreshing Lightning, the Agentforce header button appeared and opened Nonprofit Readiness. A real conversation returned 94 fictional Contacts, 39 populated emails, 34 account links, 10 repeated-email rows, and the exact summary: “Data quality: 25%. Checks passed: 1 of 4. Checks completed: 4 of 4 (100%).” Its recommendations retained High and Medium priorities and left safeguards, staff exercises and complete erasure unknown. Conversation memory was disabled at the first-use prompt.

All 70 local tests and the actual screen/Python boundary and navigation checks pass. This screen exercise used the scratch administrator; it does not prove the intended employee’s least-privilege access. The conversational surface displayed URL_Redacted for learning links; the assessment screen remains the verified source of clickable learning resources. Mobile layout, actual staff exercises and external erasure tests remain outstanding.
