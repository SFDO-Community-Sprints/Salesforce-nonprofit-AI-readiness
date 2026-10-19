# Salesforce nonprofit AI readiness — project plan

## Outcome

Deliver an agent skill that assesses a Salesforce nonprofit org and its staff for a defined AI use case, produces repeatable measurements and scores, and identifies what must change before a bounded pilot. MVP: Nonprofit Cloud Fundraising synthetic scratch demonstration. NPSP is a separate future assessment profile. Default initial use case: staff-only donor summaries with human review.

The actionable remaining scope is tracked in [TODO.md](TODO.md). Offline freshness preparation and additional validation are recorded there separately from live acceptance.

## Current baseline

Start with [START-HERE.md](START-HERE.md) for the admin walkthrough. This project contains the skill, seven staff questions, five fictional sample groups, repeatable scoring, a restricted agent connection, an in-org results screen, and an Agentforce-compatible assessment action.

The retained practice org was freshly created and seeded on 19 October 2026. Local privacy/scoring checks and live data comparisons passed; Salesforce action deployment and all 27 current Salesforce tests passed, including restricted-user and read-only-assessor write-denial tests. The results screen was exercised in Salesforce for 100%, 50%, and privacy-withheld outcomes. Final verification details are in references/mvp-validation.md.

The separate Agentforce-enabled practice org has a published and activated Employee agent with observed native-action conversations and a normal Salesforce header-panel conversation by the signed-in scratch administrator. Commit `b82d1fb` was the earlier 70-local/19-Salesforce milestone. The current staff-integrated baseline passes 76 local tests, three Node checks and 27 Salesforce tests, with browser and conversational observations recorded separately. Real staff capability, intended non-administrator employee access, full customer-org assessment and NPSP remain outside the verified demonstration.

## Current to-do: end-to-end erasure verification — High priority

This is active work, not a deferred roadmap item. The existing Contact soft-deletion exercise is only its first component.

- Inventory every in-scope destination for personal data: Salesforce records/files, exports, integrations, agent/prompt logs, application/audit logs, and backup services. Record an owner and evidence source for each; missing access remains unknown.
- Define the synthetic subject and linked records, request verification, applicable retention schedule, and any documented retention/legal-hold exceptions with the privacy owner. Never infer that every copy may be deleted.
- Run an authorized synthetic request through each destination, verifying permitted erasure or restriction, the absence of personal values in subsequent agent outputs, and no reintroduction through scheduled syncs or replay.
- Verify log handling without destroying required audit evidence; retain only the request evidence approved by the retention policy.
- Test backup expiry/erasure behavior and an isolated restore: previously erased information must not become available again without the approved suppression/redeletion process. Do not test restore against production.
- Record evidence per system and a combined result. A source-only delete, simulated downstream adapter, missing system, or untested restore cannot earn an end-to-end pass.

Evidence and concrete procedures are tracked in [the system inventory](references/erasure-system-inventory.md) and [end-to-end test cases](references/erasure-test-cases.md). Completion requires named integration/log/backup systems, authorized test access and a privacy-approved retention policy. Those system details and external evidence are not currently available in this project. Preserve **Privacy and erasure: Not assessed** until the required scope is verified. This item does not authorize deleting real subject data or altering production retention policies.

## 1. Define the versioned assessment rubric

The MVP demonstration rubric is implemented in `demo/rubric.json`; the broader customer/use-case profiles below remain to be completed.

Create a machine-readable profile with stable check IDs, category, applicability, severity, evidence requirements, exact measurement, thresholds, and pass criteria. Version profiles by use case and nonprofit model. Keep queries, fixtures, scenario answer keys, and test expectations versioned alongside the rubric. Report the rubric version on every assessment.

Start with three categories: data quality, technical controls, and staff readiness. Keep checks equally weighted within each category and report category scores separately. Do not introduce a blended overall score in the first version.

Select required fields and freshness thresholds for the specific use case; do not declare email universally required. Establish thresholds before assessing an org, and record any profile overrides so results with different criteria are not presented as directly comparable.

## 2. Build deterministic collection and scoring

Use read-only Salesforce APIs or CLI for collection; implement scoring as ordinary code, not model judgment. Reuse existing tooling where it fits. Preserve raw numeric measurements separately from the derived status and score.

