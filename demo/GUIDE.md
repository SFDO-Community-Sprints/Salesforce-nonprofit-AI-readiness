# Demonstration setup and repeatable checks

For the Salesforce administrator walkthrough, start with [START-HERE.md](../START-HERE.md). This guide contains the technical setup.

Run from the salesforce-nonprofit-ai-readiness project root. All data is fictional, uses example.invalid email addresses, and contains no beneficiary notes or production records.

```sh
python3 scripts/demo.py test
python3 scripts/demo.py score demo/blocked/fixture.json
```

| Scenario | Data score | Technical score | Staff score | Expected conclusion |
|---|---:|---:|---:|---|
| poor | 50.0% | 20.0% | 14.3% | Not ready |
| improving | 50.0% | 60.0% | 71.4% | Readiness not established |
| pilot | 100.0% | 100.0% | 100.0% | Ready for bounded pilot **simulation** |
| blocked | 100.0% | 80.0% | 100.0% | Not ready: unauthorized export succeeds in simulated evidence |
| unknown | 0.0% | 0.0% | 0.0% | Readiness not established; 0% coverage |

Poor and improving share a data score but have different measurements: poor has only four contacts and 25% email completeness; improving has ten contacts and 80% completeness but a repeated email. Show the underlying measurements rather than just the score. Pilot and blocked share clean data; the critical export failure still blocks the latter.

## Demo rubric: donor-summary-demo-v1

This intentionally small local demo is not the full production assessment. Data checks are: at least ten Contacts, at least 90% email completeness, all Contacts linked to an Account, and zero repeated populated emails after trim/lowercase normalization. Email completeness is a demonstration of an approved contact-channel requirement, not a universal nonprofit requirement. Repeated emails are only duplicate indicators. Nested Contact records establish Account relationships on import. No freshness or nonprofit gift-quality score is implemented yet.

Five technical checks: prerequisites, runtime access, approval, export blocking, and stopping the agent. Seven staff checks correspond to the skill's checklist. Technical and staff evidence is explicitly simulated, not inferred from imported records. All checks are equally weighted per category; unknowns earn zero points, and coverage excludes unknowns. Percentages round half up to one decimal place.

Critical gates: runtime access, approval, export blocking, stop control, sensitive-data handling, untrusted-content handling, consequential-output review, and incident response. Any critical failure means not ready; otherwise unknown evidence means readiness not established. In this demo any remaining failed check also prevents a pilot recommendation. No overall blended score is calculated.

Each scenario has:
- `salesforce-tree.json`: Account/Contact seed records importable into an isolated Salesforce test org.
- `fixture.json`: the same records plus explicitly simulated control and staff evidence for offline replay.
- `expected.json`: expected measurements, category scores, coverage, and decision.

## Optional Salesforce seed import

Only use a disposable scratch org explicitly selected for this demonstration. Confirm its org ID and scratch provenance with the creating Dev Hub before importing. Do not use customer orgs. For manual imports, use one scenario per fresh scratch org. The scripted live runner below instead scopes each query to a separate Account cohort.

```sh
sf data import tree --files demo/poor/salesforce-tree.json --target-org <verified-demo-scratch-alias>
```

Importing seeds changes records, not permissions, settings, staff competency, or AI behavior. In live mode collect technical evidence from the org and run authorized exercises; leave untested checks unknown. Never reuse simulated passing evidence as a live assessment result. An empty Contact child list in the unknown scenario is an offline empty-data case; use a fresh empty org rather than import that tree.

Delete the disposable org after the demonstration. Reimports create duplicate records and change scores; these fixtures are not an idempotent production seeder. These fixtures were imported and checked successfully on 2026-10-19 with the scripted cohort-scoped runner below.

## Agent demonstration prompt

“Use this project's skill to assess the synthetic blocked fixture. Run the deterministic demo scorer, explain the measurements and category scores, identify the blocking guardrail, and propose remediation. Clearly label all technical/staff evidence simulated. Then compare with pilot and unknown, explaining why clean data is insufficient and why missing evidence is not a pass.”

Regenerate fixtures only when deliberately updating the demo, then run tests and review changed expectations:

```sh
python3 scripts/demo.py generate
python3 scripts/demo.py test
```

## Live scratch demo scripts

