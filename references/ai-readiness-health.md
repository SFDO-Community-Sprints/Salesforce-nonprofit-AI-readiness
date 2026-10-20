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