Target coverage is listed below. The MVP implements the fixed Contact count, email completeness, relationship and duplicate-indicator checks; freshness and comprehensive technical/runtime coverage remain pending.

| Category | Measurements or fixed tests |
|---|---|
| Data quality | Required-field completeness, relevant relationship integrity, freshness, duplicate indicators, sufficient test data |
| Technical controls | Required objects/licenses/settings; required and prohibited permissions; positive and negative runtime access tests; action approval, export restrictions, monitoring, and stop controls |
| Staff readiness | Seven questions with fixed scenario answer keys, required demonstrations, and recorded supporting evidence |

Each check returns pass, fail, unknown, or not applicable. Unknown includes denied collection, missing evidence, unperformed tests, and insufficient data. Accept not applicable only with a recorded profile rule or reviewed justification. A check must not pass merely because the dataset is empty.

For each category:

- Applicable checks = all checks except justified not-applicable checks.
- Score = passed / applicable × 100. Unknown checks earn no points.
- Coverage = (passed + failed) / applicable × 100.
- If applicable is zero, report not applicable, not 100%.
- Display counts with percentages and use a fixed rounding rule: one decimal place, round half up. Calculate decisions from unrounded values.

Keep critical gates separate from scores. A demonstrated critical failure blocks a pilot regardless of score. Unknown critical evidence yields readiness not established. A pilot recommendation also requires all profile thresholds, staff exercises, and operational controls to pass. Define those gates explicitly in the rubric; do not let the agent invent them per run.

Example presentation: “Technical controls: 80.0% score, 90.0% coverage; pilot blocked because the unauthorized-export test failed.”

## 3. Make the seven staff questions assessable

Retain the existing seven topics: approved scope/human decisions, sensitive data, hallucinations/prompt injection, runtime permissions, data quality, consequential-action review, and incident response/recovery.

Implemented in `references/staff-answer-key.json` and `scripts/staff_readiness.py`: seven fictional scenarios, observable required actions, fixed answer keys, evidence requirements and critical failure markers. The reviewer workflow maps yes/partly/no/unknown to underlying checks and requires confirmation plus an opaque evidence reference for conclusive results. The saved own-review form and calculated outcome display are implemented in Salesforce. Actual staff exercises and accountable evidence review remain pending; self-confidence and fictional fixtures cannot establish capability.

## 4. Separate assessment from active exercises

Read-only collection remains the default. Permission probes, action attempts, fixture creation, stop tests, and recovery exercises require an explicitly authorized isolated test context. Record unperformed active checks as unknown rather than quietly expanding assessment permissions. Use synthetic nonprofit data and the intended runtime identity; administrator success does not prove runtime access boundaries.

Store a sanitized assessment snapshot containing org identity, timestamp, collector/runtime identity, profile version and overrides, query/test versions, aggregate measurements, outcomes, evidence references, and errors. Never include credentials or personal record values. Treat source content as data, not agent instructions.

## 5. Validate repeatability and behavior

- Test the scorer with fixed snapshots covering pass/fail/unknown/not applicable, zero denominators, rounding, threshold boundaries, critical failures, and critical unknowns.
- Require identical scoring output for the same snapshot and rubric version, independent of the model used to write the report.
- Create a fresh Fundraising scratch org from the updated definition. Verify nonprofit objects and seed synthetic records with known completeness and relationship defects; assert expected measurements, then correct defects and assert changed results.
- Verify collection errors become unknown and empty data never earns a readiness pass.
- Test representative-user allowed and forbidden operations in an isolated environment. Validate approval and stop controls where the AI runtime is available.
- Run an end-to-end agent assessment and verify its report agrees with the deterministic evaluator. Record unsupported or unavailable checks explicitly.
- Validate NPSP separately using verified packages and dependencies; Fundraising results do not establish NPSP support.
- For variable AI responses, use fixed scenarios and explicit acceptance criteria, recording run counts and outcomes separately from deterministic configuration scores. Do not imply repeated scores prove identical model behavior.

## Delivery acceptance

The skill reports category scores, coverage, counts, rubric version, critical gates, evidence, remediation owners, and limitations. Every score is traceable to fixed rules and measured evidence. Replaying a saved snapshot reproduces its scores. Fresh Salesforce runs record changing data/configuration and collection boundaries; those are not assumed to be identical snapshots. No claim of production readiness follows from scratch validation alone.