From the project root, with Salesforce CLI authenticated to the chosen Dev Hub:

```sh
python3 scripts/demo.py test
python3 -m unittest discover -s scripts -p 'test_*.py'
python3 scripts/scratch_demo.py create --hub <your-dev-hub-alias> --alias nonprofit-readiness-demo
python3 scripts/scratch_demo.py seed
python3 scripts/scratch_demo.py deploy
python3 scripts/scratch_demo.py test
```

The dedicated org lasts seven days. The script saves its identity in ignored `.local/scratch.json` and verifies both Organization identity and active Dev Hub scratch provenance before importing. It does not change default targets. Five Account cohorts in one org isolate scenario measurements; queries are scoped to each cohort, not the entire org. Re-running seed skips existing cohorts; tests detect changed or incomplete data rather than silently reseeding it. Fix partial fixtures in the disposable org or create a fresh one explicitly.

The live report at `.local/live-results.json` contains aggregate data results and separate simulated technical/staff comparisons. It leaves live technical/staff readiness unknown. The linkage metric only covers Contacts within each seeded Account; it does not detect orphan Contacts elsewhere in the org. Fixture email values are read transiently to compute duplicate indicators and are not written to the report.

To open the org, run `sf org open --target-org nonprofit-readiness-demo`. To delete it after the demonstration, run `sf org delete scratch --target-org nonprofit-readiness-demo --no-prompt`. After confirmed deletion, remove `.local/scratch.json` before creating another demo. Setup and seed scripts use Salesforce CLI directly; agent-facing assessment uses the read-only MCP below.

## Agent-facing MCP

Deploy the current metadata, then provision the separate integration identity with `python3 scripts/setup_mcp_connection.py --alias nonprofit-readiness-mcp`. See [permission scopes](../references/permission-scopes.md). Run the local stdio MCP through your client's MCP server configuration (adapt the outer config format to that client):

```json
{
  "mcpServers": {
    "nonprofit-readiness": {
      "command": "python3",
      "args": ["/absolute/path/to/salesforce-nonprofit-ai-readiness/scripts/readiness_mcp.py"]
    }
  }
}
```

Replace the example path with your local project folder. Create/seed the scratch org first and keep Salesforce CLI authenticated. The server binds to `.local/mcp.json`, verifies its dedicated API-only identity and the separate active `.local/scratch.json` provenance, and speaks newline-delimited JSON-RPC on stdin/stdout. It exposes `org_identity`, `org_capabilities`, and `readiness_check`; the latter accepts only a scenario from `organization`, `poor`, `improving`, `pilot`, `blocked`, `unknown`. Organization scope performs fixed sharing-scoped aggregate computation without granting direct CRM object/field access; the other inputs are practice examples. No arbitrary SOQL, org override, raw record retrieval, free text, or writes are exposed.

Cohorts below five are always suppressed; the old synthetic flag is not an exception to the fixed facade. Aggregate-only results avoid sending Contact emails or names to the agent; record-level masking is not implemented. Fixed Salesforce aggregate computation bypasses CRUD/FLS inside the reviewed with-sharing class; restriction-rule enforcement is not established. The integration identity has no raw CRM grants and no staff-review access. Capabilities denied to this identity remain unknown/unavailable, rather than acquiring broader permissions. Explicitly shared practice records may be required for a new identity; different identities need not see the same data. Run the server on a trusted machine.

Suggested agent prompt: “Call org_identity, then readiness_check for poor, improving, pilot, blocked, and unknown. Compare the measured data scores and coverage. Keep live technical and staff evidence unknown. Use offline simulated fixtures only as a separately labeled demonstration of guardrail gates.”

Run local checks with `python3 -m unittest discover -s scripts -p 'test_*.py'` and the existing scorer test above. A passing suite establishes this MVP's tested interface, not staff readiness, NPSP compatibility, or actual Agentforce runtime behavior. No customer org support is included.

## Present the MVP in five minutes

