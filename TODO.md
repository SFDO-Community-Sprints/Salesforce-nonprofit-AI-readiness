# Remaining work

Status on 20 October 2026 (Europe/Amsterdam). This tracks the remaining PLAN.md scope, not a production-readiness claim. Checked items require implementation and validation evidence; preparation alone does not complete a live exercise.

## Current implementation batch

- [x] **DATA-1 — Native data freshness measurement.** Explicit-policy aggregate LastActivityDate measurement now runs in Apex and the Salesforce form, with UTC boundaries, suppression and non-admin access/denial tests. Dedicated MCP remains the existing fixed contract; customer policy approval is separate.
- [x] **STAFF-1 — Evidence freshness implementation.** Explicit opt-in policy, observation dates, preserved critical failures, current-date reassessment and native/MCP parity implemented and scratch-tested; desktop readback verified. Customer policy approval remains PROFILE-1; mobile acceptance remains UI-1. Owner: implementation + assessment owner.
- [x] **PRIVACY-1 — Erasure evidence validation implementation.** Inventory validation and procedures require accountable destination/retention references and keep reported/fictional evidence distinct from independent verification. Actual system verification remains PRIVACY-2 through PRIVACY-6. Owner: implementation + privacy lead.
- [x] **ACCESS-1 — Repeatable access test coverage.** Added non-admin positive/negative permission coverage and executed it in the disposable scratch. Actual intended Employee assistant access remains ACCESS-2. Owner: implementation + Salesforce admin.

### Implemented locally in this batch

- [x] DATA-1a: Aggregate-only offline freshness evaluator with explicit policy/as-of and suppression; [contract and limitations](references/data-freshness.md). Live collection/native integration remain DATA-1.
- [x] STAFF-1a: Offline and opt-in native staff freshness validation, dynamic current-date reassessment, canonical MCP output, 45-case parity corpus and scratch Apex tests. Customer policy approval and browser acceptance remain STAFF-1.
- [x] PRIVACY-1a: Actual erasure destinations require opaque owner, destination, retention-policy and privacy-approval references; reference isolation tested. Actual evidence verification remains PRIVACY-1 through PRIVACY-6.
- [x] ACCESS-1a: Non-admin positive follow-up permission test alongside existing denial coverage; deployed successfully in the verified disposable scratch. Intended Employee assistant identity remains ACCESS-2.
- [x] DATA-1b: Fixed read-only scratch LastActivityDate aggregate collector and live illustrative measurement. Native score/MCP/UI integration and customer-approved activity meaning remain DATA-1.
- [x] PROFILE-2a: Versioned catalog of all 16 current checks, thresholds and answer-key alignment; [specifications](references/check-specifications.md). Native/MCP snapshot specification versions and explicit empty fixed-profile overrides are attached and locally tested; live parity passed in the main scratch. Custom approved policies/overrides remain PROFILE-1.

## Assessment scope and data

- [ ] **PROFILE-1 — Customer-approved use-case profile.** Define permitted users/actions, required fields, thresholds, freshness, evidence expiry, critical gates, exclusions and overrides with accountable owner. Remove universal email assumptions from future customer profiles.
- [x] **PROFILE-2 — Fixed-profile check specifications.** All 16 check definitions are versioned; native/MCP aggregate snapshots attach specification_version and explicit empty profile_overrides. Historical replay is preserved. Customer profile/override execution remains PROFILE-1.
- [ ] **DATA-2 — Broader collection.** Add only approved use-case objects/relationships and bounded collection, including deny/unsupported/empty behavior. Arbitrary schema discovery/general snapshots remain deferred until explicitly scoped.
- [ ] **NPSP-1 — Separate NPSP profile and disposable validation.** [Read-only feasibility and installation plan](references/npsp-validation-plan.md) completed using official sources and sanitized local observations. A separate compatible target, installation, schema/fixture work and actual collection/scoring remain unperformed. Fundraising is not NPSP evidence.

## Staff, safeguards and feature evidence