## Demo seed data and scorer — implemented

All project artifacts live in `salesforce-nonprofit-ai-readiness/`, including this plan, the skill, references, demo fixtures, and scripts. See [demo/GUIDE.md](demo/GUIDE.md). Five synthetic scenarios demonstrate poor data, improvement, a ready-pilot simulation, clean data with a critical guardrail failure, and missing evidence. Salesforce Account/Contact import trees accompany offline snapshots and expected results. The standard-library demo evaluator computes category scores and coverage; assertion checks cover replay, thresholds, rounding, missing evidence, empty datasets, and critical failure outcomes.

Cohort-scoped live data collection and seed validation passed on 2026-10-19. The skill and activated Employee agent have observed end-to-end assessment runs. The full production rubric and actual staff/control exercises remain pending. Technical/staff fixture evidence is simulated and must never be used to claim live readiness. This plan does not authorize changes to customer orgs.

## Narrow MCP interface — MVP collection boundary

Provide a dedicated read-only MCP interface for the assessment skill rather than granting general CLI access. Bind its deployment to an explicitly authorized org and least-privilege Salesforce identity. MVP tools: `org_identity`, `readiness_check` for accessible organization Contact records or five fixed practice examples, and `org_capabilities` for licenses/features. Schema discovery and general assessment snapshots are deferred. Accept check/profile IDs and bounded parameters, not arbitrary SOQL, arbitrary HTTP, anonymous Apex, record exports, or writes. Return measurements, scope, check/query version, timestamp, and explicit denied/unsupported errors; never tokens or personal values. Enforce input validation, query/row/time limits, and org binding in the server, not only skill prompts.

Keep the scoring evaluator ordinary deterministic code, shared by CLI tests and the MCP path. The skill explains findings and remediation. Staff demonstrations and active runtime/control probes remain separately authorized evidence; a read-only collector cannot establish them. Scratch creation, seeding, and teardown remain outside the assessment MCP. Integration acceptance: the same measurement snapshot produces identical scores through either collection path; forbidden tools/parameters and cross-org access are rejected. The stdlib stdio server is `scripts/readiness_mcp.py`, bound to `.local/scratch.json` with active scratch verification. The default suppresses cohorts below five; `READINESS_SYNTHETIC_DEMO=1` explicitly permits the fictional demo cohorts only. See demo/GUIDE.md for client configuration. Integration test outcomes must be recorded from actual execution, not inferred from implementation.

## Critical gate: sensitive data must not reach the agent

The MVP implements an aggregate-only boundary and sanitized errors; it does not offer record-level assessment evidence or masking. The remaining requirements below are the roadmap before expanding that boundary. Mask inside the trusted server boundary, never by first sending raw data to an agent and asking it to redact it.

- Default to fixed aggregate checks. Keep raw values inside the collector; return counts, rates, check IDs, and sanitized errors. Apply a defined small-cohort suppression policy for sensitive aggregates and constrain query combinations to limit inference. Demo synthetic cohorts may use a separately marked test policy.
- Use versioned object/field allowlists and data classifications. Deny unclassified fields, record exports, and free-text notes by default. Field names alone do not establish sensitivity; approved classifications and the intended purpose determine allowed access. Never expose arbitrary SOQL or arbitrary schema/record retrieval through assessment tools.
- Where a use case explicitly requires record-level evidence, define a field-specific transformation before collection: removal, generalization, or stable pseudonyms scoped to an assessment. Keep identity maps/keys server-side; do not return reversible mappings. Pseudonymized values may still be personal data and are not automatically anonymous. Do not send donor/beneficiary names, email addresses, phone numbers, exact addresses, IDs, secrets, or safeguarding/health narratives to an agent by default.
- Validate every response against an approved output schema. Apply the same rules to tool errors, logs, traces, caches, and retries. If classification, masking, or output validation fails, return a sanitized denial with no partial payload. Log check IDs and outcomes, not source values. Bound permissions and storage independently of model instructions.
- Treat pattern/PII detectors as supplemental defense, not proof that unstructured text is safe. Default-deny free text until a separately approved and tested use case requires it. Output escaping and masking do not neutralize prompt injection; source content remains untrusted.

### Deterministic acceptance tests

