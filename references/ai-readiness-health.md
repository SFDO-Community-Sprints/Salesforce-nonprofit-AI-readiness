# AI readiness health check v1

This is our own native Apex health check, not Salesforce Security Health Check. `ReadinessOrgHealth.scan()` is shared by the Lightning dashboard and the invocable MCP/agent action **Scan AI Readiness Health**. It reads org data/configuration, executes fixed package boundary probes and evaluates current evidence. No Python service, external callout or Salesforce-to-itself credential is required.

## Rubric and findings

Every check contributes one point when passed. Score = passed / all defined checks × 100, rounded half up to one decimal. Unknown checks earn no points. When no check in a category is measurable its score is null, shown as Not checked. Coverage = (passed + failed) / all defined checks × 100. Inventory counts are excluded. Critical failures display a blocking banner irrespective of score. Scores are scoped evidence, not automatic pilot approval.

- **Data quality:** four current organization Contact checks plus an explicit unmeasured approved freshness-policy check. Contact counts below five remain withheld. This health overview always assesses organization scope; the existing Contact selector controls the detailed data section.
- **Access and safeguards:** four fixed org-wide grant checks, four executed current-user package checks, and five explicit intended-assistant/workflow gaps. Non-administrator profiles are defined as profiles without Modify All Data. Broad grants outside those profiles require review; legitimate approved exceptions are not silently inferred. These are grant findings, not a full effective-access graph or proof of restricted assistant access.
- **Staff readiness:** seven versioned exercises from the existing answer key. Only the current user's confirmed real reviews contribute pass/fail outcomes. Seeded practice answers contribute unknown to human readiness. Critical observed staff failures remain blocking. No whole-team conclusion is inferred.
- **Privacy and erasure:** own latest source-exclusion and Recycle Bin observations within the last 24 hours, plus unmeasured integrations, logs, backups, exports, agent output and retention. The scan never creates/deletes a canary automatically. Run the separate confirmed scratch erasure exercise to collect observations. The 24-hour technical observation window is part of this rubric; it does not approve an organizational retention policy.

Detailed rows show severity/result, check, category, actual observation, expected outcome and an action. Links are restricted to fixed Salesforce Setup pages or this app. Org access inventory shows active users, administrator-profile users, unassigned permission sets and unused roles without treating small assignment counts or empty roles as failures.

## Permissions and execution

Readiness Assessor can open the dashboard and collect its existing data/current-user checks. The separate **Readiness Security Reader** grants only the health collector, its custom permission and read-only Setup/roles/users visibility, with no CRM object grants, API transport or security-edit privileges. Missing Setup access produces unknown grant findings. In a scratch org the post-deploy script assigns this role separately; production requires explicit specialist assignment.

The original restricted MCP aggregate role is unchanged. To expose AI readiness health to an authorized tool identity, expose the invocable `ReadinessOrgHealth.invoke` action and compose the specific reader roles needed for data or staff scope. Do not give the existing API-only aggregate MCP identity broader roles without explicitly changing its connection contract.

A scan writes only fixed-vocabulary sanitized runtime events. It never creates Tasks, changes configuration, or performs an erasure exercise. Package stop gates the health scan too. No names, raw emails, staff evidence references, credentials, or donor records are returned by the report.

## Live verification — 20 October 2026

Serpent DEPLOY-26 (`6ad7517419614192da1f9a1d`) deployed 63/63 components successfully to `data-connect-7516-dev-ed.scratch.my`. Scratch post-deploy completed, and the separate Security Reader custom permission was verified before scanning. MCP execution (`6ad751d745aea17b84c08d39`) compiled and succeeded, exercised a new disposable canary and checked the native report.

Observed result: **24.2% score, 39.4% coverage; 8 passed, 5 failed, 20 unmeasured across 33 defined checks**. Data 40%/80% coverage; access 38.5%/53.8%; staff not checked/0%; privacy 12.5%/25%. Actual grant queries found one non-administrator-profile user with broad read and one broad permission assignment, zero broad-access or export-capable guest users. Inventory observed seven active users, one administrator-profile user, three unassigned permission sets and 18 roles without active users. These counts are observations, not evidence of usage or automatic reasons to delete metadata.

Active canary exclusion passed and permanent erasure failed because it remained recoverable. No existing Contact was selected or purged. The browser Run assessment displayed the same score, category counts, detailed actual/expected rows and scope limitations. Desktop cards and table were visually inspected. No production, mobile, intended assistant identity, external destination or human competency acceptance is claimed.

Validation: 84 Apex tests passed with full metadata; five focused native health tests passed after enforcing user-mode saved-observation access. All seven Node UI checks passed. No Salesforce Health Check, Named Credential or external runtime was configured or required.

Final action/sorting corrections deployed through Serpent DEPLOY-30 (`6ad752ac70293efa66e52603`): 63/63 components, no failures. MCP readback (`6ad752ffada4f4e411b23319`) compiled and succeeded, asserted the Contact action URL and returned unchanged totals. After a cache-only hard reload of Salesforce assets (sign-in retained), the native browser showed high-severity failures before medium ones and Contact findings linked to `/lightning/o/Contact/list`. No final UI cache limitation remains in the verified desktop session.

## Category tabs — 20 October 2026

Serpent DEPLOY-34 (`6ad758169aee7ce85c4bc303`) deployed both updated Lightning bundles successfully (2/2 components), including the prior equal-width Actual/Expected columns. Overview retains AI readiness findings and recommended actions. Contact data, package configuration, licenses/features, verification, evidence/freshness and staff exercises have separate panels. Panels remain mounted so switching categories retains results and unsaved form inputs.

Validation: Salesforce compiled the parent component in the validation scratch org; all eight Node checks passed, including selected-tab state and keyboard navigation. Live desktop inspection verified the Overview findings, isolated Contact summary/checks, retained staff answers and View recommended actions returning to Overview and focusing its heading. Mobile tab interaction was not checked.

## Implementation workspace extension, 21 October 2026

The current public scan adds separately identified Company/Org governance findings and uses rubric `ai-readiness-health-v2`. Scoped implementation scans replace organization Contact rows with the selected grounding collectors, retain explicitly shared configuration and current-user evidence, and add implementation policy findings. Reported policy passes never replace actual safeguard gaps. Organization and scoped denominators differ by design; each report stores its scope definition and rubric. Existing October 20 results above remain historical v1 evidence, not current v2 scores. See the [workspace guide](implementation-workspace.md).
