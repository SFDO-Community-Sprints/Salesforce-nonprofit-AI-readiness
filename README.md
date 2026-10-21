# Salesforce Nonprofit AI Readiness

An open-source community project helping nonprofits understand what they need to put in place before introducing AI into their Salesforce work.

**Project Initiator & Lead: [Fergal Hayes](https://www.linkedin.com/in/fergalhayes/)**

Fergal initiated the project at the Amsterdam Community Sprint and helped bring the team together.

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

## Try the fictional examples

For administrators and contributors: the prototype includes a Salesforce results page, a restricted read-only agent connection, an Agentforce assessment agent, fictional demonstration data, and automated tests. The current demonstration uses Nonprofit Cloud Fundraising in disposable scratch orgs. NPSP requires separate validation. Start with the [administrator walkthrough](START-HERE.md) or [demonstration guide](demo/GUIDE.md).

Requires Python 3 and Node.js. No Salesforce login is needed for these examples.

```sh
python3 scripts/demo_failures.py
python3 scripts/check_all.py
```

The examples demonstrate different scores, failed safeguards, staff training gaps, and erasure problems with prioritized next steps. All staff and safeguard examples are clearly labelled simulations.

## Use a practice Salesforce org

Use an authenticated Salesforce CLI and a Dev Hub that supports the requested scratch features. Follow the [setup guide](demo/GUIDE.md) to create, seed, and deploy the disposable practice org. Never run the seed or active test exercises against customer or production data.

```sh
python3 scripts/scratch_demo.py create --hub YOUR_DEV_HUB --alias nonprofit-readiness-demo
python3 scripts/scratch_demo.py seed
python3 scripts/scratch_demo.py deploy
python3 scripts/check_all.py --live
```

Open **Nonprofit AI Readiness** from the App Launcher. **Run assessment** reads accessible Contact summaries; creating follow-up Tasks is a separate explicit action. The live test command adds fictional failure records, temporarily corrects and restores them, and creates and soft-deletes one fictional record.

## Agentforce

The [Agentforce setup guide](references/agentforce-next-steps.md) describes the separate Agentforce-enabled scratch environment and the single read-only assessment action. Live authoring-preview checks and activated-agent conversation checks are included. Prepare the second practice org with `python3 scripts/setup_agentforce_demo.py --hub YOUR_DEV_HUB`, then run `python3 scripts/check_agentforce_action.py`. Preview success, publication, activation, and verified conversations remain separate evidence.

## Current limits

Data scores follow fixed rules; they do not certify an organization as ready for AI. Staff capability requires observed exercises and accountable review. Runtime safeguards and full erasure across integrations, logs, backups, restores, exports, and retention remain unassessed until actual evidence is collected.

The agent connection returns aggregate summaries and suppresses small groups. It does not offer record-level masking or arbitrary record access. License assignments do not establish enablement or usage. See the [completion review](references/completion-audit.md) for remaining work and [validation evidence](references/mvp-validation.md) for executed checks.

Local authentication, scratch identifiers, generated traces, and test results stay in ignored folders and are not part of this repository.

Reviewers can [record the seven observed staff exercises in Salesforce](references/staff-review-in-salesforce.md). This is an explicit, permission-controlled action separate from the read-only assessment.

Permission sets are narrowly scoped by responsibility; the dedicated MCP integration has no CRM object/field grants. See [permission scopes and setup](references/permission-scopes.md).
