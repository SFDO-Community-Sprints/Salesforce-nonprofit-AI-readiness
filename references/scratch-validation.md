# Disposable nonprofit validation

Nonprofit Cloud Fundraising is supported through the Fundraising scratch feature; Dev Hub entitlements and release settings can constrain creation. NPSP is a separate managed-package setup. Do not substitute one model for the other or label a generic org a nonprofit test.

Use an explicitly selected Dev Hub and a unique alias. Creation consumes scratch allocation. Keep the existing project's defaults, metadata, and scratch definition unchanged.

```sh
sf org create scratch --definition-file <skill-path>/references/nonprofit-scratch-def.json --target-dev-hub <hub> --alias <unique-test-alias> --duration-days 1 --wait 5 --json
```

Filter JSON before displaying it; creation and authentication output can contain secrets. On failure, record the actual error and stop; do not repeatedly consume allocations or switch to customer orgs. For a requested NPSP assessment, use an authorized NPSP test org with verified installed dependencies, consulting the current official installer; Fundraising-only validation does not cover NPSP.

First query Organization identity, discover objects, and describe GiftTransaction and Contact. Verify nonprofit objects are present and queryable. Run the skill's read-only checks and record unknown staff/governance answers. An empty org must return readiness not established.

For a data-quality test, seed only disposable synthetic data after confirming the target is this scratch org. Example: two Contacts, one with Email and one without; an aggregate must report 2 total and 1 missing email (50%). Do not treat email as universally required: this fixture only tests a chosen donor-contact channel. Re-run after a synthetic correction to verify the metric responds. Keep fixture cleanup confined to this org.

Also verify denied-query handling leaves controls unknown and representative-user access remains unknown until positive and negative tests run. A scratch org does not prove production data quality, staff competence, legal suitability, real-volume behavior, or actual Agentforce enforcement. Do not claim AI runtime validation without licensed configuration and exercised runtime tests.

Delete only the scratch org created for this run when finished, using its explicit alias. Report any cleanup failure and expiry. Store a compact validation record with actual outcomes and skipped checks; never credentials or real personal records.

See [the recorded validation](validation-result.md) for observed outcomes and limits; it is historical evidence, not a current org assessment.
