# Check your Salesforce AI readiness

Open **Nonprofit AI Readiness** in Salesforce and select **AI Readiness**. The **Run assessment** button checks Contact records the signed-in user can access and shows data-quality findings and recommended next steps.

Open **Nonprofit AI Readiness** from the App Launcher in your prepared practice org.

The prepared practice org is **nonprofit-readiness-demo**, available for seven days from 19 October 2026. Its donor records are fictional. The assessment itself reads Salesforce when you press the button; results are not a preset sample state.

## Run an assessment

1. Open **Nonprofit AI Readiness** from the App Launcher.
2. Select **Run assessment**.
3. Review **Data quality**, the counts shown, and which checks need attention.
4. Review **Recommended next steps**, including suggested owners.
5. Review the priorities: **Critical → High → Medium → Low**. A confirmed leak or unsafe action is Critical; missing safeguard evidence is High, not a claimed failure.
6. Choose **Create my follow-up tasks** if you want the recommendations added to your Salesforce Tasks. They are assigned to you, include learning links, and matching open tasks are reused and their assessment priorities refreshed. Running the assessment alone creates no tasks.
7. Complete the [seven staff readiness questions](references/staff-checklist.md) with the team. Authorized reviewers can [record the observed exercises in Salesforce](references/staff-review-in-salesforce.md).

This first version checks enough records, email completeness, repeated email addresses, and contacts linked to accounts. The screen explains the thresholds. Repeated emails are a review signal, not proof that two people are duplicates. Email completeness matters only when the proposed use of AI needs that contact information.

Access and safeguards and Privacy and erasure remain **Not assessed** until those checks are actually carried out. Staff exercises remain unassessed until a reviewer saves supported observations; that score covers only the saved exercises. Good data does not establish overall readiness. Records hidden from the signed-in user are outside the assessment; an administrator should confirm that the intended records are covered.

Only summary results are returned. Donor names, email addresses, and case notes are not sent to the screen or agent by this assessment. Groups below five are withheld. The first version does not offer masked individual records: it refuses individual-record requests entirely.

## A five-minute demonstration

1. Open the prepared app and press **Run assessment**. The initial fictional records contain missing emails and a repeated email, so the current data score should be **50%**.
2. Show the findings and next steps. Explain that all four data checks can be completed even when only two pass.
3. Complete missing emails or resolve the repeated email in the disposable practice org, then press **Run assessment** again. The result is collected again from Salesforce and will change when a threshold is crossed. Do not edit production data for a demonstration.
4. Discuss the unassessed safeguards and staff questions. A higher data score alone does not approve a pilot.
5. Use the separate guided simulation below to demonstrate a failed safeguard and withheld results without changing actual access controls.

The live screen has no sample-state selector. The repeatable sample examples remain in the separate guide and scripts for testing.

## Review licenses and features

Each run also shows product licenses available, assigned, and remaining, plus relevant feature availability and visible record counts. Unassigned seats are a review opportunity, not proof of waste. Neither an assigned license nor an available feature proves actual use; recent activity remains **Not verified**. Missing permissions are shown as unavailable information.

## Deletion and the right to erasure