Aggregate-only response/input/error-stream sentinel tests are implemented and included in local verification. Broader telemetry review and all future record-level transformations remain outside that evidence. Before expanding the interface, extend the suite with fake names, email/phone/address values, beneficiary/health/safeguarding notes, custom unclassified fields, Salesforce IDs, and credential-like strings. Verify forbidden fields are rejected and no disallowed original sentinel reaches tool responses, errors, logs, traces, or persisted snapshots. Assert exact permitted response schemas and masking transformations, missing/null behavior, small-cohort suppression, per-assessment pseudonym consistency and cross-assessment separation, nested payload handling, and failure paths. Include non-pattern sensitive content to verify it is denied by policy even when a detector would miss it. Reject requests that try to override policy through parameters or record instructions.

Record results as separate critical controls: classification coverage, allowlist enforcement, minimization, masking/output validation, telemetry hygiene, and suppression where applicable. A demonstrated raw-data leak blocks the pilot; an untested boundary leaves readiness not established. Never score these controls as passed from staff assurances or simulated fixture evidence. Runtime tests verify the assessed interface and version only; they do not guarantee every possible sensitive value can be detected.

## MVP completion boundary

Included: versioned local scorer, five seed scenarios, verified scratch setup/seeding/live data checks, narrow read-only MCP, aggregate minimization, small-cohort suppression, and automated boundary tests. Test execution results are recorded separately from this scope statement.

Deferred: customer/production deployment, NPSP validation, arbitrary object/schema discovery, record-level masking and pseudonymization, comprehensive inference resistance, actual staff demonstrations, representative non-administrator runtime permission probes, full consequential-action approval/stop tests, and production certification. Agentforce conversations have been observed in the separate scratch environment; those observations do not complete the remaining runtime-control exercises. Live technical safeguards remain unknown. Staff scores cover only the signed-in reviewer's saved observations; missing observations remain unknown, and offline passing fixtures cannot establish actual capability. Scratch runtime credentials may be broad; the MCP method boundary does not prove a least-privilege Salesforce identity. Production deployment requires its own identity/permission design.

## In-org results and Agentforce action — implemented

The Nonprofit AI Readiness app includes a native Lightning screen with Data quality, Access and safeguards, Staff readiness, and Recommended next steps. It assesses Contacts accessible to the signed-in user, using the shared action's deterministic data checks and summary-only boundary. Fixed practice groups remain separate replay examples. Small groups are withheld; no bypass is exposed inside Salesforce. The screen does not replace unknown staff or safeguard evidence with simulated passing results.

The shared Apex action can be selected in Agentforce Builder following references/agentforce-setup.md. No unrelated record retrieval, exports, or write actions belong in that demo agent. The separate Agentforce-enabled scratch org has completed publication, activation, native-action tests and a normal Salesforce header-panel conversation. These do not establish entitlement or intended-user access in another org.

## Current Salesforce assessment, follow-ups, and privacy checks

The full-width screen now runs against Contact records accessible to the signed-in user, with no sample-state selector. It calls the same shared assessment logic as the Agentforce-compatible action. The local MCP offers organization scope too. Fixed practice examples remain separate for repeatable scoring and guardrail demonstrations.

Recommendations include suggested owners and verified learning links. An explicit Create my follow-up tasks button creates fixed next steps for the signed-in user and reuses matching open tasks. The assessment and agent connection remain read-only; task creation is a separate user action and optional permission. Concurrent sessions can still race to create duplicate tasks.

The screen and restricted connection also inventory bounded product license assignments and fixed Fundraising, Service cases, and Knowledge availability/counts. Assignment counts are not actual usage; no visible records cannot prove a feature is unused. Missing access is unknown. Unlimited license totals are not presented as zero remaining seats.

Privacy and erasure readiness is shown as unassessed. A synthetic deletion exercise verifies that fresh assessments exclude a deleted contact without exposing its personal values, while explicitly confirming soft deletion leaves it recoverable. Whole-system erasure, backups, integrations, exports, AI logs, retention exceptions, and request handling are the active High-priority work item above and require separate external evidence. Expand the existing seven staff questions rather than adding an eighth.

Run `python3 scripts/check_all.py --live` for the complete automated MVP checks. It includes local tests, Salesforce action tests, connected scoring/privacy checks, inventory, action/connection agreement, and the synthetic deletion exercise. It does not launch an Agentforce conversation or replace browser checks.

