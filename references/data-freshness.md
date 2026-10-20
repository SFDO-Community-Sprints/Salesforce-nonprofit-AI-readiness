# Aggregate data freshness

`scripts/data_freshness.py` measures a separately approved freshness policy without changing the fixed four-check Salesforce/MCP demo rubric. This offline evaluator does not establish customer approval or a pilot decision. A separate fixed scratch collector is described below. Native org collection is available through `ReadinessDataFreshness.assess` and the additional checks form.

Run `python3 scripts/data_freshness.py snapshot.json` with this aggregate-only shape:

```json
{
  "version": "data-freshness-v1",
  "as_of": "2026-10-19T00:00:00Z",
  "policy": {
    "version": "example-policy-v1",
    "window_days": 90,
    "minimum_recent_percent": 90,
    "minimum_cohort": 5
  },
  "metrics": {
    "records": 10,
    "recent_records": 9,
    "window_days": 90,
    "as_of": "2026-10-19T00:00:00Z"
  }
}
```

These values are illustrative, not default customer requirements. The assessment owner must approve the relevant object, activity meaning, date field and window before collection. A record modification timestamp alone does not prove a donor relationship is current. Define the observation window as activity at or after `as_of - window_days` and at or before `as_of`; exclude future activity. Record that collection definition and its query version with the trusted source evidence. This offline input has counts only and cannot verify how a collector obtained them.

The count threshold uses exact integer comparison. Metrics must match the policy window and assessment instant. Missing metrics and cohorts below the explicit suppression threshold (at least five) remain unknown and return no counts. Unexpected fields, invalid counts and timezone-free timestamps are rejected. The output contains the policy and assessment timestamp for replay; it never establishes overall readiness. Do not supply record values, field contents, or personal identifiers.

Still required: approved customer profile and dedicated MCP expansion if requested. The native Salesforce form uses the same explicit policy and suppression rules. The fixed scratch activity collector below does not establish the correct freshness definition for a customer. Do not merge this result into the existing demo scores silently.

## Fixed read-only scratch collection

`python3 scripts/collect_data_freshness.py policy.json --as-of 2026-10-19T00:00:00Z` reads only Contact counts and counts with `LastActivityDate` in the explicit inclusive calendar-date window. `policy.json` contains exactly the four policy fields above. The assessment instant must be a non-future UTC midnight. No field, object, target-org or query override is accepted; the saved disposable org is verified before queries. The output records accessible-Contact scope, collection timestamp and query version. Unknown/denied collection fails with a sanitized message and never a pass. This is a separate developer validation command, not an additional MCP tool.

The first live fictional-data run used an illustrative 90-day/90% policy: 94 accessible Contacts, zero with recent activity, therefore freshness failed. This observation is deliberately separate from the existing four-check data score. It demonstrates LastActivityDate measurement, not real donor activity or approved customer thresholds. The aggregate result is retained in ignored `.local/freshness-results.json`. No records were changed.

## Native Salesforce assessment

After assigning Readiness Assessor, open AI Readiness → Additional readiness checks → Data freshness. Supply the approved policy version, window days, percentage and cohort size (at least five). Confirm the policy and select Assess data freshness. `ReadinessDataFreshness` collects accessible Contact aggregates over inclusive UTC calendar dates using `LastActivityDate`, with no data writes. Missing access or small cohorts remain Not assessed. This separate result does not silently change the original four data checks. No Python or post-deployment data seeding is required.
