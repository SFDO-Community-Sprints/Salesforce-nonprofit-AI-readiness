# Live assessment inside Salesforce

Every displayed assessment is calculated from current org records/configuration. No selector loads expected-result fixtures or cached scores.

| Area | Current input | Collector |
| --- | --- | --- |
| Contact data quality | Accessible Contact aggregates for the selected scope | NonprofitAIReadiness |
| Product inventory | Accessible license assignments and feature availability | NonprofitAIReadiness.capabilityInventory |
| Activity freshness | LastActivityDate aggregates and explicit approved policy | ReadinessDataFreshness |
| Access configuration | Actual readiness role CRUD/FLS, API flags, custom permissions and class grants | ReadinessOrgChecks |
| Privacy configuration | Actual staff-reader, MCP and evidence-reviewer grants | ReadinessOrgChecks |
| Staff practice | Stored raw answers, actions and reviewer fields, evaluated each request | ReadinessStaffReview |
| External controls and erasure | Explicitly recorded evidence references and observed outcomes | ReadinessEvidence |

The configuration score is versioned separately as org-configuration-v1. Scores mean passed/applicable configuration checks; coverage means measured/applicable. Denied metadata access remains unknown. Configuration roles do not prove effective user privileges, runtime approvals/export/stop or end-to-end erasure. The UI names this measured scope.

The seed creates actual practice Contacts and raw staff answer records. It never creates a score or expected assessment. Seeded practice provenance is retained and visible; real recorded reviews override practice input. Old preset-result snapshots are retired. Offline Python fixtures remain developer test oracles, not production assessment inputs.

The post-deployment script assigns the current demo user the three focused UI roles; MCP, agent and follow-up privileges stay separate. Run setup and seed separately to avoid mixed setup/data DML. Neither script creates an overall readiness pass.
