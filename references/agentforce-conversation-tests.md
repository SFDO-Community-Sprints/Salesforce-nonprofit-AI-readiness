# Live Agentforce conversation checks

This spec calls the published Agentforce agent, not a mocked assistant. Run only against the dedicated synthetic scratch org after publishing the single-action agent and loading the original 34 contacts plus the 60-contact failure seed. The expected live baseline is **94 contacts, 25% data quality**. Reconcile that baseline with the Apex assessment before running; ordinary seed or visibility changes require updating the expected case.

```sh
sf agent test run-eval --spec agentforce/tests/readiness-conversation.yaml --api-name Nonprofit_Readiness --target-org nonprofit-readiness-agent-test --result-format json > .local/agentforce-conversation-results.json
```

The installed CLI supports this beta command and the legacy YAML schema. Local installed `@salesforce/agents` types and translator were inspected: `expectedTopic`, nonempty `expectedActions`, `expectedOutcome`, and `customEvaluations` with `string_comparison`, `operator=contains`, and `actual=$.generatedData.outcome` are translated. The local spec parses and translates successfully; that is not a live conversation pass.

The first case requires the `readiness` subagent and `assess_organization` binding from the checked-in Agent Script, plus an exact `25%` response string. Published planner action identifiers can differ: verify the actual action identifier from the first live trace and change the expected identifier only to the published equivalent. Do not remove the action assertion to get a pass. A response saying `25 percent` instead of `25%` deliberately fails the exact string check; inspect that formatting failure separately from a wrong measurement.

The other cases exercise personal-data, export, arbitrary-SOQL and invented-readiness refusals. **An empty expectedActions list is skipped by the installed run-eval translator; it does not assert that no action ran.** Inspect recorded planner actions for these cases and require that no export, arbitrary query or write action occurred. This agent exposes only the fixed read-only assessment action. Refusal wording uses Salesforce's semantic outcome evaluator and is not a deterministic security proof. Keep Apex permission tests, aggregate allowlists and sentinel tests as separate enforcement evidence.

CLI exit zero means evaluation execution succeeded, not that every assertion passed. Inspect every returned scorer result, invoked action and response. Keep synthetic conversation logs in `.local/`; do not introduce real personal records into test prompts.

Alternative installed Testing Center workflow (writes test metadata; not executed as part of preparing this file):

```sh
sf agent test create --spec agentforce/tests/readiness-conversation.yaml --api-name Nonprofit_Readiness_Live_Tests --target-org nonprofit-readiness-agent-test
sf agent test run --api-name Nonprofit_Readiness_Live_Tests --target-org nonprofit-readiness-agent-test --result-format json --output-dir .local/agentforce-tests
sf agent test results --job-id REPLACE_WITH_RETURNED_JOB_ID --target-org nonprofit-readiness-agent-test --result-format json --output-dir .local/agentforce-tests
```

Use the actual job ID; run defaults to asynchronous execution. The installed results command requires `--job-id`, despite help prose mentioning an unsupported recent-run flag.

Sources: [Salesforce test spec reference](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-reference.html), [official CLI run-eval reference](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_agent_test_run-eval.html), [Salesforce agents TestSpec API](https://forcedotcom.github.io/agents/types/types.TestSpec.html).
