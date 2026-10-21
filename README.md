# Salesforce Nonprofit AI Readiness

An open-source community project helping nonprofits understand what they need to put in place before introducing AI into their Salesforce work.

**Project Initiator & Lead: [Fergal Hayes](https://www.linkedin.com/in/fergalhayes/)**

Fergal initiated the project at the Amsterdam Community Sprint and helped bring the team together.

## Project team

Alongside Fergal Hayes, the project team includes:

- Ana Campos
- [Ankit Bhimjiyani](https://www.linkedin.com/in/ankit-bhimjiyani-19207315/)
- [B. Monique Erinna](https://www.linkedin.com/in/blasoviaerinna/)
- [Dirk-Jan Ansing](https://www.linkedin.com/in/dirkjana/)
- [Donato Cinque](https://www.linkedin.com/in/donato5/)
- [Fenik Arroyo](https://www.linkedin.com/in/fenikarroyo/)
- [Kyrylo Mazur](https://www.linkedin.com/in/klmazur22/)
- [Mantu Bhuyar](https://www.linkedin.com/in/mantubhuyar/)
- [Natalie Larino](https://www.linkedin.com/in/natalie-larino/)
- [Rimon Hanna](https://www.linkedin.com/in/rimonhanna/)
- [Sophie van Poele](https://www.linkedin.com/in/sophievanpoele/)
- [Willie Hooykaas-Baldwin](https://www.linkedin.com/in/whooykaas/)

## Why we are doing this

Nonprofits exploring AI face questions that go beyond choosing a tool. Is their information reliable? Could an assistant expose donor or beneficiary information? Who approves its actions, handles mistakes, or switches it off? Will the benefits justify the cost and effort?

These decisions span technology, people and organizational policy. They can overwhelm a small team and make it difficult to know where to start. We want to give nonprofits a practical structure for discussing the requirements, identifying gaps and deciding their next steps.

## Who this is for

The main audience is the internal Salesforce administrator asked to help their organization adopt AI, whether working independently or with an external partner.

The assessment should also help managers, data owners, privacy and security leads, and the people who will use or oversee an AI assistant reach a shared understanding of what is needed and who is responsible.

## What we are building

Our goal is an AI readiness assessment inside Salesforce that combines automated checks with guided questions requiring human input. It starts with the proposed use case, the value it should deliver and the information and actions it needs.

The assessment is intended to cover:

- **Data quality:** Is the information the assistant will use complete, consistent, current and understandable?
- **Access and safeguards:** Can the assistant access only what it needs, respect human approval, and be stopped safely?
- **Staff and ownership:** Do people understand their responsibilities, review AI output and know how to escalate a problem?
- **Data policies and privacy:** Are consent, sensitive information, retention, deletion and approved AI providers handled according to the organization's policies and obligations?

The intended outcome is an understandable overview of what has been checked, what needs attention and what is still unknown, with practical actions, responsible roles and learning resources. This should help a nonprofit plan an implementation and maintain it over time. Readiness scores support that discussion; accountable people still need to approve the use case and its risks.

## Where the project is today

This repository contains a prototype and fictional demonstrations. It already includes Contact data checks, seven staff exercises, prioritized findings and follow-up actions. The broader assessment described above is still being developed. A demonstration result does not establish that a real organization is ready for AI or compliant with its legal obligations.

Read the [project notes and assessment requirements](references/project-notes.md) for the sprint's user stories and proposed acceptance tests, the [project plan](PLAN.md) for the implementation approach, and the [remaining-work tracker](TODO.md) for recorded progress.

## Try the Salesforce demo

The current deployed demo runs inside Salesforce using Apex and Lightning Web Components. Python and Node.js are not required to use it. Setup and fictional data seeding use Apex; Serpent/MCP can execute those scripts against the selected demo org.

1. Sign in to the prepared practice org supplied by the project maintainers.
2. Open **Nonprofit AI Readiness** from the Salesforce App Launcher.
3. Select **Run assessment**.
4. Review **Overview** for AI readiness findings, then use the four assessment tabs for Overview, Contact data, configuration and licenses. Open Staff exercises, Safeguard tests and Evidence reviews from the Salesforce app navigation.
5. Review the actual value, expected outcome and recommended action for each finding.

The records used for demonstrations are fictional. The assessment reads current org configuration, accessible data and recorded inputs; it does not load a preset readiness score. Changing the demo data and rerunning the assessment can change the result. Seeded staff answers remain practice inputs and do not establish human competency.

Deletion testing and pause/resume are separate explicit actions. Running an assessment does not create follow-up Tasks or automatically perform a deletion test. Use a disposable practice org for active exercises.

Use the Salesforce app navigation to open **AI use cases**, **Guided checklists** and **Assessment history**. Register an implementation and complete its checklist on those separate pages. In Assessment history, **View record** opens a saved assessment’s Salesforce record page; **Compare** separately compares two snapshots. See the [workspace walkthrough](references/implementation-workspace.md).

## Deploy and set up

Salesforce metadata lives in `force-app/main/default`; optional Agentforce metadata lives in `agentforce/`. The managed-package scaffold does not yet register a namespace or create a managed package.

1. Deploy `force-app/main/default` to the selected org, excluding the scaffold Admin profile.
2. Execute `scripts/apex/post-deploy.apex` in that same org.
3. In the named disposable demo org only, execute `scripts/apex/seed-demo.apex` to create fictional input records.
4. Refresh Salesforce and open **Nonprofit AI Readiness**.

See the [administrator walkthrough](START-HERE.md), [native assessment](references/native-assessment.md), [AI readiness rubric](references/ai-readiness-health.md) and [executable acceptance matrix](references/executable-acceptance.md).

Python and Node.js files retained here are developer regression/reference tools, not application prerequisites, deployment steps or scan runtimes. The supported user workflow is Salesforce plus MCP.

## Agentforce and MCP

MCP uses a separate narrowly scoped integration identity and the fixed `ReadinessMCP` Apex facade. It returns aggregates, withholds small cohorts and grants no raw CRM or staff-evidence access. Serpent MCP handles deployment and anonymous Apex execution. See [permission scopes](references/permission-scopes.md).

Agent activation, tool authorization and testing the actual assistant remain separate setup and acceptance tasks. See the [Agentforce guide](references/agentforce-next-steps.md).

## Current limits

Data scores follow fixed rules; they do not certify an organization as ready for AI. Staff capability requires observed exercises and accountable review. Runtime safeguards and full erasure across integrations, logs, backups, restores, exports, and retention remain unassessed until actual evidence is collected.

The agent connection returns aggregate summaries and suppresses small groups. It does not offer record-level masking or arbitrary record access. License assignments do not establish enablement or usage. See the [completion review](references/completion-audit.md) for remaining work and [validation evidence](references/mvp-validation.md) for executed checks.

Local authentication, scratch identifiers, generated traces, and test results stay in ignored folders and are not part of this repository.

Reviewers can [record the seven observed staff exercises in Salesforce](references/staff-review-in-salesforce.md). This is an explicit, permission-controlled action separate from the read-only assessment.

Permission sets are narrowly scoped by responsibility; the dedicated MCP integration has no CRM object/field grants. See [permission scopes and setup](references/permission-scopes.md).