- [ ] **STAFF-2 — Actual seven staff exercises.** Collect observed demonstrations, accountable reviewer approval and approved evidence references; scope results to observed people and dates. Fictional answers are not evidence.
- [ ] **ACCESS-2 — Intended employee access.** Provision approved least-privilege test identity in an isolated org and verify normal screen/Employee assistant positive and forbidden operations under that identity.
- [ ] **CONTROL-1 — Active control exercises.** Execute approved runtime permission, export denial, consequential-action approval, monitoring, escalation, stop and recovery scenarios with evidence. Unperformed checks remain unknown.
- [ ] **FEATURE-1 — Prerequisites and use.** Confirm actual required entitlement/settings and product activity using authorized evidence; assigned licenses alone are insufficient.
- [x] **AGENT-1 — Bounded repeated response evaluation.** Added 1–5 round support and declared criteria; executed two rounds/ten distinct sessions and inspected all ten response texts. Two automated assessment checks passed; eight safety texts met the reviewed criteria. Native action tracing remains unavailable, so no action-trace pass is claimed.
- [ ] **AGENT-2 — Optional beta evaluation state.** Earlier run with no result remains unpassed; inspect the remote job/cancellation state if accessible. No repeated-model guarantee follows from AGENT-1.

## Privacy and whole-system erasure — High priority

- [ ] **PRIVACY-2 — Actual system inventory.** Name Salesforce records/files, exports, connected destinations, agent/prompt/application/audit logs and backup providers; record owners, evidence sources, scope gaps and authorized access.
- [ ] **PRIVACY-3 — Approved request and retention scope.** Obtain synthetic subject/request verification, privacy-approved retention schedule and documented restriction/legal-hold exceptions.
- [ ] **PRIVACY-4 — Authorized destination tests.** Verify permitted erasure/restriction per system, agent-output absence, scheduled synchronization and replay without reintroduction.
- [ ] **PRIVACY-5 — Logs and backups.** Verify approved log handling and backup expiry; perform isolated restore with suppression/redeletion controls. Preserve required audit evidence.
- [ ] **PRIVACY-6 — Combined evidence review.** Independently review all required destinations and outcomes before changing “Privacy and erasure: Not assessed”. Source-only deletion never completes this.
- [ ] **PRIVACY-7 — Output/telemetry policy.** Review actual logs, traces, caches and retries; complete versioned field classification/allowlist and response-schema enforcement for any expanded interface.
- [ ] **PRIVACY-8 — Conditional record-level support.** Only if an approved use case requires it: trusted-boundary removal/generalization/pseudonyms, server-side key handling, nested/failure-path sentinel tests and classification coverage. Keep record/free-text access denied otherwise.
- [ ] **PRIVACY-9 — Inference resistance.** Define and test protections before expanding fixed aggregate queries or customer-data access.

## Narrow role implementation

- [x] **ROLES-1 — Focused specialist grants.** Data Assessor, Staff Reader, Staff Reviewer, Follow Up, Employee Agent Access and MCP are separate roles. Assessor has no staff evidence grants; Staff Reader has no raw review CRUD/FLS; Task writes require an explicit custom permission before queries/DML.
- [x] **ROLES-2 — Dedicated MCP identity.** Provisioned and pinned separate API-only integration identity with zero profile/role object permissions and zero field grants. Exact grants/profile and OAuth user/org are verified before tools run; there is no admin collection fallback. Fixed aggregate facade is sharing-scoped, not general CRM read access or restriction-rule validation.
- [x] **ROLES-3 — Boundary validation.** Both scratch deployments passed 37 Apex tests. Live raw Contact email query denied; object describes denied; effective zero CRUD/FLS confirmed. No live create attempts were made. Native/MCP same-identity parity passed; current small visible scope is withheld, with no staff data. No extra record shares or broad privileges were added to obtain a score.

## Delivery and verification

- [ ] **UI-1 — Complete mobile/browser acceptance.** Desktop and a narrow desktop-UA initial assessment passed. Actual phone emulation redirected away from the readiness route. Exercise the real phone entry path, complete small-screen staff form, keyboard/screen-reader behavior, date errors and remaining console warnings; [observations](references/ui-validation.md).
- [x] **UI-2 — Evidence-backed safeguards/privacy cards.** Native structured forms evaluate reported safeguard and erasure evidence; live role-configuration measurements populate scoped configuration cards. No evidence still means Not assessed; references do not establish independent verification. The five live technical checks and whole-system erasure remain external evidence work.
- [ ] **DEPLOY-1 — Customer deployment acceptance.** [Deployment design](references/customer-deployment-design.md) now identifies concrete target/identity/policy/retention/stop/rollback requirements. Customer authorization, collector implementation and environment-specific acceptance remain open; scratch results do not complete these.
- [ ] **LINK-1 — Serpent connection.** Repair/replace the unavailable project and authenticate through a supported org flow; verify repository and org links. No working connection is currently established by this repository.
- [x] **VERIFY-1 — Integrate this implementation batch.** Local tests, both scratch deployments, native/MCP parity, desktop rendering and bounded repeated conversations recorded separately below. Mobile acceptance and real-world controls remain their own open tasks.

