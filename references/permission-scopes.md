# Narrow permission scopes

Each permission set has one purpose. Assign only the roles a person needs; none of these sets is an administrator or bundled “all readiness features” role.

| Permission set | Grants | Does not grant |
|---|---|---|
| Readiness_Assessor | Interactive data assessment, Account/Contact read fields needed by its user-mode checks, readiness app/tab | Staff evidence, staff writes, API-only integration access, Task writes, Employee agent |
| Readiness_Staff_Reader | Own calculated staff outcome through one class and explicit summary permission | Raw review object/fields, evidence references, saving reviews, data assessment, Tasks |
| Readiness_Staff_Reviewer | Create/read own structured reviews and calculated outcomes | Edit/delete reviews, CRM data assessment, Tasks, MCP, Employee agent |
| Readiness_Follow_Up | Explicit readiness follow-up permission and Task creation/update prerequisites | CRM writes, staff evidence, MCP, Employee agent; use alongside Assessor for the screen/action |
| Readiness_Employee_Agent_Access | The one Nonprofit Readiness Employee agent | Data permissions, staff review, Task or MCP permissions; platform panel access is separate |
| Readiness_MCP | API-only transport, the fixed ReadinessMCP aggregate action and its explicit execution permission | CRM object/field grants, staff evidence, Tasks, interactive app/tab or Employee agent |

Permission sets add access; they cannot remove access granted by a person's profile, other sets, groups or sharing. The dedicated MCP verifier rejects additional assignments and effective privilege drift rather than treating the presence of Readiness_MCP as sufficient. Do not assign it to an administrator.

## Dedicated MCP identity

After deploying to the verified disposable scratch, run:

```sh
python3 scripts/setup_mcp_connection.py --alias nonprofit-readiness-mcp
```

This creates a separate **Minimum Access - API Only Integrations** identity with the Salesforce Integration license and only the reviewed MCP permission set. The local credential remains in Salesforce CLI storage; `.local/mcp.json` contains only its alias and pinned org/user IDs. Existing bindings are verified, not silently replaced. If a prior creation attempt left an alias without a binding, retry verifies that explicit existing alias against the same strict identity/permission boundary before saving it; unrelated identities are rejected. If creation succeeds but validation fails, the synthetic user may remain in the disposable org; no usable binding is saved and no administrator fallback is selected. Inspect the failed stage privately before retrying or authorizing cleanup.

Every MCP tool request checks the pinned authenticated identity, the saved active scratch provenance, the exact profile/role assignments and the effective permission boundary. Administrative scratch credentials are used only for this control-plane inspection, not for collecting source Contact values. Assessment calls use the dedicated credential and fixed `ReadinessMCP` action. Missing bindings, wrong users/orgs and unexpected grants fail closed. This is still a scratch-bound demonstration, not a production credential provisioning system.

The API-only profile has no object-permission grants. Its expected platform baseline consists of API access, API-only login and the platform ChatterInternalUser flag; none supplies CRM CRUD. The MCP set has no object/field permissions. The integration identity cannot retrieve Contact email values or invoke human review/Task actions just because it can request aggregate counts.

## Fixed aggregate computation

The MCP facade checks its explicit custom permission and accepts only the existing fixed scenario names. Shared scoring uses fixed aggregate SOQL in system CRUD/FLS mode within an explicitly `with sharing` class. This allows approved counts without granting the integration credential general record/field access. The facade returns no raw values, staff outcome, evidence reference or write operation, and always withholds cohorts below five. The former local small-cohort bypass does not apply to this facade.

These outputs are labelled **sharing scoped**, not user-mode CRM access. System-mode aggregate computation does not establish field-level access or enforcement of restriction rules; a customer needs a separately reviewed aggregate purpose, sharing design and restriction-rule validation. Unknown/denied evidence is not a readiness pass. The capabilities tool does not acquire wider permissions to read license/settings information; inaccessible sections remain unavailable/unknown.

## Human staff and Task boundaries

Own-summary reading requires Readiness_Read_Staff_Outcomes or the reviewer permission. The fixed class selects only the signed-in user's latest review under sharing and projects calculated outcomes; the summary-reader set does not need raw Snapshot__c access. Reviewer evidence remains protected by native object access and sharing; authorized administrators may have separate access.

Task creation checks Readiness_Create_Follow_Up before collecting data or writing anything. Generic Task rights or an administrator profile alone do not authorize that readiness action. The screen hides its Task controls without this permission. Platform Task grants remain subject to the user's other permissions and sharing; this set is not a platform-wide prohibition on other Task workflows.

The staff component makes no staff Apex calls for assessor-only users. Summary readers load outcomes without an editor; reviewers receive the explicit observation workflow. Combining human roles is a deliberate assignment, not an implicit side effect of data assessment or MCP access.

## Verification

`scripts/test_permission_scopes.py` pins the exact metadata grants. Native tests exercise non-admin summary-only access/raw-query denial, explicit follow-up gates, fixed MCP aggregation without CRM CRUD/FLS, small-cohort suppression, and denied staff/Task operations. MCP connection tests reject missing/mismatched bindings, unexpected roles and privilege drift. Live results are recorded separately in TODO.md; passing role metadata tests does not prove every customer profile or sharing policy is safe.
