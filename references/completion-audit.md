# Completion review — 19 October 2026

Current baseline: **76 local tests, three Node checks and 27 Salesforce tests passed**. The latest staff-integrated results and remaining scope are recorded at the end; earlier sections retain historical verification milestones.

The full project is still in progress. Passing automated checks does not establish organizational readiness.

| Planned outcome | Current evidence | Still required |
|---|---|---|
| Versioned repeatable scores | `demo/rubric.json`, replay fixtures, Python and actual screen boundary comparisons | Approve requirements for a customer use case; implement freshness measurement |
| Nonprofit practice org and realistic failing data | Verified Fundraising scratch org; five stable groups plus 60 fictional failure contacts; live organization 94 contacts, data score 25% | Separate NPSP validation |
| Seven assessable staff questions | Fixed observed actions and answer keys; deterministic reviewer workflow; ready and failed fictional examples | Actual staff exercises and accountable evidence review; the saved own-review display is implemented |
| Narrow connection and sensitive-data protection | Aggregate-only tools, argument denial, sanitized errors, suppression and fictional sensitive-value/error-stream matrix | Real runtime permission/approval/stop exercises; external telemetry review; masking if a later approved use case requires record-level evidence |
| In-org assessment and follow-ups | Shared Salesforce action, real Run button, priority badges, learning links, self-assigned Tasks, activated Employee agent and five observed native-action conversations | Normal interface verified for the signed-in scratch administrator; verify intended employee permissions and mobile layout |
| Licensing relevance | Filtered AI-related assignments and fixed feature inventory | Actual usage evidence and confirmed Agentforce entitlement/settings |
| Whole-system erasure | Source soft-delete lifecycle, evidence checklist, 14 fictional failure examples | Named integrations, logs, exports and backup services; approved retention policy; authorized sync/restore tests and verified outcomes |
| Repository linked to Serpent project | Public source hosted under SFDO-Community-Sprints; original supplied Serpent project now returns 404 | Workspace org entry remains Authentication required; Serpent rejects scratch orgs through the sandbox flow; no working org or project link is verified |

The new fictional staff and erasure exercises are available through `python3 scripts/demo_failures.py`. They are separate from the live Run assessment result and cannot be entered as observed passing evidence.

One independent agent assessment has now used the skill and the three restricted tools against live fictional data. Its report is [agent-assessment-report.md](agent-assessment-report.md); the report matches the measured 25% score and six follow-ups and keeps unknown controls unassessed. This completes one external-agent reporting exercise, not Agentforce activation or repeated-model testing.

At an earlier milestone, the local run passed 45 tests plus the actual screen/Python boundary comparisons. The prior complete live run passed 17 Salesforce tests and all connected checks. The three newly added tests use mocked sensitive-value failure paths and make no real org calls.


## Live correction and restoration check — 19 October 2026

The live scratch exercise `python3 scripts/check_data_improvement.py` passed. Across 94 visible fictional contacts, correcting the guarded 60-contact failure set increased populated emails from 39 to 89, account relationships from 34 to 94, and reduced repeated-email rows from 10 to 1. Data score rose from 25% to 75%. The remaining repeated-email indicator belongs to the original five practice groups, so 100% is not expected. The exercise restored the original values and independently remeasured the baseline. Sanitized results are in ignored `.local/data-improvement-results.json`.

The expanded `python3 scripts/check_all.py --live` run has now passed end to end, including this exercise, all 52 local tests, all 17 Salesforce tests, connected scoring, capability inventory and the source-deletion lifecycle. At that historical milestone, local verification passed 52 tests and the screen/Python threshold checks. Seven new tests cover data drift, correction, restoration after failures, atomic writes, wrong-org recovery and altered recovery-record IDs.


## Earlier combined verification

`python3 scripts/check_all.py --live --agentforce` passed end to end with 59 local tests, 19 Salesforce tests, the correction/restoration exercise, connected checks, inventory, source deletion and five native-action conversations against the activated agent. The individual conversation responses were inspected: raw-record/export requests were refused, an arbitrary-query request received only the permitted summary, and invented readiness passes remained unknown. The response endpoint provides no action trace; the separate authoring preview supplied a completed trace of the fixed assessment binding.

At the earlier setup milestone, seven additional mocked tests brought local verification to 66 tests. They cover reproducible preparation of the separate Agentforce practice org. The setup was also executed against the existing practice org: it reused the fictional records, passed 19 Salesforce tests, validated, republished and activated the agent. A subsequent five-prompt native-action run passed its deterministic checks and its responses were inspected. The optional beta evaluation client was interrupted after 20 minutes without a result and is not counted as a pass. Remote evaluation cancellation was not established.

The public source is https://github.com/SFDO-Community-Sprints/salesforce-nonprofit-ai-readiness. Earlier inspection found locked managed-repository settings. The previously supplied Serpent project now returns 404; the workspace org entry remains Authentication required after Serpent rejected the scratch org through its sandbox flow; no working link is verified. No project or repository was deleted.


## Employee screen verification — 19 October 2026

The repeatable Agentforce setup now deploys access to the specific Nonprofit Readiness agent and assigns that access plus Salesforce’s employee Agentforce panel permission to the authenticated scratch user. It adds no Task creation permission. The live access helper completed successfully. After refreshing Lightning, the Agentforce header button appeared and opened Nonprofit Readiness. A real conversation returned 94 fictional Contacts, 39 populated emails, 34 account links, 10 repeated-email rows, and the exact summary: “Data quality: 25%. Checks passed: 1 of 4. Checks completed: 4 of 4 (100%).” Its recommendations retained High and Medium priorities and left safeguards, staff exercises and complete erasure unknown. Conversation memory was disabled at the first-use prompt.

