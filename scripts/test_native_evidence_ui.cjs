// Exercise UI state boundaries without a Salesforce runtime.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessEvidence/readinessEvidence.js', 'utf8')
    .replace(/^import .*;\n/gm, '').replace('export default class', 'class') + '\nthis.Component = ReadinessEvidence;';
const calls = [];
let freshnessResponse = { freshness: { score: '100.0', coverage: '100.0' }, reason: 'measured' };
const context = {
    LightningElement: class { dispatchEvent(event) { calls.push(event); } },
    CustomEvent: class { constructor(type, data) { this.type = type; this.detail = data.detail; } },
    canReview: true,
    assessFreshness: async request => { calls.push(request); return JSON.stringify(freshnessResponse); },
    evaluateSafeguards: async request => { calls.push(request); return JSON.stringify({ mode: 'actual', score: 0, coverage: 0, checks: { approval: 'unknown' } }); },
    evaluateErasure: async () => JSON.stringify({ mode: 'simulation', follow_ups: [] })
};
vm.runInNewContext(source, context);
(async () => {
    const component = new context.Component();
    component.template = { querySelectorAll: () => [{ reportValidity: () => true }] };
    assert.equal(component.approvedPolicy, false);
    assert.equal(component.windowDays, '');
    await component.assess();
    assert.equal(calls.length, 0, 'No approved policy means no scan');
    Object.assign(component, { approvedPolicy: true, policyVersion: 'approved_v1', windowDays: '90', minimumRecentPercent: '80', minimumCohort: '5' });
    await component.assess();
    assert.equal(calls[0].minimumRecentPercent, 80);
    assert.equal(component.freshnessResult.reason, 'measured');
    assert.match(component.freshnessSummary, /Freshness score: 100.0%/);
    for (const reason of ['missing_evidence', 'cohort_withheld']) {
        freshnessResponse = { freshness: { score: '0.0', coverage: '0.0' }, reason };
        await component.assess();
        assert.match(component.freshnessSummary, /Freshness score: Not assessed;/, reason);
        assert.doesNotMatch(component.freshnessSummary, /score: 0/);
    }
    assert.match(fs.readFileSync('force-app/main/default/lwc/readinessEvidence/readinessEvidence.html', 'utf8'), /Contact LastActivityDate over inclusive UTC calendar days/);
    freshnessResponse = { error: 'invalid_freshness_policy' };
    await component.assess();
    assert.equal(component.freshnessResult, undefined, 'Failed assessment clears stale score');
    await component.evaluate();
    assert.equal(calls.at(-1).detail.kind, 'safeguards');
    assert.equal(calls.at(-1).detail.result.mode, 'actual');
    assert.equal(JSON.parse(calls.at(-2).evidenceJson).evidence.length, 0, 'Unknown checks do not invent evidence');
    const changeCheck = (check, field, value, destination) => component.changeCheck({ target: { dataset: { check, field, destination } }, detail: { value } });
    changeCheck('approval', 'result', 'pass');
    assert.equal(calls.at(-1).detail.result, null, 'Editing clears parent evidence outcome');
    changeCheck('approval', 'evidence_ref', 'approval_01');
    changeCheck('approval', 'reviewer_ref', 'reviewer_01');
    assert.equal(component.buildEvidence().evidence[0].check_id, 'approval');
    assert.equal(component.buildEvidence().evidence[0].evidence_ref, 'approval_01');
    changeCheck('approval', 'result', 'unknown');
    assert.equal(component.buildEvidence().evidence.length, 0, 'Reset observation removes evidence');
    component.changeKind({ detail: { value: 'erasure' } });
    assert.equal(component.buildEvidence().systems.length, 0);
    component.addDestination();
    const key = component.destinations[0].key;
    const changeDestination = (field, value) => component.changeDestination({ target: { dataset: { destination: key, field } }, detail: { value } });
    for (const field of ['id', 'destination_ref', 'owner_ref', 'retention_policy_ref', 'privacy_approver_ref']) changeDestination(field, field + '_01');
    changeCheck('active_read_absent', 'result', 'pass', key);
    changeCheck('active_read_absent', 'evidence_ref', 'read_01', key);
    changeCheck('active_read_absent', 'reviewer_ref', 'reviewer_01', key);
    const inventory = component.buildEvidence();
    assert.equal(inventory.systems[0].owner_ref, 'owner_ref_01');
    assert.equal(inventory.evidence[0].result, 'observed');
    assert.equal(inventory.evidence[0].system_id, 'id_01');
    changeDestination('category', 'exports');
    assert.equal(component.buildEvidence().evidence.length, 0, 'Category change clears probes');
    assert.equal(component.destinations[0].probes[0].id, 'export_copy_absent');
    component.changeMode({ detail: { value: 'simulation' } });
    assert.equal(Object.keys(component.buildEvidence().systems[0]).sort().join(','), 'category,id', 'Simulation omits actual-only system fields');
    await component.evaluate();
    assert.match(component.evidenceSummary, /Simulation only/);
    component.removeDestination({ target: { dataset: { destination: key } } });
    assert.equal(component.buildEvidence().systems.length, 0);
    component.template = { querySelectorAll: () => [{ reportValidity: () => false }] };
    const beforeInvalid = calls.length;
    await component.evaluate();
    assert.equal(calls.length, beforeInvalid, 'Invalid references prevent evaluator invocation');
    component.template = { querySelectorAll: () => [{ reportValidity: () => true }] };
    assert.doesNotMatch(fs.readFileSync('force-app/main/default/lwc/readinessEvidence/readinessEvidence.html', 'utf8'), /lightning-textarea|Evidence JSON/);
    component.canReview = false;
    const before = calls.length;
    await component.evaluate();
    assert.equal(calls.length, before, 'Missing reviewer gate prevents UI invocation');
    console.log('Native evidence UI state checks passed');
})().catch(error => { console.error(error); process.exitCode = 1; });