## Final test matrix

| Planned check | Automated coverage | Remaining evidence |
|---|---|---|
| Versioned scores, coverage, thresholds, rounding, empty/unknown/N/A | Local scorer assertions and five saved expected scenarios | Use-case thresholds need owner approval for customer use |
| Read-only connection, fixed inputs, no raw values, sanitized errors | Python boundary tests and live MCP refusal checks | External logs/retention and production credential scope |
| Salesforce screen/action/connection agreement | Live organization + fixed-example comparisons | Different sharing configurations beyond tested user |
| User access restrictions | Restricted-user Salesforce tests, sanitized denial; scratch-administrator agent conversation | Full intended non-administrator runtime identity and control exercises |
| Relevant license inventory and no usage inference | Inclusion/exclusion tests, unlimited seats, bounded live inventory | Actual activity and AI feature activation |
| Tasks assigned to runner and repeat-click reuse | Salesforce tests with user-mode writes | Concurrent sessions may still create duplicates |
| Erasure lifecycle and no stale deleted-record inclusion | Salesforce rollback test + live fictional-contact soft-delete exercise | Physical erasure, backups, integrations, exports, logs and legal retention |
| Four-card responsive screen and real Run button | Salesforce deployment and separate desktop browser checks; activated assistant observed in normal Salesforce UI | Mobile-device checks and intended employee access remain separate |

The complete automated entry point is `python3 scripts/check_all.py --live`; screen and conversational checks are never silently counted as automated passes.

## Priority and impact rules — implemented

Next steps are ordered Critical, High, Medium, Low, with a reason explaining impact. Confirmed essential safeguard failures in the practice evidence are Critical. Unknown access controls and erasure processes are High; unverified staff practice is Medium. Missing-email findings are High below 50% completeness, repeated-email findings are High from 10% repeated rows, and unlinked-contact findings are High above 20%; otherwise those data findings are Medium. Too little evidence is Low priority. These are explicit MVP rules, not an inferred risk or legal score.

The screen, connected recommendations, and Salesforce follow-up tasks use these thresholds. Salesforce standard Task.Priority maps Critical/High to High, Medium to Normal, Low to Low. The exact severity and impact remain in each description. Refreshing follow-ups updates matching open tasks owned by the runner; write failures roll back the creation/update batch. No task is created by the read-only Run assessment button.

The complete check now includes the actual screen priority function's boundary checks in Node, Python recommendation/gate checks, and Salesforce tests for priority mapping and refreshing existing tasks.


## Demonstrate failures and the resulting actions

Run `python3 scripts/demo_failures.py` from the project folder. It compares fictional data and safeguard failures, seven failed staff exercises, and 14 failed erasure checks covering integrations, logs, backups, exports, repeat synchronization, and retention approval. Each produces prioritized next steps. Results are saved in `.local/failure-demo-results.json`; none are evidence about the real org.

Compare staff improvement with `python3 scripts/staff_readiness.py evaluate demo/staff-ready.json`. For an actual staff review, start with `python3 scripts/staff_readiness.py template`; a reviewer must confirm observed actions and supply an opaque evidence reference. Never substitute demo answers for staff observations.

The versioned scoring rules are in `demo/rubric.json`. The erasure checklist measures evidence coverage and keeps overall erasure unassessed until actual systems and outcomes have been verified. Importing demo records cannot turn off safeguards or establish erasure readiness.

For visible failures in the actual practice-org screen, run `python3 scripts/seed_failure_demo.py`, then choose **Run assessment** in Salesforce. This adds 60 fictional contacts with missing email addresses, repeated emails, and missing account relationships. It verifies the disposable org first, preserves the five original practice groups, and skips a complete previous import. It deliberately lowers the organization-wide score. The small-sample failure is demonstrated separately by the `poor` example; a sufficiently large dataset cannot also fail that check. Staff, safeguards, and external erasure failures remain separately labelled simulations, rather than weakening real org protections.


## Latest verification and remaining dependencies

An independent read-only agent ran this skill against the live fictional org and produced [an observed assessment report](references/agent-assessment-report.md). The report agrees with the 25% data score, measurements and six priorities. This is one independent skill-and-MCP agent run. Separate authoring-preview, activated native-action and normal Salesforce UI conversations have also been observed; none prove repeated model behavior.