## Validation of this batch

Initial batch: 85 local tests and three Node checks passed.

Continuation on 20 October (local date): `python3 scripts/check_all.py` passed **93 Python tests**, fixture/replay checks, fictional failure demonstrations and **three Node checks**. `git diff --check` passed. Current metadata deployed successfully to the saved, identity-verified active disposable scratch: **30 Salesforce tests passed, zero failures** across both test classes, including non-admin follow-up access, native freshness save/readback and invalid-policy rejection. The report completed at 2026-10-19T23:10:53Z.

The separate read-only activity collector measured 94 fictional Contacts and zero recent LastActivityDate values under an illustrative 90-day/90% policy. Freshness failed; existing four-check data scores were unchanged. Its scope is accessible Contacts, not guaranteed whole-org data. No records were changed for this measurement.

A read-only live assessment action call succeeded after deployment. That practice identity had no saved staff review, so no live policy-bearing MCP readback is claimed; canonical freshness output is covered by local boundary tests and native Apex save/readback tests.

No new browser/mobile or activated Employee conversation verification is claimed. At that earlier point, browser inspection found no connected authenticated Salesforce session. A subsequent native browser check is recorded below. No external erasure or real staff evidence was created; customer and external dependencies remain open.

## Dependencies

Real staff observations, customer policy approval, named external systems and test credentials, retention approval, a representative employee identity, NPSP environment and a supported Serpent connection cannot be supplied by code or fictional fixtures. Keep their items open until evidence exists.

## Latest continuation — live readback, snapshot metadata and repeated evaluation

- Local verification passed **97 Python tests and three Node checks**; whitespace checks passed.
- Both verified disposable scratch orgs now have current metadata and passed **31 Salesforce tests each**. Main scratch metadata deployment passed **31 Salesforce tests** after updating the cache test for the added specification-resource query. Live action/MCP parity passed for all five practice scenarios and organization scope, including specification metadata and exact staff freshness equality.
- Minimal existing reviewer permission was assigned only to the saved verified scratch identity. After confirming no previous owned reviews, one all-unknown/unconfirmed review with an illustrative explicit age policy was saved. No existing review was overwritten and no observation or competence pass was fabricated. Native/action/MCP readback showed seven unknown outcomes, seven missing observation dates, score 0% and coverage 0%.
- Two published-agent rounds completed in ten distinct sessions. Both assessment checks passed; all eight safety response texts were inspected by the assistant against the stated criteria. Source and review evidence are separate ignored `.local/agentforce-action-results.json` and `.local/agentforce-response-review.json`; the review binds to the source hash. These conversations preceded the separate Agentforce-org catalog metadata synchronization and supply no action trace. After synchronization, the Agentforce native action separately confirmed the specification version, empty overrides and unchanged unknown staff results; conversations were not rerun.
- Desktop Salesforce browser interaction/readback passed. At 393px with desktop user agent, the initial screen and Run assessment also worked; the complete staff form was not inspected there. Mobile-user-agent emulation redirected the custom route to Classic and did not establish mobile acceptance; UI-1 remains open. Details are tracked in [browser validation](references/ui-validation.md).

Do not reuse scratch synthetic review-policy values as customer-approved policy. Real staff exercises, customer-approved profiles, intended non-admin Employee access, external erasure and mobile acceptance remain open.

## Role boundary continuation — 20 October 2026

Final local verification passed **117 Python tests and three Node checks**. Both verified scratch orgs passed **37 Apex tests each** with the current role/facade/UI metadata.

See [permission scopes](references/permission-scopes.md) for role composition, dedicated API-only setup and elevated fixed aggregate computation limits. Earlier MCP staff-summary observations in this tracker describe the prior shared scratch credential. The current MCP role deliberately exposes no staff outcome or review evidence and always suppresses cohorts below five; the synthetic environment bypass was removed from the live MCP path.

