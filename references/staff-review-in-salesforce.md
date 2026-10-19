# Record staff exercises in Salesforce

Open **Nonprofit AI Readiness** and find **Staff readiness exercises** below the assessment results. The seven sections describe fictional situations and the actions a reviewer needs to observe. Opening the screen or running a data assessment does not save a staff review.

An administrator grants **Readiness Staff Reviewer** only to people responsible for reviewing these exercises. **Readiness Assessor** remains read-only and cannot save observations. Reviewer access does not grant follow-up Task creation.

For each exercise:

1. Observe the actions in an approved practice environment. Choose Demonstrated, Partly demonstrated, Not demonstrated, or Not observed for each action.
2. Select an unsafe action only when it was actually observed.
3. Enter a reference to the protected evidence, such as TRAINING-001. Keep names, personal information and source notes outside this form.
4. Confirm the reviewed observations when the reference supports them.

Choose **Save staff review**. Salesforce calculates the outcome from the fixed answer key. A positive answer without all required actions and confirmed evidence cannot pass. Missing observations remain unknown. An observed critical failure blocks a pilot until corrected and retested.

The latest review belongs to the person who saved it. Its score covers those recorded exercises, not every member of staff. The screen shows its saved time and seven outcomes. A replacement starts with unobserved actions; the screen does not turn a previous score into new evidence.

Run the assessment to include the latest own review in recommended actions. If results are already displayed, saving refreshes them. **Create my follow-up tasks** remains a separate choice: it uses the current assessment and assigns its recommendations to you. Existing Tasks are not automatically closed when a newer review passes.

The Employee assistant receives calculated outcomes and fixed next steps, not evidence references or source documents. The restricted external connection reads the same own-review outcome through the fixed Salesforce assessment action and reconstructs its allowed summary from the answer key. It never returns references or source documents. A passing staff review never establishes technical safeguards, complete erasure, legal compliance or overall pilot approval.

Fictional ready and failing review files remain offline demonstrations. Salesforce rejects the simulation format when saving actual evidence. Relabeling invented observations cannot be detected automatically: reviewer confirmation is an accountable assertion, not independent verification.

Review records use Salesforce’s private sharing model. The application only selects the signed-in person’s own review. Salesforce administrators and other people with access through native permissions, sharing or the role hierarchy may still access stored review records outside this screen; “private” is not a promise to hide evidence from authorized administrators. Review this against your training-record policy before customer use. [Salesforce explains private sharing and hierarchy access](https://developer.salesforce.com/blogs/2013/12/locking-down-record-access-in-salesforce).

Calculated training outcomes can still be sensitive even without names. The form explains before saving that the current reviewer’s outcomes become available to assessment assistants. This workflow excludes names, source notes and evidence references from assistant output; it does not claim that an attributable training score is anonymous. Confirm that this limited use of exercise outcomes fits your organization’s approved purpose and training-record policy.

## Optional evidence freshness policy

Save time does not establish when actions were observed. To enforce an organization-approved age limit, select **Apply an approved evidence age policy**, enter the assessment date (today in Salesforce), enter the approved maximum evidence age in whole days, and record the actual observation date for each supported exercise. No date or age limit is preselected. Missing dates are allowed and leave that exercise unknown. Confirm dates against the protected evidence before saving.

The saved review stores the explicit policy and observation dates inside its protected snapshot. Each retrieval recalculates opted-in outcomes as of the current Salesforce date; it does not freeze a passing result at its original assessment date or modify the saved observations. The summary displays the actual assessment date and age limit. Older reviews and reviews saved without opting in retain their existing scores and are labelled **Evidence freshness not assessed**. Opting out in a replacement review removes age enforcement for that replacement; reviewers remain responsible for using the approved policy. This is a reviewer-selected evidence policy, not an administrator-enforced organization-wide retention control.

The Salesforce action, recommendations and restricted MCP connection receive the resulting outcomes. The restricted connection emits only validated freshness statuses, assessment date and age limit; observation dates and evidence references stay excluded. A confirmed critical failure still blocks when its date is expired or missing. Correct and retest the failure rather than waiting for it to expire.

### Offline replay

For a separately retained structured CLI review, a reviewer can apply an explicit age policy:

```sh
python3 scripts/staff_readiness.py evaluate review.json --freshness-policy policy.json
```

The policy file must contain exactly these fields; the dates and 30-day limit below are fictional examples, not recommended customer defaults:

```json
{
  "as_of": "2026-10-19",
  "max_age_days": 30,
  "observed_on": {
    "scope": "2026-09-19",
    "sensitive_data": "2026-09-18"
  }
}
```

`observed_on` maps the fixed question IDs from `references/staff-answer-key.json` to reviewer-verified observation dates. Keep personal information and evidence references out of this policy. The assessment date and whole-day age limit from 0 to 2147483647 are mandatory. Dates use `YYYY-MM-DD`; future observation dates and unknown question IDs are rejected. Evidence exactly at the age limit remains current. Missing or expired dates make that exercise unknown, including an ordinary observed failure; confirmed critical failures continue to block until corrected and retested. A current date cannot replace missing actions, evidence or reviewer confirmation. Simulation results remain labelled simulations.

The output records the assessment date, age limit and per-exercise freshness statuses without emitting observation dates or evidence references. This deterministic offline check neither updates saved Salesforce records nor retrieves protected source artifacts. The same policy can be stored as an optional `freshness_policy` property of the structured review for Python replay; replay uses its explicit `as_of` date, while Salesforce latest-review retrieval reassesses using the current Salesforce date. Reviewers must verify dates against those artifacts and agree the policy before relying on it. Omitting `--freshness-policy` preserves the existing scoring behavior; no age limit is silently selected.