1. Run `python3 scripts/run_demo.py` for the offline comparison. Explain that all controls and staff outcomes here are simulated fixture evidence.
2. Show `poor`: incomplete donor contact data produces a lower data score. Show `pilot`: clean synthetic data and simulated passing controls demonstrate the scoring rules, not live readiness.
3. Show `blocked`: the same clean data cannot override a simulated unauthorized-export failure. Show `unknown`: unavailable evidence lowers coverage and cannot earn a pass.
4. With the verified scratch org seeded, run `python3 scripts/run_demo.py --live`. This exercises the MCP path and saves sanitized results in `.local/mcp-demo-results.json`. Check scoring against the actual scoped aggregates; unavailable practice cohorts remain unknown, and different sharing scopes need not match the complete offline fixtures. Live staff and runtime controls remain unknown.
5. Connect the agent with the configuration above and ask it to explain the MCP results and remediation. It should state what is measured, what is simulated, and what remains unknown.

The demo runner does not create or seed the scratch org; use the setup commands above first. Keep the synthetic demo exception confined to the fictional scratch data.

## Complete automated check

`python3 scripts/check_all.py` runs all local tests and scorer assertions. Add `--live` for the prepared scratch org: Salesforce action tests (including follow-up ownership/reuse and synthetic deletion), MCP privacy/scoring checks, action-to-connection agreement, license/feature inventory, and a live fictional-contact deletion exercise. The live exercise creates and soft-deletes only its own new fictional contact in the verified scratch org; it leaves no active fixture changes, but the deleted record remains in the Recycle Bin. Sanitized summaries are saved in `.local/`. A failed step stops the run.

Browser interactions and activated Agentforce conversation tests remain separate. The live Run assessment button collects Contact checks and license/feature inventory, not the entire software test suite. Follow-up tasks are created only by the explicit task button.

### Priority demonstration

The offline blocked scenario has a confirmed fictional safeguard failure and therefore a Critical next step. Live unknown safeguards are High, not Critical. The prepared organization currently yields High access/erasure reviews and Medium staff/data follow-ups. Each recommendation includes impact. Press Create my follow-up tasks only when you want Salesforce Tasks; matching open tasks are reused and priorities refreshed. Their descriptions preserve Critical/High/Medium/Low even though the standard Task field uses High/Normal/Low.


## Demonstrate failures and the resulting actions

Run `python3 scripts/demo_failures.py` from the project folder. It compares fictional data and safeguard failures, seven failed staff exercises, and 14 failed erasure checks covering integrations, logs, backups, exports, repeat synchronization, and retention approval. Each produces prioritized next steps. Results are saved in `.local/failure-demo-results.json`; none are evidence about the real org.

Compare staff improvement with `python3 scripts/staff_readiness.py evaluate demo/staff-ready.json`. For an actual staff review, start with `python3 scripts/staff_readiness.py template`; a reviewer must confirm observed actions and supply an opaque evidence reference. Never substitute demo answers for staff observations.

The versioned scoring rules are in `demo/rubric.json`. The erasure checklist measures evidence coverage and keeps overall erasure unassessed until actual systems and outcomes have been verified. Importing demo records cannot turn off safeguards or establish erasure readiness.

For visible failures in the actual practice-org screen, run `python3 scripts/seed_failure_demo.py`, then choose **Run assessment** in Salesforce. This adds 60 fictional contacts with missing email addresses, repeated emails, and missing account relationships. It verifies the disposable org first, preserves the five original practice groups, and skips a complete previous import. It deliberately lowers the organization-wide score. The small-sample failure is demonstrated separately by the `poor` example; a sufficiently large dataset cannot also fail that check. Staff, safeguards, and external erasure failures remain separately labelled simulations, rather than weakening real org protections.


### Confirm that correcting the data improves the result

Run `python3 scripts/check_data_improvement.py` after importing the fictional failure contacts. It measures the baseline, temporarily fixes only those 60 fictional contacts, checks the score improvement, and restores the original demonstration values. Use the practice org without other people editing its demo records during this exercise. Do not run an assessment demonstration or create follow-up tasks until restoration finishes.

If interrupted, follow the saved recovery instructions and run `python3 scripts/check_data_improvement.py --restore`. The script verifies the same disposable org and fixed fictional record set before restoring. The saved recovery file stays in ignored `.local/`.

The complete `python3 scripts/check_all.py --live` command now ensures the failure contacts exist and includes this correction/restoration exercise as well as the fictional source-deletion check. These checks intentionally change practice records; ordinary **Run assessment** remains read-only.
