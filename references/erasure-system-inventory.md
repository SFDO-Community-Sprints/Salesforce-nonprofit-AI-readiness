# Privacy and erasure: system inventory

**Status: Not assessed — High-priority work remains open.**

On 19 October 2026, a read-only inventory was run against the project's saved practice scratch org after confirming its identity and active scratch-org status through the Dev Hub. These observations apply only to that practice org and the authenticated Salesforce CLI identity. They do not describe a production organization.

## Observed Salesforce configuration

| Configuration | Visible entries | Names |
|---|---:|---|
| Named credentials | 0 | None returned |
| External credentials | 0 | None returned |
| Connected apps | 1 | `CPQIntegrationUserApp` |
| Authentication providers | 0 | None returned |
| Remote site settings | 0 | None returned |
| Installed packages | 0 | None returned |

All six listings completed successfully. Only configuration names and installed-package labels/namespaces were selected for this report. No credential values, endpoints, tokens, authentication output, donor records, or external system responses were exported.

A visible connected app is a configuration entry, not proof that an integration is enabled, used, receiving personal data, or capable of deletion. No backup package was visible in the installed-package listing. That does not establish the absence of backups or integrations: externally hosted jobs, API clients, exports, platform services, user downloads, and systems outside this scratch org remain outside this inventory. Empty metadata lists also do not prove that every possible connection is absent.

## What remains unknown

| Destination or process | Evidence still required |
|---|---|
| Connected app | Owner and intended purpose of the visible entry; whether an active data flow exists; authorized deletion or restriction procedure if applicable |
| External integrations and exports | Named systems, responsible owners, mapped personal-data destinations, authorized test access, and scheduled/replay behavior |
| Agent and host logs | Logging destinations, personal-data content rules, retention settings, access control, and demonstrated deletion or restriction |
| Backups and restore | Named provider or Salesforce backup service, applicable retention/expiry rules, and an isolated restore test that does not reintroduce erased information |
| Retention and exceptions | Privacy-approved policy covering each destination, retained data and purpose, applicable exceptions, and evidence of expiry or restriction |

The existing fictional-contact deletion exercise confirmed that fresh assessments exclude a soft-deleted Contact while the record remains recoverable from the Salesforce Recycle Bin; see [MVP validation](mvp-validation.md). This establishes source-query behavior, not physical erasure or removal from every destination. No additional deletion, purge, external connection, backup restore, or retention-policy change was performed during this inventory.

## Read-only commands used

The saved alias and hub were read locally from ignored `.local/scratch.json`; their values are intentionally omitted here. The existing `verify` helper confirmed the saved Organization identity and an active matching ScratchOrgInfo record. The configuration listings used the existing sanitized Salesforce CLI wrapper:

```text
sf org list metadata --metadata-type NamedCredential --target-org <saved-practice-alias> --json
sf org list metadata --metadata-type ExternalCredential --target-org <saved-practice-alias> --json
sf org list metadata --metadata-type ConnectedApp --target-org <saved-practice-alias> --json
sf org list metadata --metadata-type AuthProvider --target-org <saved-practice-alias> --json
sf org list metadata --metadata-type RemoteSiteSetting --target-org <saved-practice-alias> --json
sf package installed list --target-org <saved-practice-alias> --json
```

Only the count and `fullName` from each metadata listing, and the package name/namespace fields from the package listing, were emitted. Exception details would have been replaced with a generic unavailable result. No configuration was changed.

The end-to-end check cannot pass until the named external systems, authorized test scope, and approved retention rules are supplied and exercised. Keep **Privacy and erasure: Not assessed** in the readiness result.
