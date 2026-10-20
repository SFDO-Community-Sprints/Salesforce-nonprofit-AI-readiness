# Assessment inside Salesforce

The assessment runs in the target org; users do not need Python or a remote scanner.

| Assessment | Apex implementation | Salesforce entry point |
| --- | --- | --- |
| Four Contact data checks and recommendations | NonprofitAIReadiness | Run assessment |
| Accessible license and feature inventory | NonprofitAIReadiness.capabilityInventory | Run assessment |
| Explicit-policy activity freshness | ReadinessDataFreshness | Additional readiness checks |
| Seven observed staff exercises and evidence expiry | ReadinessStaffReview | Staff review |
| Five safeguard checks, score, coverage and critical gate | ReadinessEvidence.evaluateSafeguards | Safeguards evidence form |
| Erasure destination inventory and fourteen required probes | ReadinessEvidence.evaluateErasure | Erasure evidence form |

Assign Readiness Assessor to expose the app/tab and read-only Contact assessment. Assign Readiness Evidence Reviewer separately to evaluate safeguard/erasure references, and Readiness Staff Reviewer separately to create staff reviews. No specialist API, Task or deletion permissions are bundled into the assessor. The dedicated MCP role is unchanged.

Run `scripts/apex/post-deploy.apex` as the intended assessor to assign only the assessor permission set, or use Setup → Permission Sets → Manage Assignments. Open `/lightning/n/AI_Readiness` after refreshing the Salesforce session. Deploying metadata by itself does not assign roles or seed records. No background job or sample data is required to display the application.

The new evidence form uses structured inputs, builds a strictly validated payload, and holds results only for the current screen session. Inputs contain opaque controlled-evidence references; no donor values or raw artifacts are required. Save the approved source evidence in the organization's controlled evidence store. Staff reviews retain their existing permission-controlled persistence.

Python scripts are retained as development tooling: fixtures, parity tests, scratch creation/seeding/deployment, dedicated MCP provisioning and isolated live verification exercises. These are not operations that should automatically run in an installed package. Executing the development `--live` test suite modifies fictional records and is not a read-only scan.

Missing access and small cohorts remain unknown. Policy-based LastActivityDate measurements do not prove donor details are current. Reference evaluation produces reported or simulated evidence coverage, not independent verification. External integrations, exports, logs, backups, retention approvals and restore/synchronization outcomes still need actual observed tests. These results do not certify organizational readiness or compliance.

## Validation

On 20 October 2026 the full metadata deployed to the existing disposable demo scratch org and all 51 Apex tests passed, including non-admin freshness success/denial, dedicated reviewer permission checks and eight Python-generated evidence parity fixtures. Local validation passed 119 Python tests and four Node checks. A final LWC deployment succeeded. The post-deployment Apex script succeeded twice without duplicate assignment. Browser readback confirmed the app, additional checks, permission-gated reviewer section and a successful Run assessment. This evidence concerns the existing demo scratch org, not `data-connect-7516`, whose CLI login was not completed. No mobile acceptance or independently verified external safeguards/erasure is claimed.

## Complete fictional walkthrough

`seed-demo.apex` now seeds five owner-scoped simulation snapshots in addition to five Accounts and 34 Contacts. The snapshots cover the versioned data, safeguard and seven staff outcomes, plus erasure probes. They use `demo-scenarios-v1` records; actual latest staff reviews explicitly select `staff-readiness-v1`, so simulated outcomes cannot replace actual evidence. The read-only scenario accessor validates mode and owner before returning snapshots.

The Assessment source selector defaults to Live organization. Five explicitly labelled Simulation options render all four cards and the staff/safeguard/erasure details, without creating tasks or saving staff reviews. `post-deploy.apex` assigns the executing demo user the three separate assessor/staff-reviewer/evidence-reviewer roles; it leaves MCP, agent and follow-up access unassigned. Refresh Salesforce after setup so custom permissions reload. Local validation passed 123 Python tests and five Node checks; full deployment passed 62 Apex tests in the existing disposable demo org.