Current dedicated identity uses Minimum Access - API Only Integrations with only the Readiness_MCP set plus the platform's implicit matching profile assignment. Its profile has only API transport/API-only login/ChatterInternalUser flags and no object/field grants. Extra roles, profiles, custom grants, groups or cross-org/user credentials are rejected. Scratch administration is used for control-plane verification only; Contact aggregation runs as the dedicated identity via the fixed with-sharing facade. Restriction-rule behavior is not established by system CRUD/FLS aggregate computation.

Live `org_identity` and sharing-scoped organization assessment succeeded. The dedicated identity's current visible cohort is below five, so metrics and score are withheld and readiness remains not established. Same-identity native/MCP parity passed; the administrator's larger dataset is not treated as the integration user's scope. Raw Contact email retrieval was denied, and object describes were denied. No live write attempts were made. The UI now hides staff editors and Task controls unless the corresponding specialist permission is present; role-loading and handler denial are covered by Node/native tests.

The Access and safeguards and Privacy and erasure page cards are still hardcoded unknown states (UI-2). These app permission tests do not supply all runtime/approval/export/monitoring/stop evidence or integration/log/backup/restore/retention erasure evidence.

## Native Apex assessment migration — 20 October 2026

Assessment users no longer need Python: existing Contact/feature/staff logic is joined by native policy-based activity freshness and safeguard/erasure evidence evaluators. Structured forms avoid JSON editing. Every assessment uses live inputs; preset-result paths were removed. A separate Evidence Reviewer role grants evaluator access only. The post-deployment Apex script idempotently assigns Readiness Assessor to its executing user; no seed data is required to open the app. See [native assessment map](references/native-assessment.md).

Validation: 119 Python tests, four Node checks, eight Python-driven Apex parity fixtures, and full metadata deployment with 51 Apex tests passed in the existing disposable `nonprofit-readiness-demo` scratch org. This does not prove deployment to `data-connect-7516`; its separate local CLI login was not completed. Customer readiness, external safeguards/erasure, mobile and production acceptance remain open.

## Executable acceptance continuation — 20 October 2026

- [x] Execute current-principal native/MCP and unauthorized-action checks; display outcomes and unresolved identity/workflow bindings.
- [x] Add package stop/resume enforcement and sanitized private operational events with separate specialist permissions.
- [x] Add an explicitly confirmed scratch-only canary lifecycle probe, including active-read exclusion and recoverability checks.
- [x] Integrate executable verification into Run assessment and the post-deploy scratch role setup.
- [x] Validate full metadata deployment with **79 Apex tests** in `nonprofit-readiness-demo`; **123 Python tests and six Node checks** pass.
- [x] Deploy and execute the new verification in `data-connect-7516` through Initial PoC; see live evidence below.
- [ ] Bind the actual assistant identity/workflow and named external destinations, then execute their acceptance checks.
- [ ] Obtain actual human demonstrations and approved retention decisions.

The earlier hardcoded-card and simulated-result descriptions above are historical. Current collectors use real org/configuration/input records, and executable probe results retain their measured scope. See [executable acceptance](references/executable-acceptance.md) for the remaining acceptance matrix.

### Live native verification

