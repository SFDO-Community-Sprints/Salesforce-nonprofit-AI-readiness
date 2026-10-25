# AI Readiness Check (AIR)

A Salesforce app that helps an admin, and the people they work with, answer one question: **is our organisation ready to implement and operate AI, and what do we need to fix first?**

It combines:

- **An org scan.** Automated checks on sharing, permissions, integrations, guest access and data quality.
- **Guided checklists.** Questions the org can't answer for itself, such as GDPR/DPO, signed policies, LLM policy, training and travel protocols.
- **An implementation assessment per AI use case.** This includes checks against the **integration user the AI connects as** and data quality checks scoped to the fields the agent grounds on.

Everything rolls up into a readiness score, a coverage figure and a list of **critical failures** that block a pilot regardless of the score.

> Status: **demo**, deployed as unpackaged source. It is built to become a 2GP managed package later (see `docs/ROADMAP.md`).

## Screens

| Tab | What it does |
|---|---|
| **AI Readiness** | Dashboard matching `docs/mockup-home-dashboard.png`: health donut, checks completed, four category cards, critical failures. It also explains that AI must never connect as a System Administrator. |
| **Org Scan** | Runs the automated org checks. Shows every result with evidence, filters, and "why and how to fix". |
| **Checklists** | Company, Org and Implementation checklists. Company starts with the responsible people; Implementation starts with the AI integration user. |
| **Use Cases** | Register each AI connection: value, what you lose, handover points, cost vs gains, integration user and grounding fields. |

## Scoring

- **Score** = passed / all defined checks. Not-checked checks earn no points.
- **Checks completed** = (passed + needs attention) / all defined checks.
- **Health** is set by the first rule that applies:
  1. **Not checked** when nothing is measured.
  2. **Blocked** when any critical check needs attention.
  3. **Ready for pilot** when the score is 80% or higher.
  4. **Needs attention** otherwise.
- The Home dashboard covers the latest Company and Org assessments. Use cases are scored separately.

## The check catalogue

The checks are custom metadata records (`AIR_Check__mdt`): question, pass criteria, advice, resources and the Apex handler for automated checks. The source of truth is `tools/catalogue.py`. To regenerate the metadata, run:

```bash
python3 tools/generate.py
```

This regenerates the objects, fields, custom metadata records, permission set, tabs, app and FlexiPages. Apex and LWC are hand-written.

| Level | Automated | Manual |
|---|---|---|
| Company | – | 12 |
| Org | 28 | 11 |
| Implementation (per use case) | 6 AI-user + 8 data quality | 13 |

## Deploy

Prerequisites: [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) and Node 18 or later.

```bash
# 1. Authorise the org (once); use your org's My Domain login URL
sf org login web --instance-url https://<your-domain>.my.salesforce.com --alias air-demo --set-default

# 2. Deploy and run the Apex tests
sf project deploy start --source-dir force-app --test-level RunLocalTests --target-org air-demo

# 3. Give yourself access (fields deployed through the Metadata API have no FLS otherwise)
sf org assign permset --name AIR_Admin --target-org air-demo

# 4. Demo data (deletes existing AIR data first)
sf apex run --file scripts/apex/seed-demo.apex --target-org air-demo

# 5. Open the app
sf org open --path lightning/n/AIR_Home --target-org air-demo
```

## Develop

```bash
npm install --legacy-peer-deps
npm run lint        # ESLint for LWC
npm test            # LWC Jest tests
npm run prettier    # format Apex, JS, HTML, CSS
```

## Design notes

- **AI access.** AI must connect through a dedicated integration user, never as a System Administrator. Each use case stores that user (`Agent_User__c`). The implementation checks work out the user's effective permissions from its profile, permission sets and permission set groups: all-data permissions, object View All / Modify All, donor objects outside the grounding scope, sensitive (classified) fields, and API-only access. Apex can't log in as another user, so this is permission analysis, not impersonation.
- **Resilience.** All setup queries are dynamic SOQL. A check that can't run in an org (no Knowledge, no Shield, no Agentforce) shows as **Not checked**, with the reason, instead of failing.
- **Security.** Results are read and written in user mode, and setup queries are read-only. There is no `global` Apex, and there are no callouts or session IDs.
