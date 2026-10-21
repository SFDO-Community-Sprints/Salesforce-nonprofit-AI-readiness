# AI implementation workspace

The app uses standard Salesforce app navigation for **AI Readiness**, **AI use cases**, **Guided checklists**, **Assessment history**, **Staff exercises**, **Safeguard tests** and **Evidence reviews**. AI Readiness keeps four assessment panels: Overview, Contact data, Package configuration and Licenses and features. All collection, validation, persistence and scoring run in Salesforce. No Python service or local runtime is required to use these features.

## Start with a use case

Open AI use cases from the app navigation, choose New implementation, and expand Implementation purpose, scope and responsibility. Record a name, business owner and purpose. Add the actual integration username when known, allowed/excluded actions, selected `Object.Field` grounding fields, value, success measures, risks, mitigation, handover, stop owner, costs/gains and accountable approver. Save before running a scoped assessment.

The integration username resolves to a real visible Salesforce user only with the separate Security Reader role. It does not impersonate that account. Data aggregates run with the scanning user's accessible records and fields. Intended-account configuration and actual assistant behavior remain distinct evidence.

Use at most 12 grounding fields across three accessible queryable objects. Optional completeness and maximum-record-age thresholds require explicit policy approval and a recorded policy reference. No threshold is selected automatically. Scope/rubric identity is saved with each scan, so changes warn against direct score comparisons.

Business lifecycle approval is a decision, not a readiness result. An Approved implementation can still have failed or unknown checks.

## Guided governance

Open Guided checklists from the app navigation. Company, Org and Implementation checklists have short stages and contextual advice. Company and Org answers are shared across the implementation choices within the viewer's authorized record scope; implementation answers are attached to the selected use case. Private record sharing controls what each reviewer can read or change.

Answers are Yes, Partially, No or Not sure. Yes requires a responsible person/role, evidence reference and review date. A partial policy is not a pass; Not sure remains unknown. Notes, due dates, evidence and reviewer/time are retained. Filters show overdue and unassigned gaps. Each save appends a new answer instead of rewriting earlier evidence.

These are reported policies and responsibilities. They have separate finding identifiers and never replace an executed safeguard result. Keep using the seven Staff exercises for observed competency. A policy answer does not establish legal compliance or full-team readiness.

The use-case editor groups setup/access and value/risk/handover into separate sections. Required fields are marked, and opening a registry row moves focus to its editor. Save before switching Salesforce app tabs or refreshing: unsaved edits are kept only on the current page. Company and Org checklists do not require an implementation selection; the selector appears for Implementation scope. Empty gap filters offer Show all questions in this stage without clearing drafts.

History timestamps include time, comparison outcomes use plain-language labels, and Clear comparison resets only the displayed pair. History shows up to 30 recent accessible assessments. Seeded staff input is labelled as practice-answer completion, not evidence of staff competency.

## Findings and history

Overview retains the health score, coverage and AI readiness findings. Filter by result, severity and category, expand a category or its advice, and use Answer in checklist to reach the exact manual question. Filter counts never change the full report's denominator. Actual and Expected columns retain equal widths. Changing governance marks the displayed scan as needing a rerun; saving an answer does not silently execute a new scan.

With Assessment Recorder, organization and scoped scans save sanitized, versioned snapshots. Open Assessment history from the app navigation to review them. Its standard Salesforce table includes run identifier, actor, observation time, scope, rubric, totals, score and coverage. The implementation selector filters the list; it does not edit a use case.

**View record** opens the selected assessment's native Salesforce record page. Its standard record layout displays the stored scope, rubric, observation time, source, score, coverage and passed/failed/unknown counts as real fields. A read-only Findings component on that record page displays the immutable report's findings in a standard Salesforce table, including actual/expected values and next actions. This is a stored snapshot, not a new scan or an implementation edit form. Exact-question checklist links remain available in the assessment Overview.

**Compare** is a separate action for selecting two saved assessments in the history page. Comparing a scan with itself is blocked; scope or rubric changes produce a warning. Review and scan age are observations, not an invented expiry policy. Rerun for current evidence. A saved scoped scan can also open the assessment Overview with its saved findings; if a report cannot be saved, it stays visible on the use-case page.

Existing snapshots can have their new record fields populated by the guarded, idempotent hydration operation. It derives those fields from the saved report and does not change its original JSON, scoring, scope or observation time.

Snapshots contain no raw donor records, emails, private policy notes or evidence references. Identity and policy bindings are hashed in the scope definition. Server-side guards allow creation only through the validated service and reject later edits/deletes. Answer history is also append-only; use cases are edited through validation and retired rather than deleted. This is application-level evidence protection, not protection from an administrator changing deployed code.

## Focused roles

