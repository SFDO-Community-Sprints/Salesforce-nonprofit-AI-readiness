# Observed agent assessment

**Decision: Readiness not established.** One independent agent assessment ran on 2026-10-19 at 12:23 UTC against the saved, verified active disposable scratch connection. It measured live Salesforce aggregates over the prepared fictional data. It did not assess a customer production org.

Assumed use case: a staff-only donor-summary pilot with human review. Proposed access: approved donor context and summaries; consequential decisions or writes need separately verified controls. The current run performed no Salesforce writes or follow-up Task creation.

## Observed data quality

Rubric: `donor-summary-demo-v1`. Scope: Contact records accessible through the configured assessment connection, not proven complete organization coverage. Collected at `2026-10-19T12:23:20.670676+00:00`.

**Data score: 25.0% — 1 of 4 checks passed. Evidence coverage: 100.0% — all 4 data checks completed.** Coverage means these four measurements were obtained, not that every readiness topic was covered. No blended readiness score is assigned.

| Check | Observation | Result |
|---|---|---|
| Sufficient data | 94 accessible Contacts; demonstration threshold at least 10 | Met |
| Approved contact channel | 39 of 94 have email, 41.5%; threshold at least 90% | Gap |
| Account relationships | 34 of 94 linked; 60 unlinked | Gap |
| Duplicate indicator | 10 repeated populated-email rows; threshold zero | Gap |

Email is an explicit demonstration requirement, not a universal nonprofit requirement. Repeated emails indicate review candidates, not proven duplicate people. Freshness, gift quality, source accuracy and broader nonprofit processes were not measured.

## Recommended actions

| Priority | Finding and impact | Next action | Suggested owner |
|---|---|---|---|
| High | Access, approval, export and stop controls remain unknown; unsafe actions cannot yet be ruled out | Observe allowed/forbidden operations, approval and stop exercises under the intended runtime identity | Salesforce/security owner |
| High | Sensitive-data and complete erasure handling remain unknown | Execute the fictional-subject tests across actual integrations, logs, backups, restore and retention; see [erasure test cases](erasure-test-cases.md) | Privacy lead and system owners |
| High | 55 missing emails limit the approved contact-channel use case | Verify whether the requirement applies, then correct only from approved sources | Data steward |
| High | 10 repeated-email rows exceed the high-impact threshold of 10% of accessible Contacts | Review identity ambiguity without automatically merging people | Data steward |
| High | 60 unlinked Contacts exceed the high-impact threshold of 20% | Verify and correct relationships where known | Salesforce/data owner |
| Medium | Staff capability has not been demonstrated | Run the seven fictional exercises with reviewer-confirmed evidence | Training/process owner |

No observed Critical failure is established by this assessment. Unknown controls are High-priority work, not evidence that a leak or unauthorized action occurred.

## Relevant licensing and available objects

Inventory collected at `2026-10-19T12:23:22.461374+00:00`. This is a bounded AI-readiness overview, not a licensing audit or product recommendation.

| License label returned by Salesforce | Total | Assigned | Remaining | Interpretation |
|---|---:|---:|---:|---|
| Salesforce | 5 | 1 | 4 | Core platform access |
| Fundraising Access | 10 | 1 | 9 | Nonprofit grounding access; not itself AI enablement |
| Fundraising Access Digital Agent | 10 | 0 | 10 | Available assignment capacity; enabled assistant behavior not established |
| Remote Data Cloud | 200000 | 0 | 200000 | Optional grounding entitlement; necessity and applicability unverified |

These are allocation counters, not active-user counts, engagement measurements, monetary value, or evidence that a feature is unused. Do not interpret the large Data Cloud entitlement as a recommended purchase or a required prerequisite.

Fundraising, Service cases and Knowledge were reported available to the connection. Their record counts were withheld under the small-count policy. No zero count or disabled feature can be inferred from a withheld value. Feature usage remains `not_verified` for all three. The inventory is consistent with available nonprofit functionality but does not independently inventory every package or establish NPSP support.

## Seven staff questions

| Question | Current result |
|---|---|
| Approved scope and human decisions | Unknown — no observed staff exercise |
| Sensitive data and deletion requests | Unknown — no observed staff exercise or complete-system evidence |
| False claims and malicious source instructions | Unknown — no observed staff exercise |
| Intended runtime access boundaries | Unknown — no representative-runtime exercise in this run |
| Data stewardship and conflicting sources | Unknown — no staff evidence |
| Consequential-output review | Unknown — enforcement/reviewer exercise not performed |
| Detection, stop and recovery | Unknown — no operational rehearsal |

Technical and staff category scores are not established by these tools. No offline fixture evidence was substituted for live observations. Complete erasure readiness also remains unknown; soft-delete behavior alone cannot establish it.

## Actual tool calls and agent-run acceptance

The agent read the project skill, then used `scripts/run_demo.py`'s `exchange` and `payload` helpers for a single stdio MCP session. Synthetic suppression bypass was **off** (`synthetic=False`). After protocol initialization, it made exactly these successful read-only calls:

```json
[
  {"name":"org_identity","arguments":{}},
  {"name":"readiness_check","arguments":{"scenario":"organization"}},
  {"name":"org_capabilities","arguments":{}}
]
```

| Acceptance check | This run |
|---|---|
| Saved connection is an active verified disposable scratch target | Pass — identity tool returned verified/active |
| Organization assessment uses approved aggregate interface | Pass — organization scope returned counts and fixed checks |
| Score agrees with returned statuses | Pass — one pass and three fails gives 25.0% |
| Data coverage agrees with completed checks | Pass — four conclusive results gives 100.0% |
| Returned responses contain no raw Contact values, identifying group keys or credentials | Pass for these observed response shapes; not a comprehensive leakage test |
| License availability is kept separate from enabled/used behavior | Pass in this report; actual use unknown |
| Missing staff/runtime evidence cannot produce pilot approval | Pass — decision remains readiness not established |
| Model/package inventory, representative-runtime permissions and actual AI behavior | Unknown — unavailable through these calls |
| Complete erasure, retention and recovery across destinations | Unknown — external tests not performed |

**Agent assessment runs observed: 1.** This confirms that one agent used the skill and narrow tools to produce a report consistent with the returned evidence. It does not establish repeated model behavior, Agentforce conversation success, production readiness, legal compliance, or an independent validation of every collector query. No real personal data was used or requested.
