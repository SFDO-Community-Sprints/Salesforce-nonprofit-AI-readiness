# Salesforce Nonprofit AI Readiness

**Project Initiator & Lead: Fergal Hayes**

Fergal initiated the project at the Amsterdam Community Sprint and helped bring the team together.

Assess nonprofit AI readiness with repeatable Salesforce data checks, seven staff exercises, clear priorities, and practical follow-up actions.

This project includes a Salesforce results page, a restricted read-only agent connection, an Agentforce assessment agent, fictional demonstration data, and automated tests. The current demonstration uses Nonprofit Cloud Fundraising in disposable scratch orgs. NPSP requires separate validation.

Start with the [Salesforce administrator walkthrough](START-HERE.md), [project plan](PLAN.md), [remaining-work tracker](TODO.md), or [demonstration guide](demo/GUIDE.md).

## Project team

Alongside Fergal Hayes, the project team includes:

- Ana Campos
- Ankit Bhimjiyani
- B. Monique Erinna
- Dirk-Jan Ansing
- Donato Cinque
- Fenik Arroyo
- Kyrylo Mazur
- Mantu
- Natalie Larino
- Rimon Hanna
- Sophie van Poele
- Willie Hooykaas-Baldwin

## Try the fictional examples

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