- **Readiness Assessor:** existing read-only Contact assessment plus authorized workspace/history reads. No workspace or snapshot writes, Setup visibility, API transport or staff-evidence access.
- **Readiness Governance Reviewer:** validated use-case create/edit and append-only checklist answers. No CRM data, Setup edit, MCP, Task or assessment-recording grants.
- **Readiness Assessment Recorder:** append-only sanitized report creation/read. No report edit/delete, CRM data or security grants.
- **Readiness Security Reader:** existing separate setup visibility for intended-account and configuration checks. Denied setup access stays unknown.

The post-deploy script composes the first three with existing staff/evidence reviewer roles for its executing walkthrough user. Scratch-only active verification roles remain separate. Dedicated MCP identity assignments are unchanged.

## Collector boundaries

Scoped findings cover selected-field completeness and Other values, approved modification-age windows, supported email duplicate indicators and Account linkage, metadata descriptions/help/free text/classification inventory, and target identity grant configuration. Supported profile/direct/group aggregates are distinguished from pending recalculation or session activation. Missing metadata does not infer a pass. Counts for small cohorts and small category cells are withheld.

Configuration inventory does not demonstrate assistant allow/deny behavior, consequential approval, stopping/recovery, alert delivery or external erasure. Actual assistant and external-system acceptance remains open until those systems supply evidence. NPSP-specific semantics and unsupported parent/matching policies remain explicit rather than guessed.

## Fictional workspace inputs

After current deployment and post-deploy setup, `scripts/apex/seed-workspace.apex` optionally creates two clearly named fictional planning records in the named disposable scratch org. It is idempotent and does not overwrite existing cases. Run `seed-demo.apex` separately for the existing fictional Contact inputs. No integration identity, policy approval, staff demonstration, checklist pass or score is seeded. Assessments still read live data/configuration.

## Executed validation, 21 October 2026

- Full metadata compiled in the validation scratch org, deployment `0AfJW00000ngWFN0A2`: 87/87 components, **96 Apex tests passed**, no failures or coverage warnings. Tests include focused nonadmin role composition, actual integration-user binding, private record isolation, unknown/partial policy states, invalid input/policy rejection, guarded append-only persistence, group aggregates and bounded collectors.
- Local contributor checks: **125 tests and nine UI behavior checks passed**. These development tools are not app/runtime prerequisites.
- Serpent **DEPLOY-41** (`6ad8aeb7c248d67a734ab098`) deployed 79/79 selected components to the named `data-connect-7516` scratch org. The scaffold Admin profile was excluded. **DEPLOY-48** (`6ad8b151e72fb8ed0317b897`) subsequently deployed the two-bundle correction separating scoped findings from organization recommendations.
- Post-deploy setup succeeded through Serpent MCP (`6ad8af66e72fb8ed0317b88c`) after an initial credential-in-use failure. The dedicated MCP role and Task permissions were not assigned. Workspace seeding (`6ad8af8f11779d540cecfc06`) created exactly two fictional planning records.
- Serpent live readback (`6ad8b045eeb03c7ac01a61d6`) confirmed two use cases, two saved reports and 19 governance questions. Live acceptance (`6ad8b1dbeeb03c7ac01a61d8`) confirmed repeat seeding creates zero records, the browser-saved unknown answer and its due date persist, forged snapshots/edits are denied, a new scan appends a sanitized report, the earlier snapshot remains byte-for-byte unchanged, and unknown policy remains unknown. The selected donor-summary scan produced 61 scoped findings; no readiness pass is inferred from that count.
- Native desktop interaction confirmed the new tab, organization and scoped scans, outcome filtering (51 of 61 findings shown without changing the denominator), exact checklist navigation/focus, unknown-answer save, and overdue filtering. Browser QA used native computer control because the Browser plugin was unavailable.

These are application/scratch evidence. Actual assistant allow/deny/approval/stop/alerts, external erasure, customer policy approval, genuine staff competency, production and NPSP-specific acceptance remain separate. Mobile and actual assistive-technology operation were not established by this validation.

Final history contract check used two actual saved reports read through Serpent MCP (`6ad8b498c248d67a734ab0b3`), one organization and one implementation report. The existing UI controller loaded their actual JSON, preserved 46/61 findings and all totals/IDs/dates, displayed grounding scope, and warned against cross-scope score comparison. This verifies the live backend/UI data contract; a complete browser comparison flow was not observed. The workspace history controls themselves were inspected in the rendered desktop app.

Serpent metadata retrieve `6ad8b45ec248d67a734ab0ad` completed without saving changes to Git; it returned the workspace files and no diff for the requested parent/workspace JavaScript paths. An existing Lightning tab retained a stale action state after deployment, so older open tabs may require a cache-only hard reload. No browser security settings or sign-in cookies were changed. Workspace listing is bounded to the latest 100 accessible use cases, 2,000 answer versions and 30 reports per load; saved records remain in Salesforce.

