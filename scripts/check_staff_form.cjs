const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../force-app/main/default/lwc/readinessStaffReview/readinessStaffReview.js'), 'utf8');
const start = source.indexOf('function buildSnapshot(');
const end = source.indexOf('export default class', start);
const build = vm.runInNewContext(source.slice(start, end) + '\nbuildSnapshot');
const key = JSON.parse(fs.readFileSync(path.join(__dirname, '../references/staff-answer-key.json'), 'utf8'));
function form(value) {
    return key.questions.map(question => ({...question, reviewer_confirmed: false, evidence_ref: '',
        required_actions: question.required_actions.map(action => ({...action, value})),
        critical_failures: question.critical_failures.map(failure => ({...failure, checked: false}))}));
}
for (const status of ['yes', 'partly', 'no', 'unknown']) {
    const result = build(key.version, form(status));
    assert.equal(result.mode, 'actual');
    assert.equal(result.reviews.length, 7);
    assert(result.reviews.every(review => review.answer === status));
    assert(result.reviews.every(review => review.evidence_ref === null && review.reviewer_confirmed === false));
}
const questions = form('yes');
questions[0].required_actions[0].value = 'no';
questions[0].evidence_ref = 'TRAINING-001';
questions[0].reviewer_confirmed = true;
questions[0].critical_failures[0].checked = true;
const result = JSON.parse(JSON.stringify(build(key.version, questions)));
assert.equal(result.reviews[0].answer, 'no');
assert.equal(result.reviews[0].evidence_ref, 'TRAINING-001');
assert.equal(result.reviews[0].reviewer_confirmed, true);
assert.deepEqual(result.reviews[0].critical_failures, [key.questions[0].critical_failures[0].id]);
assert(!JSON.stringify(result).includes('criterion'));
assert(!JSON.stringify(result).includes('scenario'));
const evaluated = require('node:child_process').spawnSync('python3', ['-c',
    'import json,sys; sys.path.insert(0,sys.argv[1]); from staff_readiness import evaluate; print(json.dumps(evaluate(json.load(sys.stdin))))',
    __dirname], {input: JSON.stringify(result), encoding: 'utf8'});
assert.equal(evaluated.status, 0, 'Canonical form snapshot must be accepted by the evaluator');
const evidence = JSON.parse(evaluated.stdout);
assert.equal(evidence.decision, 'blocked_by_observed_critical_failure');
assert.equal(evidence.staff.checks.scope, 'fail');
assert.equal(evidence.staff.checks.sensitive_data, 'unknown', 'Answers alone cannot prove competence');
assert.equal(evidence.staff.coverage, '14.3');
const datedQuestions = form('yes');
for (const question of datedQuestions) {
    question.reviewer_confirmed = true;
    question.evidence_ref = 'TRAINING-001';
}
datedQuestions[0].observed_on = '2026-09-19';
datedQuestions[1].observed_on = '2026-09-18';
const dated = JSON.parse(JSON.stringify(build(key.version, datedQuestions, {asOf: '2026-10-19', maxAgeDays: '30'})));
assert.deepEqual(dated.freshness_policy, {as_of: '2026-10-19', max_age_days: 30,
    observed_on: {scope: '2026-09-19', sensitive_data: '2026-09-18'}});
assert(!Object.hasOwn(build(key.version, datedQuestions), 'freshness_policy'));
const datedOutput = require('node:child_process').spawnSync('python3', ['-c',
    'import json,sys; sys.path.insert(0,sys.argv[1]); from staff_readiness import evaluate; print(json.dumps(evaluate(json.load(sys.stdin))))',
    __dirname], {input: JSON.stringify(dated), encoding: 'utf8'});
assert.equal(datedOutput.status, 0);
const datedResult = JSON.parse(datedOutput.stdout);
assert.equal(datedResult.staff.checks.scope, 'pass');
assert.equal(datedResult.staff.checks.sensitive_data, 'unknown');
assert.equal(datedResult.staff.checks.quality, 'unknown');
console.log('Staff review form mapping, opt-in freshness and evaluator checks passed.');

async function checkRoleLoading() {
    const componentSource = source.replace(/^import .*;\n/gm, '').replace('export default class', 'class');
    const latest = {staff: {score: '0.0', coverage: '0.0', checks: Object.fromEntries(key.questions.map(q => [q.id, 'unknown']))},
        freshness: {as_of: '2026-10-20', max_age_days: 30}};
    for (const role of ['none', 'reader', 'reviewer']) {
        const calls = [];
        const Component = vm.runInNewContext(componentSource + '\nReadinessStaffReview;', {
            LightningElement: class {
                events = [];
                dispatchEvent(event) { this.events.push(event); }
            },
            CustomEvent: class { constructor(type, options) { this.type = type; this.detail = options.detail; } },
            hasReadPermission: role === 'reader', hasReviewPermission: role === 'reviewer',
            getQuestions: async () => { calls.push('questions'); return JSON.stringify(key); },
            getLatestReview: async () => { calls.push('latest'); return JSON.stringify(latest); },
            saveReview: async () => { calls.push('save'); throw new Error('Unexpected save'); }
        });
        const component = new Component();
        await component.connectedCallback();
        assert.equal(component.loading, false);
        assert.equal(component.error, undefined);
        assert.equal(component.canReview, role === 'reviewer');
        assert.equal(component.canRead, role !== 'none');
        assert.equal(component.questions.length, role === 'reviewer' ? 7 : 0);
        assert.equal(component.events.length, 1);
        if (role === 'none') {
            assert.deepEqual(calls, [], 'Assessor-only users must not call inaccessible staff Apex');
            assert.equal(component.events[0].detail, null);
            assert.equal(component.latest, null);
        } else {
            assert.deepEqual(calls, role === 'reviewer' ? ['questions', 'latest'] : ['latest']);
            assert.equal(component.latest.staff.coverage, '0.0');
            assert(component.freshnessSummary.includes('2026-10-20'));
        }
        if (role !== 'reviewer') {
            const before = calls.length;
            await component.save();
            assert.equal(calls.length, before, 'Non-reviewer saves must stop before template access or Apex');
        }
    }
    console.log('Staff role loading checks passed: no access calls no Apex; readers load summaries only.');
}
checkRoleLoading().catch(error => { console.error(error); process.exitCode = 1; });
