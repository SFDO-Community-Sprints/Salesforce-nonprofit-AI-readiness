# Run the in-org readiness assistant

The project includes a reviewed Employee agent with one read-only assessment action. It runs the current Contact assessment before answering. The deterministic Salesforce result supplies the score, check counts, priorities, and limitations.

Use a disposable practice org with fictional data. The separate Agentforce practice org also contains the AI Readiness results page and the same demonstration records. The original practice org remains available for the restricted connection demo.

## Prepare the Agentforce practice org

Requires Salesforce CLI, an authenticated Dev Hub, and access to the requested scratch features.

```sh
python3 scripts/setup_agentforce_demo.py --hub YOUR_DEV_HUB
```

The setup uses `references/nonprofit-agentforce-scratch-def.json`, creates the separate seven-day practice org, verifies its identity, imports the fictional examples, deploys and tests the readiness page/action, then validates, publishes, and activates the supplied agent. It saves the target locally in ignored `.local/agentforce-scratch.json`. The original connection target stays unchanged.

Repeating setup reuses the verified org and existing fictional records. Publishing creates a new agent version. Run it without other people editing the demonstration records. The setup does not assign the optional follow-up Task permission to the agent.

Salesforce documents the required generative AI scratch feature and settings in its [scratch-org setup guide](https://developer.salesforce.com/docs/ai/agentforce/guide/scratch-org.html). Available features, consumption allowances and account terms must be established for your own Dev Hub; the repository does not supply them.

## Test the activated agent

From the project folder:

```sh
python3 scripts/check_agentforce_action.py
```

This sends five fixed fictional demonstration prompts to the activated agent through its native Salesforce action. It checks the expected 25% score, one passing check, four completed checks, and the absence of known fictional personal values. It saves responses in ignored `.local/agentforce-action-results.json` for review.

Review the raw-record, export, arbitrary-query and invented-readiness responses. Confirm that untested staff, safeguards and complete erasure remain unassessed. The native action response does not include an action trace, and a string check cannot establish every possible refusal or future model response.

For all automated checks, including the original practice org and activated assistant:

```sh
python3 scripts/check_all.py --live --agentforce
```

The live checks intentionally create fictional records, temporarily correct and restore the failure data, and soft-delete one fictional Contact. Ordinary **Run assessment** remains read-only.

## Test changes to the assistant before publishing

The reviewed source is in `agentforce/main/default/aiAuthoringBundles/Nonprofit_Readiness/`. Use the included source rather than generating unrelated default actions.

```sh
python3 scripts/check_agentforce_preview.py
```

This previews the local authoring draft with real assessment actions, ends its session, and checks the completed trace. Only the fixed organization assessment action is permitted. Saved transcripts and traces stay local. Previewing a draft, publishing, activating, and observing a published conversation are separate pieces of evidence.

## Employee-agent preview limitation

The installed Salesforce CLI's published-agent preview starts a session with `bypassUser: true`. This fails for this Employee agent with “Invalid user ID provided on start session.” Salesforce specifies `bypassUser: false` so Employee agents use the authenticated user's identity. See [Salesforce's troubleshooting guidance](https://help.salesforce.com/s/articleView?id=005167079&language=en_US&type=1).

The supported test above calls the generated `generateAiAgentResponse/Nonprofit_Readiness` action in the signed-in user's context. Salesforce documents this [in-org action path](https://developer.salesforce.com/blogs/2025/04/invoke-agentforce-agents-with-apex-and-flow). No vendor software patch or broader runtime permissions are required.

The optional beta `agent test run-eval` command produced no result during a verified 20-minute wait. Its local client was interrupted; no evaluation pass or remote cancellation is claimed. Use the recorded live conversation evidence and keep this experimental evaluation separate.

## Current limits

The demonstrated conversations used the practice administrator and fictional data. Intended employee permissions, access to the assistant in the normal Salesforce interface, staff competency, production processing, complete erasure and retention still need their own evidence. Activation alone does not establish employee access or organizational readiness.