Serpent DEPLOY-18 succeeded with 58/58 components. Post-deploy and executable runtime/erasure probes compiled and succeeded. Separate transactions verified committed package stop, denied calls, resume and assessment recovery; package left enabled. Lightning Run assessment displayed executed results and missing bindings. Active canary exclusion passed; permanent erasure failed because the canary remained recoverable. Actual assistant, external destinations and human acceptance remain open. Details: [live executable evidence](references/executable-acceptance.md#live-execution--20-october-2026).

## AI readiness health dashboard — 20 October 2026

- [x] Replace mixed configuration/practice headline percentages with our own AI-readiness score, coverage, four categories, inventory and actual-versus-expected findings.
- [x] Implement native `ReadinessOrgHealth` collector and invocable tool action; no Salesforce Health Check dependency or external runtime.
- [x] Add separately scoped Security Reader and retain unknown org findings without that role.
- [x] Exclude seeded staff input from human readiness, persist scoped canary observations, and enforce critical failure gating.
- [x] Full metadata validation passed 84 Apex tests in the validation scratch org; all seven UI checks passed.
- [x] Verify dashboard deployment and native browser scan on `data-connect-7516`: DEPLOY-26 succeeded, 24.2% score / 39.4% coverage matched native MCP readback; see health rubric live evidence.

Remaining actual assistant, external erasure and human evidence requirements are unchanged. The [AI readiness rubric](references/ai-readiness-health.md) defines what the new score measures.

## Reference-app improvements identified on 21 October 2026

Implemented in the native app; evidence and limits are recorded in the [workspace validation](references/implementation-workspace.md#executed-validation-21-october-2026). The original [reference review](references/reference-app-review.md) remains presentation evidence, not proof of the other app's backend.

- [x] REF-1: Implementation/use-case scope and actual AI connection registry.
- [x] REF-2: Guided Company, Org and Implementation checklists, reusing existing staff exercises.
- [x] REF-3: Responsible person/role, due date, notes and evidence per gap.
- [x] REF-4: Versioned, sanitized saved scan history and scope-aware comparisons.
- [x] REF-5: Filtered/grouped findings with advice and links to exact checklist questions.
- [x] REF-6: Bounded use-case-specific grant, sharing, grounding-metadata and data collectors.

Existing real-assistant, external-erasure, human-evidence and production acceptance dependencies remain open.

- [x] REF-UI desktop acceptance: DEPLOY-61 delivered native Assessment records, white standard components and saved findings. Browser checks confirmed real record navigation/values, history comparisons and scope warnings, self-comparison rejection, connection registration, portfolio rows, checklist progress and live actor/age. Live Serpent assertions preserved all eight upgraded reports and blocked forged metrics. Permission behavior passed in the validation org; the target browser session used its existing administrator. See [delivery evidence](references/implementation-workspace.md#combined-delivery-21-october-2026).
- [ ] Separate UX checks: mobile viewport, assistive technology and a complete target-org walkthrough using each focused non-administrator role.

## Combined reference/current gap audit — 21 October 2026

The existing REF-1–REF-6 implementations remain complete; this is the narrower visible-gap backlog after inspecting every reference navigation tab and current source. See [comparison and inspection limits](references/reference-app-gap-audit.md).

- [x] REF-7 — Add portfolio triage to existing Use Cases: standard table with business owner, lifecycle, latest accessible scoped score/coverage/readiness/critical count; Not checked when no scoped snapshot exists; Approved never overrides measured Blocked. Reuse existing editor and scan action.
- [x] REF-8 — Display live scan actor and elapsed age alongside source/time/scope; distinguish saved observations and refresh; age-based expiry needs an approved policy, not the reference's unapproved 24-hour default.
- [x] REF-9 — Expose stage progress for existing guided checklists using saved answered/unanswered/accountable counts per selected scope. Stage navigation must not save answers implicitly or equate completed policy answers with executed safeguards or human competency.

Native record Findings, white cards, warning/registration and the three visible-gap improvements were deployed and desktop-verified in DEPLOY-61; this audit does not reopen their existing components. Actual assistant, external erasure and human acceptance remain separate requirements.

## UI/UX follow-up review, 21 October 2026

- [x] Group the use-case editor, show required fields, focus opened editors and invalid inputs, and use appropriate single-line controls.
- [x] Limit implementation selection to Implementation checklists; explain empty gap filters with a reset that preserves drafts.
- [x] Add comparison reset, readable outcomes and timestamp times; clarify recent-history scope and practice-answer coverage.
- [x] Commit/sync `413d086`; Salesforce dry-run `0AfJW00000ngmC70AI` compiled both components; local suite passed 126 tests and ten UI checks; Serpent DEPLOY-69 (`0AfPw00000as91aKAA`) deployed 2/2 components with zero failures.
- [ ] Repeat final rendered checks of the changed editor, empty-filter reset, comparison reset and practice wording. The pre-change desktop walkthrough reproduced the issues, but concurrent Edge activity interrupted the post-deployment recheck. No final visual pass is asserted. Existing mobile, assistive-technology and focused-role checks remain open.

Unsaved drafts are retained only within the current workspace page; leaving an app tab or refreshing can discard them. The new notice makes this explicit. This review does not add cross-tab draft persistence or change assessment scoring/permissions.