The full test run includes a fictional contact deletion exercise. It confirms a new assessment excludes the deleted contact and explicitly confirms it remains recoverable from the Recycle Bin. It does not prove complete erasure. End-to-end verification is now in the current High-priority to-do list. A privacy lead must verify request handling, retention obligations, integrations, exports, AI logs, backups and isolated restore behavior before this readiness check can pass. See [EDPB guidance](https://www.edpb.europa.eu/sme/be-compliant/respect-individuals-rights_en) and [Salesforce Recycle Bin behavior](https://help.salesforce.com/s/articleView?id=home_delete.htm&language=en_US&type=5).

## Use the same check with an agent

With the supplied skill and restricted connection configured, ask:

> Check the Contact records I can access in this Salesforce org. Explain the data-quality findings and recommended next steps in Salesforce administrator language. Do not retrieve personal information. Make clear which safeguards and staff checks remain unassessed.

To offer this through an internal Agentforce assistant, follow [Add the readiness check to Agentforce](references/agentforce-setup.md). The screen and the Agentforce-compatible action share the same assessment code. The button runs that action's assessment logic directly; it does not start an AI conversation or execute Python on your computer. Assistant activation still requires the right features/licenses and separate conversation checks.

The Salesforce Task priority field normally uses High / Normal / Low. Critical and High assessment items use High, Medium uses Normal, and Low uses Low. Each task description preserves the exact assessment priority and impact explanation.

## Setup and repeatable checks

These commands are for the person maintaining the practice environment. Run them from this project folder:

```sh
# Open the prepared Salesforce app.
sf org open --target-org nonprofit-readiness-demo --path lightning/app/c__Nonprofit_AI_Readiness

# Demonstrate fictional data, safeguard, and staff outcomes separately.
python3 scripts/run_demo.py

# Repeat the sample data checks through the restricted connection.
python3 scripts/run_demo.py --live

# Verify the screen/Agentforce action agrees with the connected assessment.
python3 scripts/test_salesforce_action.py

# Run all automated checks, including Salesforce and the fictional deletion exercise.
python3 scripts/check_all.py --live

# Run only local checks, without touching Salesforce.
python3 scripts/check_all.py
```

For fresh setup:

```sh
python3 scripts/scratch_demo.py create --hub <your-dev-hub>
python3 scripts/scratch_demo.py seed
python3 scripts/scratch_demo.py deploy
```

The install step also runs the Salesforce action tests and gives the signed-in test user **Readiness Assessor** access. Other users need that permission set plus normal access to the records. The separate **Readiness Follow Up** permission set allows the optional task creation; it is not needed to run a read-only assessment. Avoid creating follow-ups simultaneously in multiple sessions, which can create duplicates. The scripts verify the saved practice org before setup changes. Detailed connection settings are in [the demonstration guide](demo/GUIDE.md).

This is an initial Contact data-readiness assessment, not a complete nonprofit or security audit. NPSP, staff demonstrations, a complete organization readiness score, and production-scale validation remain outside the verified scope.


## Demonstrate failures and the resulting actions

Run `python3 scripts/demo_failures.py` from the project folder. It compares fictional data and safeguard failures, seven failed staff exercises, and 14 failed erasure checks covering integrations, logs, backups, exports, repeat synchronization, and retention approval. Each produces prioritized next steps. Results are saved in `.local/failure-demo-results.json`; none are evidence about the real org.

Compare staff improvement with `python3 scripts/staff_readiness.py evaluate demo/staff-ready.json`. For an actual staff review, start with `python3 scripts/staff_readiness.py template`; a reviewer must confirm observed actions and supply an opaque evidence reference. Never substitute demo answers for staff observations.

The versioned scoring rules are in `demo/rubric.json`. The erasure checklist measures evidence coverage and keeps overall erasure unassessed until actual systems and outcomes have been verified. Importing demo records cannot turn off safeguards or establish erasure readiness.

For visible failures in the actual practice-org screen, run `python3 scripts/seed_failure_demo.py`, then choose **Run assessment** in Salesforce. This adds 60 fictional contacts with missing email addresses, repeated emails, and missing account relationships. It verifies the disposable org first, preserves the five original practice groups, and skips a complete previous import. It deliberately lowers the organization-wide score. The small-sample failure is demonstrated separately by the `poor` example; a sufficiently large dataset cannot also fail that check. Staff, safeguards, and external erasure failures remain separately labelled simulations, rather than weakening real org protections.


### Confirm that correcting the data improves the result

Run `python3 scripts/check_data_improvement.py` after importing the fictional failure contacts. It measures the baseline, temporarily fixes only those 60 fictional contacts, checks the score improvement, and restores the original demonstration values. Use the practice org without other people editing its demo records during this exercise. Do not run an assessment demonstration or create follow-up tasks until restoration finishes.

If interrupted, follow the saved recovery instructions and run `python3 scripts/check_data_improvement.py --restore`. The script verifies the same disposable org and fixed fictional record set before restoring. The saved recovery file stays in ignored `.local/`.

The complete `python3 scripts/check_all.py --live` command now ensures the failure contacts exist and includes this correction/restoration exercise as well as the fictional source-deletion check. These checks intentionally change practice records; ordinary **Run assessment** remains read-only.

### Run the assistant inside Salesforce

The Agentforce demonstration uses a separate practice org that also includes the readiness page and fictional data. Prepare it with:

```sh
python3 scripts/setup_agentforce_demo.py --hub YOUR_DEV_HUB
python3 scripts/check_agentforce_action.py
```

The second command tests the activated assistant through its native Salesforce action. The results show a 25% data score: one of four checks passed, while all four checks completed. Read the saved responses before accepting conversational behavior. For the full combined run, use `python3 scripts/check_all.py --live --agentforce` after both practice orgs are prepared.

See [the assistant walkthrough](references/agentforce-next-steps.md) for prerequisites, current limits, and the separate authoring-preview check.
