const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../metadata/main/default/lwc/readinessStaffReview/readinessStaffReview.js'), 'utf8');
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
console.log('Staff review form mapping and evaluator checks passed.');
