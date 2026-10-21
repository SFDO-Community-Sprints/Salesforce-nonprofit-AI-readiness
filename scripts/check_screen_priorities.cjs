// Exercise the actual screen priority function without a Salesforce browser session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.js'), 'utf8');
const start = source.indexOf('function priorityDetails(');
const end = source.indexOf('export default class', start);
assert(start >= 0 && end > start, 'Screen priority function must be available');
const priority = vm.runInNewContext(source.slice(start, end) + '\npriorityDetails');
const profile = JSON.parse(fs.readFileSync(path.join(__dirname, '../demo/rubric.json'), 'utf8'));
const thresholds = profile.thresholds;
const priorityRules = profile.priority;
assert.equal(priority('controls').priority, priorityRules.unverified_controls);
assert.equal(priority('erasure').priority, priorityRules.unverified_privacy_erasure);
assert.equal(priority('staff').priority, priorityRules.unverified_staff);
assert.equal(priority('sufficient_data', {contacts: thresholds.minimum_contacts - 1}).priority, priorityRules.insufficient_data);

// Execute both implementations on either side of each machine-profile boundary.
const cases = [];
for (const offset of [-1, 0, 1]) {
    const base = {contacts: 100, email_present: 100, linked_contacts: 100, repeated_email_rows: 0};
    cases.push({key: 'email_completeness', metrics: {...base, email_present: thresholds.email_high_below_percent + offset},
        expected: offset < 0 ? priorityRules.data_threshold_exceeded : priorityRules.data_default});
    cases.push({key: 'duplicate_indicator', metrics: {...base, repeated_email_rows: thresholds.duplicate_high_at_least_percent + offset},
        expected: offset >= 0 ? priorityRules.data_threshold_exceeded : priorityRules.data_default});
    cases.push({key: 'account_linkage', metrics: {...base, linked_contacts: 100 - thresholds.unlinked_high_above_percent - offset},
        expected: offset > 0 ? priorityRules.data_threshold_exceeded : priorityRules.data_default});
}
const python = require('node:child_process').spawnSync('python3', ['-c', `
import json, sys
sys.path.insert(0, sys.argv[1])
from demo import recommendations, data_checks
from privacy import build_data_result
payload=json.load(sys.stdin)
results=[]
for case in payload['cases']:
    results.append(next(item['priority'] for item in recommendations(case['metrics']) if item['key']==case['key']))
checks=[]
for metrics in payload['checks']:
    checks.append(data_checks(metrics))
privacy=[]
for metrics in payload['privacy']:
    result=build_data_result(metrics)
    privacy.append({'suppressed':result['privacy']['suppressed'],'score':result['data']['score']})
print(json.dumps({'priorities':results,'checks':checks,'privacy':privacy}))
`, __dirname], {input: JSON.stringify({cases,
    checks: [
        {contacts: thresholds.minimum_contacts - 1, email_present: thresholds.minimum_contacts - 1, linked_contacts: thresholds.minimum_contacts - 1, repeated_email_rows: 0},
        {contacts: thresholds.minimum_contacts, email_present: thresholds.minimum_contacts, linked_contacts: thresholds.minimum_contacts, repeated_email_rows: 0},
        {contacts: 100, email_present: thresholds.email_completeness_pass_percent - 1, linked_contacts: 100, repeated_email_rows: 0},
        {contacts: 100, email_present: thresholds.email_completeness_pass_percent, linked_contacts: 100, repeated_email_rows: 0},
        {contacts: 100, email_present: 100, linked_contacts: thresholds.account_linkage_pass_percent - 1, repeated_email_rows: 0},
        {contacts: 100, email_present: 100, linked_contacts: thresholds.account_linkage_pass_percent, repeated_email_rows: 0},
        {contacts: 100, email_present: 100, linked_contacts: 100, repeated_email_rows: thresholds.maximum_repeated_email_rows},
        {contacts: 100, email_present: 100, linked_contacts: 100, repeated_email_rows: thresholds.maximum_repeated_email_rows + 1}
    ],
    privacy: [-1, 0].map(offset => ({contacts: thresholds.minimum_privacy_cohort + offset,
        email_present: thresholds.minimum_privacy_cohort + offset,
        linked_contacts: thresholds.minimum_privacy_cohort + offset, repeated_email_rows: 0}))
}), encoding: 'utf8'});
assert.equal(python.status, 0, python.stderr || 'Python parity check failed');
const actual = JSON.parse(python.stdout);
cases.forEach((item, index) => {
    assert.equal(priority(item.key, item.metrics).priority, item.expected, `${item.key} screen/profile boundary ${index}`);
    assert.equal(actual.priorities[index], item.expected, `${item.key} Python/profile boundary ${index}`);
});
assert.equal(actual.checks[0].sufficient_data, 'fail');
assert.equal(actual.checks[1].sufficient_data, 'pass');
assert.equal(actual.checks[2].email_completeness, 'fail');
assert.equal(actual.checks[3].email_completeness, 'pass');
assert.equal(actual.checks[4].account_linkage, 'fail');
assert.equal(actual.checks[5].account_linkage, 'pass');
assert.equal(actual.checks[6].duplicate_indicator, 'pass');
assert.equal(actual.checks[7].duplicate_indicator, 'fail');
assert.equal(actual.privacy[0].suppressed, true);
assert.equal(actual.privacy[0].score, profile.privacy.suppressed_score);
assert.equal(actual.privacy[1].suppressed, false);
console.log('PASS — machine profile agrees with actual screen/Python priorities, scoring boundaries and privacy suppression');

const jumpMethod = source.match(/    handleViewActions\(\) \{[\s\S]*?\n    \}/);
assert(jumpMethod, 'Screen action shortcut must be available');
for (const reduced of [false, true]) {
    const calls = [];
    const heading = {
        scrollIntoView(options) { calls.push(['scroll', options.behavior, options.block]); },
        focus(options) { calls.push(['focus', options.preventScroll]); }
    };
    const jump = vm.runInNewContext('({' + jumpMethod[0].trim() + '}).handleViewActions', {
        window: {matchMedia(query) { assert.equal(query, '(prefers-reduced-motion: reduce)'); return {matches: reduced}; }}
    });
    jump.call({template: {querySelector(selector) { assert.equal(selector, '[data-actions-heading]'); return heading; }}});
    assert.deepEqual(calls, [['scroll', reduced ? 'auto' : 'smooth', 'start'], ['focus', true]]);
    jump.call({template: {querySelector() { return null; }}});
}
console.log('PASS — actions shortcut scrolls/focuses and respects reduced motion');
