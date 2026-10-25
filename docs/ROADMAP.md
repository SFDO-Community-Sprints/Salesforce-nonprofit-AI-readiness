# Roadmap

## Phase 1: demo (this repo)

- [x] Data model, check catalogue as custom metadata, permission set, app and tabs
- [x] Org scan with 28 automated checks
- [x] Company, Org and Implementation checklists
- [x] AI integration user checks per use case (effective permissions analysis)
- [x] Data quality checks scoped to grounding fields (fill rate, picklists, freshness, free text, coded values in text fields, look-alike fields, field descriptions)
- [x] Staff readiness: named roles, process ownership (imports, deduplication, data feeds, knowledge, access and leavers, subject requests, AI output) and escalation (handover, log review, data exposure)
- [x] Home dashboard matching the mockup
- [ ] Fact-check every check, threshold and resource link; replace `TBD` resources (Trailhead, legal, the Loom video on least-privilege agent users)
- [ ] Community beta feedback round

## Phase 2: beta package

- **Queueable scan.** Run the org scan asynchronously (one check per job if needed) and notify the page, so large orgs don't hit governor limits. COUNT queries on very large objects need batching or sampling.
- **Tooling and Metadata API checks**, which need a Named Credential to the org's own API:
  - Security Health Check score and risks
  - Remote site settings and CSP trusted sites
  - Validation rules on key donor fields (automates O05)
  - Duplicate rule actions, block or alert (automates O07)
  - Whether duplicate rules block or only alert (extends A21)
  - Connected app OAuth policies (admin-approved users only)
- **Agentforce analysis:** topics and actions per agent, the objects each action touches, and comparison with the use case scope. Data Library contents, curator and last review (automates I11).
- **Workflow scan:** find mundane, time-consuming tasks that could be automated with AI, based on current flows, approval processes and manual task volumes.
- **Score history:** trend of score and coverage over time, plus packaged reports and a dashboard.
- **PDF export** of an assessment for management, board and DPO.
- **Trailhead modules** linked from each step for teams doing the project in-house.
- **Partner hand-off:** export the open items as a work list for a partner or consultancy.

## Phase 3: AppExchange

- 2GP managed package with a namespace in FinDock's Dev Hub; promote released versions for the community beta.
- Security review (free app), then an AppExchange listing through the Salesforce non-profit programme.
- Push upgrades for new checks through custom metadata.
