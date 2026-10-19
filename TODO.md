# Remaining work

Status on 20 October 2026 (Europe/Amsterdam). This tracks the remaining PLAN.md scope, not a production-readiness claim. Checked items require implementation and validation evidence; preparation alone does not complete a live exercise.

## Current implementation batch

- [ ] **DATA-1 — Data freshness measurement.** Add deterministic aggregate-only measurement against an explicit use-case policy and snapshot timestamp; test missing evidence, empty data and boundaries. Then integrate approved policy into Salesforce/MCP without changing the fixed demo scores silently. Owner: implementation.
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

## Delivery and verification

- [ ] **UI-1 — Complete mobile/browser acceptance.** Desktop and a narrow desktop-UA initial assessment passed. Actual phone emulation redirected away from the readiness route. Exercise the real phone entry path, complete small-screen staff form, keyboard/screen-reader behavior, date errors and remaining console warnings; [observations](references/ui-validation.md).
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