The completion review is maintained in [completion-audit.md](references/completion-audit.md). The current staff-integrated baseline passes 76 local tests and three Node checks; the latest Salesforce deployment suite passed all 27 tests. Commit `b82d1fb` and its 70-local/19-Salesforce results are historical. Browser and conversation checks are separate evidence. The Agentforce-enabled environment and public SFDO-Community-Sprints repository exist. The previously supplied Serpent project now returns 404; the workspace org entry exists but remains Authentication required because Serpent rejects scratch orgs through its sandbox connection flow; no project link is verified. Actual staff demonstrations, intended employee least-privilege access, customer-use-case freshness requirements and external erasure evidence remain open; do not mark the whole project complete from these results.


## Live correction and restoration check — 19 October 2026

The live scratch exercise `python3 scripts/check_data_improvement.py` passed. Across 94 visible fictional contacts, correcting the guarded 60-contact failure set increased populated emails from 39 to 89, account relationships from 34 to 94, and reduced repeated-email rows from 10 to 1. Data score rose from 25% to 75%. The remaining repeated-email indicator belongs to the original five practice groups, so 100% is not expected. The exercise restored the original values and independently remeasured the baseline. Sanitized results are in ignored `.local/data-improvement-results.json`.

At that earlier correction/restoration milestone, `python3 scripts/check_all.py --live` passed with 52 local tests and 17 Salesforce tests, connected scoring, capability inventory and the source-deletion lifecycle. Those are historical counts, superseded by the current 76-local/27-Salesforce baseline above. The correction/restoration tests cover data drift, restoration after failures, atomic writes, wrong-org recovery and altered recovery-record IDs.


## Agentforce execution and reporting — verified scratch demonstration

A separate seven-day Agentforce-enabled Fundraising scratch org has now been created using `references/nonprofit-agentforce-scratch-def.json`. Its Employee Agent Script validates and publishes successfully. A live preview trace confirms execution of the fixed organization assessment action and the expected 94 contacts, 25% score, and deterministic priorities. Nineteen Salesforce tests passed during deployment to both practice orgs.

The five-prompt live preview collected actual responses and verified only the approved aggregate action in the completed trace. Raw-record, export and arbitrary-query prompts were refused, and a request to invent readiness passes was rejected. The reporting defect that confused passing checks with completed checks was fixed using a deterministic summary supplied by Salesforce and retested through the authoring preview and activated native action. The failure demonstration correctly reports one check passed and four completed. Refusal grading and preview traces are separate from deterministic score checks.


## Repeatable activated-agent demonstration

Use `python3 scripts/setup_agentforce_demo.py --hub YOUR_DEV_HUB` to prepare the separate seven-day Agentforce-enabled nonprofit practice org, including the specific-agent and employee-panel access for the authenticated scratch user, then `python3 scripts/check_agentforce_action.py` for the five fixed published-agent cases. The panel and assistant were observed in normal Salesforce UI under the scratch administrator; intended non-administrator employee access remains unverified. Use `python3 scripts/check_all.py --live --agentforce` after both practice orgs are prepared for the combined checks. Native-action responses require separate review and provide no action trace; the local authoring-preview test verifies the fixed action binding.

Public repository publication is complete under SFDO-Community-Sprints. The previously supplied Serpent project now returns 404. The workspace org entry exists but remains Authentication required: Serpent rejected both initial setup and a fresh reauthentication because scratch orgs must use its scratch workflow. No working repository or Salesforce-org connection is claimed. External erasure verification, real staff exercises, intended non-administrator employee access, mobile checks, freshness requirements and activity evidence remain open as recorded in the completion review. The optional beta evaluation produced no result during a 20-minute wait and is not a passing test; remote cancellation was not established.


## Saved staff exercises in Salesforce

A seven-section reviewer form now records structured observed actions, critical failures and opaque evidence references. Saving requires the separate Readiness Staff Reviewer permission; the ordinary assessment remains read-only. Salesforce computes scores from the fixed staff-readiness-v1 answer key, stores private review records, and returns only calculated own-review outcomes. The current reviewer’s latest exercises feed the screen, shared action, restricted connection, prioritized recommendations and optional own Tasks. A complete passing exercise review does not establish whole-team capability or overall pilot readiness. Missing observations stay unknown. Fictional simulation imports are rejected as actual evidence. See [the admin walkthrough](references/staff-review-in-salesforce.md) for scope and native sharing limits.

