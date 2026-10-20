# Salesforce Nonprofit AI Readiness

A self-contained Salesforce application with a restricted MCP assessment interface. The application runs in Apex and Lightning Web Components; users need no local scripts or Python runtime.

## Deploy through Serpent

1. Deploy `force-app/main/default`, excluding the scaffold Admin profile.
2. Execute `scripts/apex/post-deploy.apex` in the selected org.
3. For the named disposable demo org only, execute `scripts/apex/seed-demo.apex` to create actual fictional input records.
4. Open **Nonprofit AI Readiness** and choose **Run assessment**.

See the [administrator walkthrough](START-HERE.md), [permission scopes](references/permission-scopes.md), and [executable acceptance matrix](references/executable-acceptance.md).

Data quality, license/feature inventory, policy-based freshness, staff answer evaluation, permission probes, package stop/resume, sanitized operational logs and confirmed scratch source-deletion exercises execute inside Salesforce. Demo seeds create input records; the assessment always calculates from current org configuration and data.

MCP uses a separate narrowly scoped integration identity and the fixed `ReadinessMCP` Apex facade. It returns aggregates, withholds small cohorts and grants no raw CRM or staff-evidence access. Serpent MCP handles deployment and anonymous Apex execution.

## Acceptance limits

Actual assistant identity/workflow checks, downstream deletion, backups, exports, retention decisions and human demonstrations require their actual systems and evidence. Missing measurements remain unknown. Recycle Bin recoverability fails permanent-erasure acceptance. See [remaining work](TODO.md).

## Repository

Salesforce metadata lives in `force-app/main/default`; optional Agentforce metadata lives in `agentforce/`. This preserves the managed-package scaffold but does not register a namespace or create a managed package.

Python and Node files retained from the community import are developer regression/reference tools only. They are not application prerequisites, deployment steps, MCP services or scan runtimes. The supported user workflow is Salesforce plus MCP.
