const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const original = fs.readFileSync('force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.js', 'utf8');
const source = original.replace(/^import .*;$/gm, '').replace('export default class', 'class').replace(/^\s*@wire\([^\n]+\)\s*$/gm, '');
let inventoryCalls = 0, configurationCalls = 0, taskCalls = 0, response;
let configuration = {version: 'v1', scope: 'organization', observed_at: 'now', access: {score: 25, coverage: 100, checks: [{id: 'role', label: 'Role', status: 'fail', basis: 'ObjectPermissions'}]}, privacy: {score: 75, coverage: 100, checks: []}};
const scopes = [];
const Component = vm.runInNewContext(source + '\nNonprofitAIReadiness', {
    LightningElement: class {}, NavigationMixin: base => base, hasFollowUpPermission: true,
    assess: async request => { scopes.push(request.scenario); return JSON.stringify(response); },
    capabilityInventory: async () => { inventoryCalls++; return '{}'; },
    assessOrgConfiguration: async () => { configurationCalls++; return JSON.stringify(configuration); },
    createFollowUpTasks: async () => { taskCalls++; return '{}'; }
});
(async () => {
    const screen = new Component();
    assert.equal(screen.isOrganizationScope, true);
    assert.equal(screen.scenarioOptions.length, 6);
    for (const scenario of ['organization', 'poor', 'improving', 'blocked', 'pilot', 'unknown']) {
        screen.handleScenarioChange({detail: {value: scenario}});
        // The backend score deliberately contradicts any expected preset score.
        response = { data: { score: 37, coverage: 100, checks: {} }, metrics: { contacts: 12 }, privacy: { suppressed: false }, staff_review: {staff: {score: 63, coverage: 100}} };
        await screen.handleRun();
        assert.equal(scopes.at(-1), scenario);
        assert.equal(screen.score, '37%');
        assert.equal(screen.staffScore, '63%');
        assert.equal(screen.safeguardsLabel, 'See org health findings');
        assert.equal(screen.erasureLabel, 'Incomplete');
        assert.equal(screen.configurationChecks[0].statusLabel, 'Needs attention');
        assert.equal(screen.configurationChecks[0].basis, 'ObjectPermissions');
        assert.equal(screen.tasksDisabled, scenario !== 'organization');
        if (scenario !== 'organization') await screen.handleCreateTasks();
    }
    assert.equal(inventoryCalls, 6, 'Every scope scans org capability inventory');
    assert.equal(configurationCalls, 6, 'Every scope scans actual organization configuration');
    screen.staffReview = {provenance: 'seeded_practice', staff: {score: 22}};
    assert.equal(screen.staffScore, 'Practice answers: 22%');
    assert.match(screen.staffCoverage, /no observed staff competency/);
    for (const inaccessible of [null, {error: 'denied'}]) {
        configuration = inaccessible;
        await screen.handleRun();
        assert.equal(screen.safeguardsLabel, 'See org health findings');
        assert.equal(screen.erasureLabel, 'Incomplete');
        assert.match(screen.orgConfigurationError, /not assessed/);
    }
    assert.equal(taskCalls, 0, 'Contact subsets must not create organization tasks');
    response = {data: {score: null, coverage: null}, privacy: {suppressed: true}};
    await screen.handleRun();
    assert.equal(screen.score, 'Not assessed');
    assert.equal(screen.hasMetrics, false);
    assert.equal(screen.tasksDisabled, true);
    screen.loading = true;
    screen.handleScenarioChange({detail: {value: 'organization'}});
    assert.equal(screen.scenario, 'unknown', 'Cannot change scope during assessment');
    screen.loading = false;
    response = {error: 'unavailable'};
    await screen.handleRun();
    assert.equal(screen.result, undefined);
    assert.match(screen.error, /Assessment unavailable/);
    assert.doesNotMatch(original, /getScenario|demoScenario|expected\.json|Simulation:/);
    const html = fs.readFileSync('force-app/main/default/lwc/nonprofitAIReadiness/nonprofitAIReadiness.html', 'utf8');
    assert.match(html, /Contact data scope/);
    for (const embedded of ['c-readiness-evidence', 'c-readiness-staff-review', 'c-readiness-verification', 'c-readiness-workspace']) assert(!html.includes(embedded), `${embedded} belongs on a standard app page`);
    assert.doesNotMatch(html, /isLive|isDemo|Simulated/);
    console.log('Live Contact scope UI checks passed');
})().catch(error => { console.error(error); process.exitCode = 1; });