## Standard app navigation correction

Use-case registration, guided checklists, saved history, staff exercises, safeguard tests and evidence reviews now have their own standard Salesforce app tabs. They are no longer embedded inside the assessment's local result tabs. Findings link to the exact checklist question through Salesforce page state; saved scoped reports route back to AI Readiness Overview by assessment identifier. Unsaved report results remain on the originating page.

Local controller checks cover route state, delayed child rendering, ignored stale history responses, the four result tabs, exact question targeting and the unsaved-report fallback. Earlier rendered evidence above covers the prior embedded layout. Serpent DEPLOY-55 deployed the navigation correction (29/29 components, job `0AfPw00000asDMvKAM`). A live scoped run opened Overview with its saved assessment ID, four result tabs and an enabled findings shortcut. The security-owner finding opened the Company checklist and focused its exact question. The subsequent standard history-table and white-card update was deployed through DEPLOY-58. The native assessment record layout and its findings component were subsequently delivered and verified in DEPLOY-61, as recorded below. Mobile and assistive-technology behavior are not established by controller tests.

## Native saved-assessment record acceptance

The record layout, real snapshot fields, guarded hydration, View record navigation and the separate comparison workflow require deployment and focused record-page checks. Verify a new report and an older hydrated report, confirm their stored JSON remains unchanged, check read-only role access, review the saved findings and their next actions, and distinguish View record from Compare. Do not treat prior history cards or the earlier custom accordion as proof of the native record layout.

For existing scans, run `scripts/apex/upgrade-assessment-records.apex` after deployment, separately from the role-assignment script. Each run fills at most 100 owned, accessible records from their original stored reports; repeat until zero are updated. The immutable saved report is preserved, and no edit permission is added to the Recorder role. New scans populate their native fields automatically.

## Combined delivery, 21 October 2026

Community source `70adfbe` and its private shared-tree mirror were deployed to `data-connect-7516-dev-ed.scratch.my.salesforce.com` through Serpent **DEPLOY-61** (`6ad8c176e5bc38620ad5f1e0`), Salesforce job `0AfPw00000as8jqKAA`: 24/24 components, zero failures. No Admin profile was selected.

Validation: 107 components compiled without errors; 97 Apex tests passed in the validation org, including role boundaries, original evidence protection and idempotent projection hydration. The contributor suite passed 126 tests and ten UI checks. These tools are development checks, not application prerequisites.

Desktop Salesforce evidence:

- Overview has a compact white Salesforce header and the dedicated integration-user warning. Register an AI connection opens the expanded blank registration form in the Use Cases app tab.
- The portfolio shows both fictional implementations with separate business lifecycle and measured results. The donor case had its actual saved 9.8%/16.4% report; the other case explicitly had no recent saved scan. No readiness values were seeded.
- History uses a standard datatable with saved-by actor and spacing below its implementation filter. View record opened the actual `/lightning/r/Readiness_Assessment__c/.../view` page. Native fields showed the real scope, rubric, timestamp, score, coverage and 6/4/51 totals; saved findings appeared below in a standard datatable.
- Compare selected an implementation baseline and an organization scan; the UI warned that scopes differ. Choosing the same scan twice was rejected.
- Company checklist progress showed 0/7 answered, 7 unknown/unanswered and a 0/3 stage count from actual saved data. Navigation did not save answers.
- A new real organization scan showed the actual recorded actor and Observed just now, alongside time/source/scope and approved-review-policy guidance. The earlier exact security-owner finding link had opened and focused its Company checklist question.

Serpent upgrade action `6ad8c1d032dc4b9678c42f2d` successfully populated eight owned existing records. Repeating hydration changed zero records; hashes verified every original Report/Summary remained unchanged. Acceptance action `6ad8c2f1589ff9983b3a5969` verified new native metrics match the saved report, UI actor is excluded from stored reports, actual actor lookup is correct and a forged score update is rejected. Both anonymous Apex actions compiled and completed successfully.

The administrator browser session showed standard inline edit affordances; server guards reject saved evidence/metric changes. Focused Recorder object edit remains disabled. A complete target-org browser walkthrough for each focused role, mobile and assistive-technology checks remain separate. Prior browser-console inspection showed Salesforce O11Y/beacon telemetry errors; no component error overlay was observed in the delivered workflows. This is desktop component evidence, not organizational readiness or real-assistant/external-erasure acceptance.

Finding categories use standard Salesforce tabs with the filtered count in each header. All findings remains available; Result and Severity filters update every tab count without changing the score or coverage. Categories with no matches stay visible with a zero count.

Finding filters use native Lightning comboboxes and a Lightning Clear filters button. Each category uses a standard Lightning datatable with equal initial widths for Actual and Expected values. The row menu opens View details and next steps, including the explanation, approved recommendation link and applicable checklist action.