Cross-runtime verification includes a fixed 42-case staff scoring corpus; observed critical failures, missing actions, unconfirmed evidence and one-of-seven rounding are checked against Python and Salesforce. A screen regression check covers saving a critical review during an in-flight assessment. Actual team exercises, approved evidence review, representative employee access, freshness and whole-system erasure remain outstanding.

## Latest staff-integrated verification

`python3 scripts/check_all.py --live --agentforce` passed with the saved own-review integration. The Agentforce practice user has a saved review with all seven outcomes unknown and 0% evidence coverage; this is not a staff exercise pass. Its assessment returns 12 priorities: the data/control/privacy recommendations plus seven question-specific staff follow-ups. All five published-agent responses were manually inspected: the assessment listed all 12, unsafe raw-data/export/query requests stayed within the permitted summary boundary, and invented readiness passes were refused.

After that combined run, the guard-limit and in-flight-save regression checks passed: six targeted Salesforce tests passed in both practice orgs. Final local verification passed 76 tests and all three Node checks. The latest complete Salesforce deployment suite passed 27 tests; the targeted post-combined rerun is distinct from rerunning that entire suite. Real staff observations, evidence freshness, intended non-administrator access and external erasure scope remain unverified.


## Continuation — 20 October 2026 (Europe/Amsterdam)

The remaining-work tracker is [TODO.md](TODO.md). The latest continuation passed 93 local Python tests and three Node checks. Current metadata deployed to the verified active disposable scratch with 30 Salesforce tests passed and zero failures, including the added non-admin follow-up test and native freshness save/readback/rejection tests. This does not rerun the separate Agentforce environment, activated conversations or browser exercises.

Saved staff reviews now support an explicit opt-in observation-age policy. Retrieval reassesses opted-in evidence using the current Salesforce date; missing/expired evidence becomes unknown while confirmed critical failures remain blocking. Existing reviews without a policy retain their prior scoring and the staff form labels freshness unassessed. Policy selection is reviewer-controlled; approved customer policy and rendered browser verification remain outstanding.

A separate fixed read-only Contact LastActivityDate collector supplies aggregate freshness measurements with explicit policy, assessment instant and query version. The fictional scratch measurement was 94 Contacts and zero recent activity values under an illustrative 90-day policy, so freshness failed. It does not change the existing four-check native/MCP score or establish customer freshness requirements. The versioned catalog now specifies all 16 existing checks; native snapshot specification/override attachment remains open.

Real staff evidence, representative Employee assistant access, active runtime-control exercises, external erasure, customer policies, mobile/browser acceptance and NPSP remain outstanding. See the tracker for individual acceptance steps.


## Further continuation — 20 October 2026

Latest local validation passed **97 Python tests and three Node checks**. Current metadata deployed successfully in both identity-verified active scratch orgs with **31 Salesforce tests passed in each**. The extra specification-resource query required updating the batch-cache assertion; cached behavior remains tested. Native and restricted MCP aggregate outputs now attach the fixed specification version and empty profile overrides. Historical fixture replay is unchanged.

The main scratch received one unknown-only, unconfirmed review after checking that no existing review would be overwritten. The minimal existing reviewer permission was assigned only there. Exact native/MCP freshness readback passed: seven unknown checks, seven missing observation dates, zero score/coverage and no observation dates or evidence references returned. The illustrative age policy is synthetic test configuration, not approved customer policy or actual staff evidence.

Two published-agent rounds completed in ten distinct sessions before the Agentforce-org metadata synchronization. Both deterministic assessment responses passed their checks. The assistant inspected all eight safety texts: raw-data/export requests were refused, arbitrary queries received only fixed aggregate summaries, and invented readiness passes were rejected. Text observations do not verify underlying action traces or repeated behavior generally. After metadata synchronization, a separate read-only native call confirmed current specification metadata and unchanged unknown staff outcomes; conversations were not rerun.

Desktop browser interaction confirmed the actual assessment and saved expiry summary. The phone-emulation route redirected to Classic and did not establish mobile acceptance. Customer deployment prerequisites and NPSP feasibility are documented separately; actual customer policies/access, staff exercises, runtime controls, external erasure and mobile acceptance remain open in [the remaining-work tracker](TODO.md).
