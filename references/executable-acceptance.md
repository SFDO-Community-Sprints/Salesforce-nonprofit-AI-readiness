# Executable acceptance and required bindings

The scan runs real collectors and calls. It reports the authenticated principal and measured surface; it never substitutes permission-set configuration for effective runtime access.

| Criterion | Executable implementation | Remaining binding for full acceptance |
| --- | --- | --- |
| Allowed assessment | Invoke native fixed assessment and validate aggregate result | Run under the intended assistant identity, not an administrator substitute |
| Forbidden raw read | Execute USER_MODE Email read when current identity lacks access and observe denial | Actual intended restricted identity with approved positive and negative scope |
| Unapproved write | Invoke follow-up action without its permission and verify denial before CRM DML | Actual consequential action and approval workflow if the assistant exposes one |
| MCP boundary | Execute the fixed facade, verify aggregate/no-staff output or sanitized denial | Actual exposed tools/APIs; fixed facade is not universal export coverage |
| Stop | Org-wide package control gates assessment, MCP, inventory and follow-up writes | Other deployed agents/integrations require their own stop binding |
| Recovery | Re-enable package control and repeat allowed execution | Service-owner approval/retest for the real runtime |
| Monitoring | Persist fixed source/check/outcome vocabulary to private operational events | Actual trace/alert destination and observed human escalation |
| Source deletion | Create one new canary, verify existence, soft-delete, verify active reads and fresh count exclude it | No arbitrary existing record selection; scratch-only active exercise |
| Recycle Bin erasure | Observe whether the canary remains recoverable | Soft deletion is an observed failure of permanent-erasure acceptance, never a pass |
| Agent output | Explicit unmeasured destination | Actual agent/session endpoint and approved prompt test |
| Integration deletion/sync | Explicit unmeasured destination | Named connected system, authorized sandbox access, delete/read/sync operations |
| Logs | Explicit unmeasured destination | Actual stored and new log destinations and authorized marker query/removal policy |
| Backup restore | Explicit unmeasured destination | Backup provider and isolated restore target with approved re-deletion/retention procedure |
| Export copies | Explicit unmeasured destination | Named export stores/owners and authorized lookup/removal operation |
| Retention | Explicit unmeasured decision | Accountable privacy approval, retention schedule and documented exceptions |
| Staff | Evaluate current stored answers and observed review data | Seven actual human demonstrations; seeded practice inputs cannot prove competency |

`ReadinessRuntimeProbe.inspect()` executes current-principal probes automatically during Run assessment. Probe outcomes and unresolved bindings are shown individually. Operational events contain no donor values, request payloads, evidence references, tokens, URLs or error text.

`ReadinessErasureProbe.run()` is a separate confirmed active operation. It requires the focused tester permission, exact hostname and platform-issued scratch domain. The tester role includes Contact edit because Salesforce requires it for Contact delete; the API never selects existing records and never updates Contacts. It creates and soft-deletes only its own canary, reporting cleanup on failure. It does not purge the Recycle Bin or touch downstream systems.

`ReadinessControl.setDisabled()` requires Readiness Control Manager. Default is enabled. Stop applies at package entry points; it does not pretend to disable unrelated Salesforce agents. Emergency stop is not prevented by audit-write failure. Stop/resume and runtime-probe events are visible to the separate Operations Reader role for its own events.

The scratch post-deploy script assigns these three active-verification roles separately, in addition to the three UI roles. Production setup does not automatically assign active-verification privileges.

No external destination name or credential is inferred from an empty inventory. A real provider adapter cannot be selected or exercised until its system and authorized endpoint are supplied. The UI names these binding gaps; overall acceptance stays incomplete while any required gate is unmeasured.

## Live execution — 20 October 2026

Target: `data-connect-7516-dev-ed.scratch.my`, Initial PoC. Serpent `DEPLOY-18` (`6ad74c49a03925f32559d866`) succeeded: 58/58 metadata components, zero component failures. Validation passed before deployment. Post-deploy Apex compiled and succeeded (`6ad74c7d0b1fc2506f18df43`).

Executed runtime and erasure probes (`6ad74c96a03925f32559d86a`) compiled and succeeded. Native aggregate assessment passed; unauthorized follow-up invocation returned sanitized denial with zero DML in that action; unauthorized MCP facade invocation returned sanitized denial. Raw Email denial was correctly unmeasured because this administrator can read it. Sanitized operation events were recorded.

The probe created and soft-deleted its own fictional Contact. Active absence and fresh aggregate exclusion passed. Recycle Bin recoverability was observed, so permanent erasure failed; downstream destinations remained unknown. No existing Contact was selected or purged.

Stop committed in one transaction (`6ad74cc0a1d4386aa828d039`). A subsequent transaction confirmed assessment and inventory denial, then resumed the package (`6ad74cdbab96711892f6ef49`). A third transaction confirmed enabled state and successful native assessment recovery (`6ad74cf3ab96711892f6ef4b`). Eight private operational events were observed before the browser scan. The package was left enabled.

After refreshing Lightning's component cache, the native browser showed Executed verification, its individual observed outcomes, operational-events link, separate confirmed source-erasure action and enabled package controls. Run assessment executed the new probes and displayed their results. This verifies the current administrator/package surface, not the intended assistant or external systems. No human competency or end-to-end erasure pass is claimed.
