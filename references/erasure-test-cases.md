# Test the complete erasure process

**Current priority: High — readiness unknown.** Owner: privacy lead with Salesforce, integration, security and backup owners. This is a test plan, not a completed erasure assessment or legal advice. Do not mark an item passed from assurances alone.

The existing Apex test `deletionLifecycleExcludesDeletedContact` establishes only that fresh Contact aggregates exclude a fictional soft-deleted Contact and that its deleted record remains recoverable. Salesforce distinguishes deleting a record from its later removal; verify the actual org's retention configuration and deletion process rather than assuming the Recycle Bin is permanent erasure. [Salesforce Recycle Bin](https://help.salesforce.com/s/articleView?id=home_delete.htm&language=en_US&type=5), [extended retention](https://help.salesforce.com/s/articleView?id=000387160&language=en_US&type=1).

## Prepare one controlled fictional subject

Use an isolated test environment and a unique fictional subject, for example request `ERASURE-DEMO-001`, with an `example.invalid` email. Keep its Salesforce/test-system identifiers in a restricted test ledger, outside agent outputs. Record the environment, test version, responsible owner and timestamps. Do not copy real beneficiary/donor data or identity documents into evidence.

Before deletion, prove this fictional subject exists in each intended destination. Record matching counts and opaque evidence references, not copied payloads. Inventory integrations, export locations, search/vector stores, agent caches, logs, snapshots, backup copies and downstream recipients. Missing destinations or access leave the corresponding test **Not run**, never passed.

## Execute and observe

Each row needs an actual observation before and after the documented approved test operation. Use system-specific procedures scoped to this fictional subject; this checklist does not authorize deleting real data or emptying an entire Recycle Bin.

| Test | Procedure and pass evidence | Current status |
|---|---|---|
| Salesforce active records | Create the fictional Contact; assess; soft-delete only that Contact in the test environment; assess again. Count rises then returns to baseline and no identifying values appear in output. | Passed source-query component only; see [MVP validation](mvp-validation.md) |
| Salesforce deleted/related records | Inspect the fictional subject's recoverable deleted records, related records/files/history and configured retention. Verify the approved treatment for each with observed results; document any retained copies and restrictions. The existing soft-delete test deliberately shows recoverability. | Complete erasure test Not run |
| Connected systems and recipients | For each inventoried destination, propagate the approved fictional request; query the destination using the restricted test identity. Observe deletion or approved restriction there and capture its completion acknowledgment. A queue acknowledgment alone is insufficient. | Not run |
| Logs and audit history | Exercise success, denial and failure paths. Search only for the fictional sentinel in app logs, agent traces and support/error stores. No subject payload should be retained unnecessarily. Keep a minimal restricted audit trail: request ID, decision, destination, timestamp, outcome and evidence reference. Record any approved retained fields and expiry. | Not run |
| Sync, backfill and replay | After destination removal/restriction, run a normal sync, an authorized backfill and replay of an older fictional event in isolation. Verify the deletion marker/ledger blocks reintroduction and restricted data does not appear in responses or downstream stores. | Not run |
| Agent caches and retrieval | Warm the cache/search index with the fictional subject, execute the approved removal/invalidation, then start a fresh agent session and repeat fixed retrieval prompts. Observe no stale subject result. Verify retries and cache refresh do not resurrect it. | Not run |
| Existing assessment snapshots | Locate pre-deletion snapshots, verify whether they contain only minimized aggregates, and record their retention/access policy. Fresh aggregates must exclude deleted active records. Do not interpret an old aggregate count as evidence of a retained raw subject record, or claim this proves raw-data erasure elsewhere. | Not run |
| Backup restore and deletion ordering | In an isolated restore environment with outbound connections disabled, restore a pre-request fictional backup. Apply the protected deletion ledger **before** enabling queries, agents, sync or exports. Replay the fictional request, rebuild derived indexes, and verify the subject cannot reappear. Record backup expiry and the approved treatment while copies remain. Do not modify a production backup to run this test. | Not run |
| Retention exceptions and completion | Privacy/legal owner reviews the applicable basis, scope, expiry and access restriction for any retained data. Verify a scheduled test expiry/review actually runs and that the final request outcome accounts for every destination and exception. Do not label justified restricted retention as deletion. | Not run |

Erasure rights have conditions and exceptions; the accountable privacy/legal reviewer must determine what applies to the actual request. Review downstream notification obligations and record the decision. [EDPB individual-rights guidance](https://www.edpb.europa.eu/sme/be-compliant/respect-individuals-rights_en).

## Evidence and decision

For every test retain: request ID, destination/environment, test version, operator role, start/completion time, before/after counts, expected outcome, observed outcome, sanitized evidence reference, retained-data reason/expiry where applicable, reviewer and next owner. Keep identifiers and any necessary reidentification map protected separately; a deletion ledger itself needs minimization and an approved retention policy.

Use **Pass / Fail / Not run / Not applicable** with an evidence-based justification. A signed checklist without observations is not a pass. Unknown destination behavior stays **High priority**. A verified leak or reintroduction of subject data contrary to the approved test expectation is **Critical** and blocks a pilot until corrected and retested. Expected isolated backup presence before ledger application is not by itself a failed test; exposure after activation is.

Still needed from the organization: system/recipient inventory, test-environment access, connector and cache owners, backup restore procedure, retention schedules, applicable exception decisions and evidence storage location. Until those are supplied and observed tests run, end-to-end erasure readiness remains **unknown**.
