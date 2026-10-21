# Combined app comparison — 21 October 2026

Compared the reference UI at `orgfarm-637ad09aa9-dev-ed.develop.lightning.force.com` with the current source in this repository. The separate local `non-profit-sprint_ai-readiness` checkout was stale and was excluded from the implementation comparison. Reference presentation is evidence of visible behavior only, not proof of its authorization, collectors or scoring.

## Navigation reviewed

| Reference surface | Observed behavior | Current implementation and remaining difference |
|---|---|---|
| AI Readiness | Concise heading; timestamp and actor; refresh-age guidance; prominent dedicated AI identity warning and Register an AI connection action; overall/category scores, coverage, critical findings with direct actions | Overview health, categories and critical gating exist. Warning/registration and standard white presentation are being corrected; verify rendered placement. UI-only recorded actor and elapsed scan age are implemented, pending deployed verification. |
| Org Scan | Saved run name, actor/time, outcome/category/critical filters, grouped findings, expandable advice and exact checklist actions | `readinessOrgHealth` already has filters, groups, advice, actual/expected/action rows and checklist links. Native saved records/history already exist. This is not an unimplemented replacement dashboard. |
| Checklists | Company/Org/Implementation scopes; responsible-person fields; staged navigation; answers, advice, notes, responsibility and due dates | `readinessWorkspace` already implements these scopes, stage selection, answers, owner/due/evidence/notes/review date, accountable-gap filters and question links. Saved-answer stage counts and assigned-person totals are implemented, pending deployed verification. |
| Implementation checklist | Identity guidance, intended integration username, user selection and scoped checks; five stages | Current registry stores intended username, approved grounding/threshold policy and stop/handover responsibility; scoped collector exists. Metadata/effective-grant observation must remain distinct from actual assistant execution. |
| Use Cases | Portfolio table: name, lifecycle, business owner, latest score, coverage, health and critical count. An Approved implementation is visibly Blocked; a second Idea is Not checked | Current implementation selector/editor and scoped scanning exist. A standard multi-implementation portfolio table is implemented, pending deployed verification; missing recent snapshots remain Not checked. |
| AI Readiness Assessments | Standard recent list; AIR-0016 details displayed only name/owner/created/modified | Current saved snapshot history, comparison and immutable reports exist. New native projection fields/read-only Findings record page are being implemented; they are more useful than copying the reference's sparse details. |
| AI Use Cases | Standard recent list and Donor FAQ agent details displayed only name/owner/created/modified | Do not reproduce sparse record layouts or assume hidden scores/policies are exposed through them. Preserve functional current editor. |

No Settings tab was present in the reference navigation. Its UI does not establish a settings feature to copy.

## Focused remaining work

1. **High — Portfolio triage.** Add a standard Lightning table to the existing Use Cases view with name, business owner, lifecycle and latest accessible scoped score, coverage, readiness state and critical count. Bind each summary to its actual implementation snapshot; unscreened implementations say Not checked. Open/edit/scan use the existing selected implementation flow. An Approved lifecycle never overrides Blocked measured readiness. Missing/inaccessible snapshots never become zero critical failures or passes.
2. **Medium — Live scan provenance.** Show who ran the displayed scan and its elapsed age next to time/source/scope, with a direct refresh action. Saved and live observations must remain distinct. Use an explicitly approved freshness policy before showing expired/stale based on age; do not import the reference's arbitrary 24-hour deadline.
3. **Medium — Guided stage visibility.** Show stage names and answered/unanswered/accountable counts for the selected Company, Org or Implementation scope. Reuse current question definitions and saved answers. A completed answer is not a passed runtime control or demonstrated staff competency. Navigation must not silently save answers; retain explicit Save answer behavior and unsaved-change guidance.
4. **Acceptance pending — Current UI corrections.** Verify native assessment record fields and read-only Findings, standard white cards, warning/registration placement, direct question navigation and scope-aware comparison in the scratch org. These components exist or are under active implementation; do not mark REF-1–REF-6 undone.

Reference Home displayed 51 defined checks (13 passed, eight needing attention, 30 not checked); Org Scan displayed 39 (11 passed, five needing attention, 23 not checked). Our versioned organization/implementation reports have different scopes and catalogs. Do not compare these global percentages or counts as equivalent coverage. Explain each selected scope and denominator.

The portfolio table, recorded actor and elapsed age, saved checklist progress, and standard Overview warning/white header are implemented. Their deployed behavior still needs verification.

## Keep our stronger boundaries

The reference passed API access with 4/5 active users enabled, broad-data access with three privileged users, temporary restriction from session-based permission-set existence, and HTTPS/no tokens from absent configuration. It failed missing muting permission sets. These are unvalidated rubric choices, not acceptance criteria. Empty metadata does not establish an absent external system, an enabled feature does not demonstrate control effectiveness, and a company policy answer is not actual runtime/human evidence. Keep measured scopes, approved thresholds, unknowns, real assistant execution, external erasure and human demonstrations separate.

## Inspection limits

All six reference navigation tabs were opened and existing assessment/use-case records viewed. No scan, answer edits, explicit Save, user binding or check execution was performed. One unedited Company **Next** click showed Working and then a completed previous stage: navigation may have persisted unchanged fields or stage progress; this audit cannot guarantee zero backend writes. Subsequent stage navigation avoided Next/Back. Backend persistence, authorization, notifications, mobile, assistive technology and reference score correctness were not tested. Legal/provider claims were not adopted.
