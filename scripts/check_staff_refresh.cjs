const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.js'), 'utf8')
    .replace(/^import .*;$/gm, '').replace('export default class NonprofitAIReadiness', 'class NonprofitAIReadiness').replace(/^\s*@wire\([^\n]+\)\s*$/gm, '');
async function check() {
    let finishOld;
    let calls = 0;
    const oldReview = { staff: { score: 100, coverage: 100 }, critical_failures: [] };
    const newReview = { staff: { score: 85.7, coverage: 100 }, critical_failures: ['scope:unapproved_decision'] };
    const Component = vm.runInNewContext(source + '\nNonprofitAIReadiness', {
        LightningElement: class {}, NavigationMixin: base => base,
        hasFollowUpPermission: false,
        assess: () => ++calls === 1 ? new Promise(resolve => { finishOld = resolve; }) : Promise.resolve(JSON.stringify({staff_review: newReview})),
        capabilityInventory: () => Promise.resolve('{}'),
        assessOrgConfiguration: () => Promise.resolve('{}')
    });
    const screen = new Component();
    const pending = screen.handleRun();
    assert.equal(screen.loading, true);
    finishOld(JSON.stringify({staff_review: oldReview}));
    await pending;
    assert.equal(calls, 1);
    assert.equal(screen.staffReview.staff.score, 100);
    // Staff observations live on a separate standard app page; a new assessment must reread them.
    await screen.handleRun();
    assert.equal(calls, 2, 'A new assessment collects the latest saved staff observations');
    assert.equal(screen.staffReview.staff.score, 85.7);
    assert.equal(screen.result.staff_review.critical_failures[0], 'scope:unapproved_decision');
    assert.match(screen.banner, /blocks a pilot/);
    assert.equal(screen.loading, false);
    let taskCalls = 0;
    for (const permitted of [false, true]) {
        const TaskComponent = vm.runInNewContext(source + '\nNonprofitAIReadiness', {
            LightningElement: class {}, NavigationMixin: base => base, hasFollowUpPermission: permitted,
            createFollowUpTasks: async () => {
                taskCalls++;
                return JSON.stringify({created: 1, reused: 0});
            }
        });
        const taskScreen = new TaskComponent();
        taskScreen.result = {data: {checks: {}}, privacy: {suppressed: false}};
        assert.equal(taskScreen.canCreateFollowUp, permitted);
        assert.equal(taskScreen.tasksDisabled, !permitted);
        await taskScreen.handleCreateTasks();
        assert.equal(taskCalls, permitted ? 1 : 0, 'No custom permission must mean no Task Apex call');
        assert.equal(taskScreen.taskError, undefined);
        if (permitted) assert.match(taskScreen.taskMessage, /Created 1 tasks/);
        else assert.equal(taskScreen.taskMessage, undefined);
    }
    console.log('PASS — task creation requires the dedicated custom permission before calling Apex');
    console.log('PASS — a new assessment rereads saved staff evidence and critical failures');
}
check().catch(error => { console.error(error); process.exitCode = 1; });
