const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.js', 'utf8')
    .replace(/^import .*;$/gm, '').replace('export default class', 'class');
let liveCalls = 0, taskCalls = 0, response;
const Component = vm.runInNewContext(source + '\nNonprofitAIReadiness', {
    LightningElement: class {}, hasFollowUpPermission: true,
    assess: async () => { liveCalls++; return '{}'; },
    capabilityInventory: async () => { liveCalls++; return '{}'; },
    createFollowUpTasks: async () => { taskCalls++; return '{}'; },
    getScenario: async () => JSON.stringify(response)
});
(async () => {
    const screen = new Component();
    assert.equal(screen.isLive, true, 'Live organization is default');
    assert.equal(screen.scenarioOptions.length, 6);
    for (const scenario of ['poor', 'improving', 'blocked', 'pilot', 'unknown']) {
        const assessment = JSON.parse(fs.readFileSync(`demo/${scenario}/expected.json`));
        response = { mode: 'simulation', scenario, assessment, erasure: { unknown_checks: 2, checks: [{category: 'backups', probe_id: 'restore_no_reintroduction', status: 'simulated_failed'}] } };
        screen.handleScenarioChange({detail: {value: scenario}});
        await screen.handleRun();
        assert.equal(screen.result.staff.score, assessment.staff.score);
        assert.equal(screen.demoStaffChecks.length, 7);
        assert.equal(screen.demoErasureChecks[0].status, 'Needs attention');
        assert.match(screen.staffScore, /Simulation:/);
        assert.match(screen.safeguardsLabel, /Simulation:/);
        assert.match(screen.banner, /do not assess this organization/);
        assert.equal(screen.recommendations.length, assessment.priorities.length);
        assert.equal(screen.tasksDisabled, true);
        await screen.handleCreateTasks();
        await screen.handleStaffReview({ detail: {staff: { score: 100 }} });
        screen.handleEvidenceReview({detail: {kind: 'safeguards', result: {mode: 'actual'}}});
        assert.equal(screen.staffReview, undefined);
        assert.equal(screen.safeguardEvidence, undefined);
    }
    assert.equal(liveCalls, 0, 'Simulation must not scan real org or refresh real staff results');
    assert.equal(taskCalls, 0, 'Simulation must not create tasks');
    response = {error: 'demo_not_seeded'};
    await screen.handleRun();
    assert.equal(screen.result, undefined);
    assert.match(screen.error, /seed-demo.apex/);
    screen.loading = true;
    screen.handleScenarioChange({detail: {value: 'organization'}});
    assert.equal(screen.isDemo, true, 'Cannot change source while a request is pending');
    screen.loading = false;
    screen.handleScenarioChange({detail: {value: 'organization'}});
    assert.equal(screen.isLive, true);
    assert.equal(screen.demoScenario, undefined);
    const html = fs.readFileSync('force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.html', 'utf8');
    assert.match(html, /<template lwc:if=\{isLive\}><c-readiness-evidence/);
    assert.match(html, /Simulated staff readiness exercises/);
    console.log('Demo scenario UI boundaries passed');
})().catch(error => { console.error(error); process.exitCode = 1; });
