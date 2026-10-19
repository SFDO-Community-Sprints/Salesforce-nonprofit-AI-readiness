# Customer deployment design — prerequisites, not deployment approval

The current collector accepts only the saved, verified active disposable scratch org. Do not remove scratch provenance checks, substitute a customer alias in `.local/scratch.json`, or use broad administrator credentials to turn the demo into a production service. A customer collector and approved profile are separate implementation work. The native Salesforce app also requires its own customer validation; successful scratch deployment is not approval to deploy it elsewhere.

## Decisions required before implementation

| Decision | Accountable owner | Required evidence |
|---|---|---|
| Authorized org, users and donor-summary purpose | Customer assessment owner | Explicit target org, permitted data/actions, excluded decisions, named approval |
| Nonprofit model and relevant objects | Salesforce admin | Verified Fundraising/NPSP/hybrid object/package inventory and accessible-record scope |
| Profile and policy | Assessment owner and privacy lead | Versioned required fields, thresholds, freshness meaning/window, staff evidence age, critical gates and reviewed exclusions |
| Collector identity | Salesforce/security admin | Dedicated approved identity; object/field and sharing restrictions; API/action permissions; positive and denied representative-user tests |
| Employee access | Salesforce/security admin | Approved intended employee identity; screen, assistant, own-review isolation and optional follow-up permissions verified separately |
| Personal-data destinations | Privacy and system owners | Named integrations, exports, logs, agent traces and backup services with owners and approved retention/restriction rules |
| Operations | Service owner | Monitoring destination, alert recipient, incident escalation, tested stop mechanism and recovery owner |

## Intended execution boundary

1. Resolve an explicitly approved target binding in trusted server configuration; agent arguments must not change the org, identity, query, field selection or network destination.
2. Verify org identity before collection and record collector/runtime identity as protected evidence. Return aggregate counts and canonical check results only. A denied or unavailable measurement stays unknown; permissions are not escalated to obtain a score.
3. Select a customer-approved versioned profile before collecting. Record rubric/specification versions, policy references, explicit overrides, snapshot instant, accessible-record scope and query/test versions. Current fixed outputs use empty overrides; they do not support arbitrary customer profiles.
4. Keep assessment read-only. Review saving and optional own follow-up Tasks are separate permission-controlled actions; active permission/approval/stop/recovery exercises require their own isolated authorization. Do not expose seeding, scratch provisioning, CLI, record exports or anonymous Apex as agent tools.
5. Keep credentials, record values, evidence references and source training artifacts outside agent output. Store protected evidence separately with approved access and retention. Validate tool results and failures, including logs, traces, caches and retry paths. Test actual destinations rather than inferring them from source code.
6. Preserve replayable sanitized measurements and fixed scoring independently of variable agent text. Apply small-cohort suppression before returning counts or derived recommendations. Record denied checks and scope gaps alongside scores; no blended readiness percentage is introduced.

## Release and rollback acceptance

- Validate in a separately authorized non-production context with synthetic data and the intended identities. Include empty/denied/suppressed data, unknown controls, stale staff evidence, observed critical failures and forbidden writes/exports.
- Check the rendered results and reviewer workflow on the customer's supported desktop/mobile surfaces. Check both own-review isolation and native Salesforce administrator/sharing access; do not promise that private training records are inaccessible to authorized admins.
- Verify actual entitlement/settings and expected usage evidence for the selected assistant surface. A license assignment or administrator conversation is insufficient.
- Finish approved retention/erasure/sync/restore testing across the named destinations, or retain privacy readiness as not assessed. Do not delete required audit evidence or run restore against production.
- Have the service owner rehearse stopping the agent/collector and revoking its dedicated access without changing unrelated integrations. Record the tested procedure and responsible person before rollout; the current repository does not provide a verified universal stop command.
- Before changes, record the approved metadata version, configuration and permitted backup/recovery procedure. Deploy only reviewed metadata to the explicitly authorized target, validate under the intended user, and retain deployment/test evidence. Use the approved prior metadata/configuration for rollback; a metadata rollback does not automatically reverse created Tasks or training reviews, and deleting those records requires the applicable retention decision.

Customer approval, identity provisioning, customer collector implementation, environment-specific stop/rollback procedures and all customer acceptance evidence remain open in TODO.md. This design does not grant access or certify production readiness.
