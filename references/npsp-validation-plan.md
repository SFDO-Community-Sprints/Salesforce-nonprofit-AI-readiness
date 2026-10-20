# Separate NPSP validation plan

Read-only feasibility discovery, 20 October 2026. **NPSP support remains unvalidated.** No org was created, package installed, default changed, permission assigned or test data written during this discovery.

## Verified environment

The saved `.local/scratch.json` practice target passed `scratch_demo.verify`: Organization identity matched the saved ID, `IsSandbox` was true and its Dev Hub confirmed active scratch provenance. Filtered CLI observations:

| Observation | Result |
|---|---|
| Installed packages (`sf package installed list`) | Empty list; no installed NPSP package reported |
| `GiftTransaction` describe | Available and queryable |
| Account describe | `IsPersonAccount` field present |
| Bound Dev Hub limits | Active scratch orgs: 19 remaining of 80; daily creations: 160 remaining of 160 |

These are point-in-time observations of the saved practice target and its bound Dev Hub, not every authenticated org. Quota can change and does not guarantee NPSP installation eligibility. The configured Fundraising/PersonAccounts features and these observations establish a Fundraising demonstration, not an NPSP environment or hybrid. No auth JSON, tokens, usernames or subject records were displayed.

Do not install NPSP into this existing practice target. Salesforce documents Person Accounts as unsupported with NPSP and irreversible once enabled. Both bundled scratch definitions enable PersonAccounts, so neither is an NPSP definition. Use a separate fresh environment without that feature. [Salesforce NPSP FAQ](https://help.salesforce.com/s/articleView?id=sfdo.NPSP_FAQ.htm&language=en_US&type=5).

## Installation basis

The official installer currently lists Contacts & Organizations 3.23, Households 3.19, Recurring Donations 3.26, Relationships 3.16 and Affiliations 3.14; Account and Opportunity record-type steps; NPSP 3.237; and mobile configuration. Recheck versions and pre-install validation immediately before installation. Use the complete managed installation plan rather than one guessed package ID. Salesforce recommends trying a sandbox or developer environment before production. [Official MetaDeploy installer](https://install.salesforce.org/products/npsp/install).

The official repository separately declares Households (including Contacts & Organizations), Recurring Donations, Relationships and Affiliations dependencies. Its development tooling is corroborating dependency evidence, not a reason to add CumulusCI to this project or deploy an unmanaged development checkout. [SalesforceFoundation NPSP configuration](https://github.com/SalesforceFoundation/NPSP/blob/main/cumulusci.yml).

## Execution sequence for the authorized follow-up

1. Confirm the separate disposable target, bounded duration, installation route and package terms with the environment owner. Recheck the saved Dev Hub identity and allocation. Create a new Enterprise scratch definition without Fundraising or PersonAccounts; use a unique explicit alias and `--target-dev-hub`, without default-setting flags. Creation feasibility and installer acceptance remain untested. If that route fails, record the sanitized error and choose an explicitly authorized NPSP developer/test environment; do not use customer or production logins as a fallback.
2. Verify Organization identity and scratch provenance before any mutation. Keep a separate local NPSP state file; leave `.local/scratch.json`, the existing MCP binding and both current Fundraising definitions untouched.
3. Run official installer preflight against the explicitly selected new target. Observe dependency installation, record-type/configuration steps and completion; preserve exact installed versions and sanitized failures. Do not report success from the install request alone. Authentication/terms may require the authorized operator.
4. Inventory installed namespaces/versions and describe Account, Contact, Opportunity and the installed NPSP relationship/donation objects before writing queries or fixtures. Verify Household Account model configuration. NPSP extends standard objects and uses Opportunities for revenue; `GiftTransaction` availability is not an NPSP acceptance test. [Salesforce NPSP data model](https://trailhead.salesforce.com/content/learn/modules/nonprofit-success-pack-administration-basics/understand-the-npsp-data-model).
5. Prepare fictional Household/organization Contacts and Opportunities through supported NPSP operations, accounting for package automation and permissions. Compare aggregate completeness/linkage/duplicate checks to recorded expectations. Existing generic Contact fixture assumptions may change when NPSP creates or associates households automatically. `scratch_demo.test` currently requires GiftTransaction and must not certify this target unchanged.
6. Deploy the existing assessment only after compatibility review; run Apex, native/MCP parity, suppression, error/sentinel and representative-user access tests against the separate state. Add no arbitrary-query or raw-record agent surface. Record package versions, observation scope and timestamps with results. Contact checks alone establish no NPSP donation/relationship assessment.
7. Record component results and failures, then remove only the explicitly identified disposable environment under its authorized lifecycle. Keep technical controls, staff competency, production support and erasure unknown until separately evidenced.

## Outstanding requirements

An authorized installation target/route; successful preflight and package installation; actual namespaces/schema/configuration; NPSP-aware synthetic fixtures; a separate verified state/binding; representative identities; native/MCP compatibility results; and an agreed donation/relationship assessment scope. Discovery and available quota close none of those acceptance steps.
