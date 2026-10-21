# Salesforce AI readiness app and MCP

The supported application is self-contained Salesforce metadata in `force-app/main/default`. Setup and demo seeding run as anonymous Apex in Serpent. Scanning, scoring, staff review, runtime probes, operational logs and stop/resume run inside Salesforce. No local runtime or Python process is required.

## Deploy and open the app

1. In Serpent, deploy `force-app/main/default` from this repository to the selected org. Exclude the scaffold Admin profile.
2. Execute `scripts/apex/post-deploy.apex` on that same org. It idempotently assigns the executing user the separate Assessor, Governance Reviewer, Assessment Recorder, Staff Reviewer and Evidence Reviewer roles. In a scratch org only, it also assigns Erasure Tester, Control Manager and Operations Reader. It never assigns MCP or follow-up Task permissions.
3. Refresh Salesforce and open App Launcher → **Nonprofit AI Readiness** → **AI Readiness** (`/lightning/n/AI_Readiness`).
4. Choose **Run assessment**. Data and configuration come from the current org; runtime probes execute as the signed-in identity. Small Contact cohorts are withheld.
5. Complete the seven staff exercises with actual observations. Seeded practice answers cannot establish human competency.

The optional Follow Up role permits explicit Task creation; running a scan never creates follow-up Tasks. Freshness requires an explicitly approved policy. Configuration checks, executed probes and reported evidence retain separate scopes. A good partial score never approves an AI pilot.

## Connect MCP

Create a dedicated Salesforce API-only integration identity in Setup and assign only **Readiness MCP**, with the platform transport permissions required for that identity. Configure the Salesforce connection in the MCP host using that identity. Do not reuse the assessor or administrator connection. The Apex `ReadinessMCP` facade returns fixed aggregate results, suppresses groups below five, and exposes no raw Contact or staff evidence access. See [permission scopes](references/permission-scopes.md) for the precise supported identity boundary.

Serpent MCP is the deployment and anonymous-Apex execution interface. The readiness facade is the restricted assessment interface. Neither requires the old local Python runner to assess this org.

## Practice data through Serpent

Deploy the latest metadata, then run `scripts/apex/post-deploy.apex` followed by `scripts/apex/seed-demo.apex` on `data-connect-7516-dev-ed.scratch.my`. Setup assigns the current demo user the separate assessor, staff-reviewer and evidence-reviewer roles. Refresh Salesforce afterward.

The seed creates five Accounts and 34 Contacts with different actual completeness/duplicate patterns, plus raw practice answer records for the staff rubric. It inserts no scores, expected results or claimed control-test passes. The assessment reads the current records and configuration on every run. Select All accessible Contacts or an individual demo-record group to change the live Contact query scope. Creating follow-up Tasks remains organization-only.

Inside the seed script, `practiceScenario` selects the raw answer inputs to install: poor, improving, pilot, blocked or unknown. Re-running with another input set updates only the explicitly marked practice answer record. A real user-entered review always takes precedence. Practice answers are labelled as test input records and do not establish observed human competency. Existing old preset-result records owned by the current user are soft-deleted; real reviews are untouched.

`seed-failures.apex` optionally adds 60 actual fictional unlinked Contacts, 50 missing email and ten sharing one fictional email. That intentionally lowers the live organization data score. Both scripts are pinned to the selected scratch hostname and refuse other targets before writes. Repeat runs avoid duplicate Contacts; altered or incomplete original Contact seeds cause refusal rather than overwrites.

Access and privacy configuration cards inspect deployed readiness permission sets, their CRUD/FLS, custom permissions and class grants. These are configuration measurements; they do not establish runtime approval/export/stop behavior, effective user access or full erasure. External evidence and actual staff observations remain separately reviewable.

## Execute acceptance checks

Run assessment also executes current-identity permission/API probes and writes sanitized operational events. Review **Executed verification** for each observed result and missing runtime binding. This does not substitute the signed-in administrator for an assistant identity.

The separate **Run source erasure exercise** button requires explicit confirmation and the scratch-only Erasure Tester role. It creates and soft-deletes one new fictional Contact, observes active-read/count exclusion, and reports retained Recycle Bin data as a failed permanent-erasure check. It never purges data. The package stop/resume controls require Control Manager; Operations Reader exposes the sanitized event list. These three roles are assigned by post-deploy only in a scratch org.

See [executable acceptance](references/executable-acceptance.md) for the exact implemented checks and required external/identity bindings. Runtime, source lifecycle, configuration and human evidence remain distinct; no overall pass is inferred from a partial probe.

## AI readiness health dashboard

**Run assessment** now also runs our own AI readiness health check: an overall score and coverage, four category cards, access inventory and actionable actual-versus-expected findings. It does not import Salesforce Security Health Check. Unknown evidence earns no score points and critical failures block the result. See the [rubric and exact scope](references/ai-readiness-health.md).

Assign the separate **Readiness Security Reader** role for the org-wide grant checks. Existing Assessor access does not gain Setup visibility. Scratch post-deploy assigns that specialist role separately. No Named Credential or external runtime is needed.

Results are grouped into tabs. **Overview** keeps the AI readiness health cards, findings and recommended actions. **Contact data** contains the selected cohort summary and data checks. Package configuration, licenses/features, executed verification, evidence/freshness and staff exercises each have their own tab. Switching tabs preserves scan results and unsaved form inputs. Use left/right arrows or Home/End to navigate tabs; View recommended actions returns to Overview.

**Safeguard tests** explains each executed app check as a question, result and next step. Its results cover the signed-in account; the separate “Still to test with your AI assistant” list remains unmeasured until actual assistant evidence exists. Deletion and pause/resume are optional actions in collapsed sections. Raw diagnostic output and the audit-log link are under Technical details. A completed deletion test refreshes the Overview health report.

## Use cases, governance and scan history

Open **Use cases and checklists** to register the implementation, complete the Company/Org/Implementation stages and compare saved assessments. Overview retains the filterable health findings and direct checklist links. See the [workspace walkthrough and role boundaries](references/implementation-workspace.md).

For the named disposable scratch demo, `scripts/apex/seed-workspace.apex` adds two fictional implementation planning records without assigning an AI account or seeding any readiness result.