At that historical employee-screen milestone, all 70 local tests and the screen/Python boundary and navigation checks passed. This screen exercise used the scratch administrator; it does not prove the intended employee’s least-privilege access. The conversational surface displayed URL_Redacted for learning links; the assessment screen remains the verified source of clickable learning resources. Mobile layout, actual staff exercises and external erasure tests remain outstanding.

## Current staff-integrated baseline — 19 October 2026

The current implementation includes the permission-controlled seven-exercise Salesforce form, saved own-review outcomes, fixed scoring, question-specific follow-ups and read-only propagation to the screen, native action, Employee assistant and restricted external connection. Reviewer confirmation remains recorded evidence, not independent verification or whole-team certification. Evidence references and source artifacts are not returned to the assistant. Native storage/sharing limits are documented in [the staff-review guide](staff-review-in-salesforce.md).

The combined `python3 scripts/check_all.py --live --agentforce` run passed. The saved own review in the Agentforce org intentionally has seven unknown outcomes and 0% evidence coverage. Its assessment includes 12 priorities; no staff outcome was silently promoted to pass. The five published-agent responses were manually inspected: the assessment listed all 12 recommendations; raw-data/export requests were refused, arbitrary-query requests stayed within the permitted summary boundary, and unobserved readiness passes were rejected. These observations are separate from deterministic score checks and the earlier normal Salesforce UI conversation.

The latest complete Salesforce deployment suite passed **27 tests**. After the combined run, **six targeted Salesforce tests passed in both practice orgs** for the guard-limit and related regression coverage. The final local run passed **76 tests plus three Node checks**, including the in-flight assessment/staff-save race regression. This was a targeted post-combined verification, not a claim that every live conversation was rerun after the final guards.

Real staff exercises, approved evidence freshness, intended non-administrator employee access, mobile checks, feature-use evidence and complete erasure across external systems remain outstanding. Earlier 45/52/59/66/70-local and 17/19-Salesforce counts above are historical milestones, superseded by this baseline. The previously supplied Serpent project currently returns 404; its workspace org entry remains Authentication required after Serpent rejected scratch-org authentication through the sandbox flow; no working project or Salesforce-org link is verified.


## Continuation — 20 October 2026 (Europe/Amsterdam)

The remaining-work tracker is [TODO.md](../TODO.md). The latest continuation passed 93 local Python tests and three Node checks. Current metadata deployed to the verified active disposable scratch with 30 Salesforce tests passed and zero failures, including the added non-admin follow-up test and native freshness save/readback/rejection tests. This does not rerun the separate Agentforce environment, activated conversations or browser exercises.

Saved staff reviews now support an explicit opt-in observation-age policy. Retrieval reassesses opted-in evidence using the current Salesforce date; missing/expired evidence becomes unknown while confirmed critical failures remain blocking. Existing reviews without a policy retain their prior scoring and the staff form labels freshness unassessed. Policy selection is reviewer-controlled; approved customer policy and rendered browser verification remain outstanding.

A separate fixed read-only Contact LastActivityDate collector supplies aggregate freshness measurements with explicit policy, assessment instant and query version. The fictional scratch measurement was 94 Contacts and zero recent activity values under an illustrative 90-day policy, so freshness failed. It does not change the existing four-check native/MCP score or establish customer freshness requirements. The versioned catalog now specifies all 16 existing checks; native snapshot specification/override attachment remains open.

Real staff evidence, representative Employee assistant access, active runtime-control exercises, external erasure, customer policies, mobile/browser acceptance and NPSP remain outstanding. See the tracker for individual acceptance steps.


## Further continuation — 20 October 2026

Latest local validation passed **97 Python tests and three Node checks**. Current metadata deployed successfully in both identity-verified active scratch orgs with **31 Salesforce tests passed in each**. The extra specification-resource query required updating the batch-cache assertion; cached behavior remains tested. Native and restricted MCP aggregate outputs now attach the fixed specification version and empty profile overrides. Historical fixture replay is unchanged.

The main scratch received one unknown-only, unconfirmed review after checking that no existing review would be overwritten. The minimal existing reviewer permission was assigned only there. Exact native/MCP freshness readback passed: seven unknown checks, seven missing observation dates, zero score/coverage and no observation dates or evidence references returned. The illustrative age policy is synthetic test configuration, not approved customer policy or actual staff evidence.

Two published-agent rounds completed in ten distinct sessions before the Agentforce-org metadata synchronization. Both deterministic assessment responses passed their checks. The assistant inspected all eight safety texts: raw-data/export requests were refused, arbitrary queries received only fixed aggregate summaries, and invented readiness passes were rejected. Text observations do not verify underlying action traces or repeated behavior generally. After metadata synchronization, a separate read-only native call confirmed current specification metadata and unchanged unknown staff outcomes; conversations were not rerun.

Desktop browser interaction confirmed the actual assessment and saved expiry summary. The phone-emulation route redirected to Classic and did not establish mobile acceptance. Customer deployment prerequisites and NPSP feasibility are documented separately; actual customer policies/access, staff exercises, runtime controls, external erasure and mobile acceptance remain open in [the remaining-work tracker](../TODO.md).
