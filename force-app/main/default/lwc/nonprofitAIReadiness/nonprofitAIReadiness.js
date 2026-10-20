import { LightningElement } from 'lwc';
import hasFollowUpPermission from '@salesforce/customPermission/Readiness_Create_Follow_Up';
import assess from '@salesforce/apex/NonprofitAIReadiness.assessScenario';
import createFollowUpTasks from '@salesforce/apex/NonprofitAIReadiness.createFollowUpTasks';
import capabilityInventory from '@salesforce/apex/NonprofitAIReadiness.capabilityInventory';
import getScenario from '@salesforce/apex/ReadinessDemoScenarios.getScenario';

const LABELS = {
    sufficient_data: 'At least 10 contact records',
    email_completeness: 'At least 90% have email addresses',
    account_linkage: 'All contacts linked to accounts',
    duplicate_indicator: 'No repeated email addresses'
};
const STAFF = {
    scope: ['Approved scope', 'Keep grant awards and other consequential decisions with authorized people.'],
    sensitive_data: ['Sensitive data and deletion', 'Exclude sensitive notes and trace deletion across all retained copies.'],
    untrusted_content: ['Untrusted content', 'Reject embedded export instructions and unsupported donation claims.'],
    access: ['Assistant access', 'Test allowed and forbidden operations under the intended assistant identity.'],
    quality: ['Source quality', 'Flag conflicting or missing details without inventing or merging values.'],
    review: ['Human review', 'Reject unsafe messages and enforce approval before a send or change.'],
    incident: ['Incident response', 'Escalate unsafe behavior, stop the assistant and rehearse recovery.']
};
const CONTROL_LABELS = { prerequisites: 'Required prerequisites', runtime_access: 'Assistant access', approval: 'Human approval', export_block: 'Unapproved exports blocked', stop_control: 'Stop and recovery' };
function outcome(status) {
    if (status === 'pass' || status === 'observed' || status?.endsWith('_observed')) return 'Passed';
    return status === 'fail' || status === 'failed' || status?.endsWith('_failed') ? 'Needs attention' : 'Not assessed';
}
const LEARNING = {
    data: { url: 'https://trailhead.salesforce.com/content/learn/trails/prepare-your-data-for-ai', label: 'Prepare your data for AI' },
    duplicates: { url: 'https://trailhead.salesforce.com/content/learn/modules/sales_admin_duplicate_management/sales_admin_duplicate_management_unit_2', label: 'Learn how to manage duplicates' },
    controls: { url: 'https://trailhead.salesforce.com/content/learn/modules/data_security', label: 'Learn Salesforce data security' },
    erasure: { url: 'https://www.edpb.europa.eu/sme/be-compliant/respect-individuals-rights_en', label: 'Understand individual privacy rights' },
    staff: { url: 'https://trailhead.salesforce.com/content/learn/modules/trusted-agentic-ai/discover-how-salesforce-builds-trusted-agentic-ai', label: 'Learn about trusted AI agents' }
};
const ACTIONS = {
    sufficient_data: 'Confirm whether the available contacts represent the intended AI use. This check requires at least 10 records.',
    email_completeness: 'Review missing email addresses and complete them where appropriate for the intended use.',
    account_linkage: 'Review contacts without accounts and link them to the correct account where appropriate.',
    duplicate_indicator: 'Review repeated email addresses. Shared addresses can be legitimate; do not merge contacts automatically.'
};

function priorityDetails(key, metrics = {}) {
    const contacts = metrics.contacts || 0;
    switch (key) {
        case 'controls': return { priority: 'High', impact: 'Access and action boundaries must be verified before a pilot.' };
        case 'erasure': return { priority: 'High', impact: 'Deletion obligations and retained copies require evidence.' };
        case 'staff': return { priority: 'Medium', impact: 'Staff must recognize and escalate unsafe behavior.' };
        case 'email_completeness': return {
            priority: contacts && metrics.email_present / contacts < 0.5 ? 'High' : 'Medium',
            impact: 'Missing addresses can make donor communication incomplete or unreliable.'
        };
        case 'duplicate_indicator': return {
            priority: contacts && metrics.repeated_email_rows / contacts >= 0.1 ? 'High' : 'Medium',
            impact: 'Repeated addresses can distort donor summaries and need review before use.'
        };
        case 'account_linkage': return {
            priority: contacts && (contacts - metrics.linked_contacts) / contacts > 0.2 ? 'High' : 'Medium',
            impact: 'Missing account relationships can leave summaries without their intended context.'
        };
        default: return { priority: 'Low', impact: 'Limited evidence makes the data quality assessment less representative.' };
    }
}

export default class NonprofitAIReadiness extends LightningElement {
    result;
    scenario = 'organization';
    demoScenario;
    scenarioOptions = [
        { label: 'Live organization', value: 'organization' },
        { label: 'Simulation: poor readiness', value: 'poor' },
        { label: 'Simulation: improving readiness', value: 'improving' },
        { label: 'Simulation: blocked safeguard', value: 'blocked' },
        { label: 'Simulation: bounded pilot', value: 'pilot' },
        { label: 'Simulation: missing evidence', value: 'unknown' }
    ];
    get isDemo() { return this.scenario !== 'organization'; }
    get isLive() { return !this.isDemo; }
    get scopeLabel() { return this.isDemo ? 'Fictional simulation · Seeded scenario outcomes · No organization readiness conclusion' : 'Live Salesforce data · Four data checks · Records you can access'; }
    handleScenarioChange(event) {
        if (this.assessmentDisabled) return;
        this.scenario = event.detail.value;
        this.result = undefined;
        this.demoScenario = undefined;
        this.staffReview = undefined;
        this.safeguardEvidence = undefined;
        this.erasureEvidence = undefined;
        this.lastChecked = undefined;
        this.error = undefined;
        this.taskMessage = undefined;
        this.taskError = undefined;
    }
    get demoStaffChecks() {
        return Object.entries(STAFF).map(([key, [label, description]]) => ({ key, label, description,
            status: outcome(this.result?.staff?.checks?.[key]) }));
    }
    get demoControlChecks() {
        return Object.entries(this.result?.technical?.checks || {}).map(([key, status]) => ({ key, label: CONTROL_LABELS[key] || key, status: outcome(status) }));
    }
    get demoErasureChecks() {
        return (this.demoScenario?.erasure?.checks || []).map((check, index) => ({ key: String(index),
            label: `${check.category}: ${(check.probe_id || '').replace(/_/g, ' ')}`, status: outcome(check.status) }));
    }
    safeguardEvidence;
    erasureEvidence;
    handleEvidenceReview(event) {
        if (this.isDemo) return;
        if (event.detail.kind === 'safeguards') this.safeguardEvidence = event.detail.result;
        if (event.detail.kind === 'erasure') this.erasureEvidence = event.detail.result;
    }
    get safeguardsLabel() { if (this.isDemo) return this.result?.technical?.score == null ? 'Simulation: not assessed' : `Simulation: ${this.result.technical.score}%`; return this.safeguardEvidence ? (this.safeguardEvidence.mode === 'simulation' ? 'Simulation only' : 'Evidence evaluated') : 'Not assessed'; }
    get safeguardsCoverage() {
        if (this.isDemo) return `Simulated checks completed: ${this.result?.technical?.coverage ?? 0}%. No live access tests.`;
        return this.safeguardEvidence ? `${this.safeguardEvidence.mode === 'simulation' ? 'Simulated' : 'Reported'} evidence only; independent verification required` : 'Separate access and safety tests required';
    }
    get erasureLabel() { if (this.isDemo) return 'Simulation only'; return this.erasureEvidence ? (this.erasureEvidence.mode === 'simulation' ? 'Simulation only' : 'Evidence evaluated') : 'Not assessed'; }
    get erasureCoverage() {
        if (this.isDemo) return `${this.demoScenario?.erasure?.unknown_checks ?? 0} simulated checks missing. End-to-end erasure not verified.`;
        return this.erasureEvidence ? `${this.erasureEvidence.reported_observations} reported observations; ${this.erasureEvidence.unknown_checks} checks missing. End-to-end erasure not assessed.` : 'Deletion and retention procedures need review';
    }
    loading = false;
    error;
    lastChecked;
    savingTasks = false;
    canCreateFollowUp = Boolean(hasFollowUpPermission);
    taskMessage;
    taskError;
    inventory;
    inventoryError;
    staffReview;
    refreshAfterAssessment = false;
    get staffScore() { if (this.isDemo) return this.result?.staff?.score == null ? 'Simulation: not assessed' : `Simulation: ${this.result.staff.score}%`; return this.staffReview?.staff?.score == null ? 'Not assessed' : `${this.staffReview.staff.score}%`; }
    get staffCoverage() { if (this.isDemo) return `Simulated checks completed: ${this.result?.staff?.coverage ?? 0}%. Fictional exercises only.`; return this.staffReview ? `Checks completed: ${this.staffReview.staff.coverage}%. Your reviewed exercises only.` : 'Staff practice and review required'; }
    async handleStaffReview(event) {
        if (this.isDemo) return;
        this.staffReview = event.detail;
        if (this.loading) { this.refreshAfterAssessment = true; return; }
        if (this.result) { await this.handleRun(); }
    }
    get licenses() { return (this.inventory?.licenses || []).map(item => ({ ...item, total: item.total == null ? 'Not specified' : item.total, remaining: item.remaining == null ? 'Not specified' : item.remaining, key: `${item.kind}:${item.name}` })); }
    get capabilities() {
        return (this.inventory?.capabilities || []).map(item => ({
            ...item,
            availabilityLabel: item.availability === 'available' ? 'Available' : item.availability === 'unavailable' ? 'Unavailable' : 'Not verified',
            countLabel: item.visibleRecords == null ? 'Not shown' : item.visibleRecords
        }));
    }
    get actionsDisabled() { return this.loading || !this.result; }
    get assessmentDisabled() { return this.loading || this.savingTasks; }
    get tasksDisabled() { return this.isDemo || !this.canCreateFollowUp || this.loading || this.savingTasks || !this.result || this.suppressed; }
    get followUpCount() { return this.recommendations.length; }
    get score() { return this.result?.data?.score == null ? 'Not assessed' : `${this.result.data.score}%`; }
    get coverage() { return this.suppressed || this.result?.data?.coverage == null ? 'Not assessed' : `${this.result.data.coverage}%`; }
    get suppressed() { return this.result?.privacy?.suppressed === true; }
    get hasMetrics() { return Boolean(this.result?.metrics) && !this.suppressed; }
    get metrics() {
        if (!this.hasMetrics) { return []; }
        const { contacts, email_present: emails, linked_contacts: linked, repeated_email_rows: repeated } = this.result.metrics;
        return [
            { label: 'Contact records', value: contacts },
            { label: 'Missing email addresses', value: contacts - emails },
            { label: 'Possible duplicate email entries', value: repeated },
            { label: 'Contacts without accounts', value: contacts - linked }
        ];
    }
    get banner() {
        if (this.isDemo) return 'Simulation only. These fictional outcomes demonstrate the rubric; they do not assess this organization or certify staff, access safeguards or erasure.';
        if (this.result?.staff_review?.critical_failures?.length) {
            return 'An observed unsafe action in your staff review blocks a pilot. Correct it and repeat the exercise. Access safeguards and complete erasure still need review.';
        }
        return this.suppressed
            ? 'Not assessed: fewer than five accessible contacts. Counts and scores are withheld to protect personal information.'
            : this.result?.staff_review
                ? 'More checks are needed before an AI pilot. Staff scores cover only your saved exercises; whole-team readiness, access safeguards and complete erasure are not established.'
                : 'More checks are needed before an AI pilot. These results cover contact data only; access, safeguards and staff readiness and erasure procedures still need review.';
    }
    get checks() {
        return Object.entries(this.result?.data?.checks || {}).map(([key, status]) => ({
            key, label: LABELS[key] || key, status: status === 'unknown' ? 'Not assessed' : status === 'pass' ? 'Passed' : 'Needs attention',
            badgeClass: `status ${status}`
        }));
    }
    get recommendations() {
        if (this.isDemo) return (this.result?.priorities || []).map(item => ({
            key: item.key, owner: item.key === 'staff' ? 'Training lead' : item.key === 'privacy' ? 'Privacy lead' : 'Salesforce admin',
            text: item.recommendation, priority: item.priority, impact: item.impact,
            priorityClass: `priority-badge ${item.priority.toLowerCase()}`,
            learning: LEARNING[item.key] || LEARNING.erasure
        }));
        const actions = [
            { key: 'controls', owner: 'Salesforce admin', text: 'Before a pilot, test which information the agent can access, restricted exports, human approvals and how to stop it. These safeguards have not been assessed here.' },
            { key: 'erasure', owner: 'Privacy lead', text: 'Confirm how deletion requests cover Salesforce, the Recycle Bin, exports, integrations, AI logs and backups, including retention obligations. A deleted Contact alone does not establish erasure.', extraUrl: 'https://help.salesforce.com/s/articleView?id=home_delete.htm&language=en_US&type=5', extraLabel: 'Review Salesforce record deletion' },
            { key: 'staff', owner: 'Training lead', text: 'Use the seven staff questions to practice sensitive information handling, misleading instructions, review and incident reporting. Record what staff can demonstrate.' }
        ];
        if (this.suppressed) {
            actions.push({ key: 'privacy', owner: 'Data owner', text: 'Confirm the intended assessment scope with your administrator. Do not broaden access or add unnecessary personal information just to obtain a score.' });
        } else {
            Object.entries(this.result?.data?.checks || {}).filter(([, status]) => status === 'fail')
                .forEach(([key]) => actions.push({ key, owner: 'Data owner', text: ACTIONS[key] }));
        }
        const order = { Critical: 0, High: 1, Medium: 2, Low: 3 };
        if (this.result?.staff_review) {
            const generic = actions.findIndex(action => action.key === 'staff');
            if (generic >= 0) { actions.splice(generic, 1); }
            (this.result.priorities || []).filter(item => item.key.startsWith('staff_')).forEach(item => {
                actions.push({ key: item.key, owner: 'Training lead', text: item.recommendation.replace(` ${LEARNING.staff.url}`, ''),
                    reviewedPriority: item.priority, reviewedImpact: item.impact });
            });
        }
        return actions.map(action => {
            const details = action.reviewedPriority ? { priority: action.reviewedPriority, impact: action.reviewedImpact }
                : priorityDetails(action.key, this.result?.metrics || {});
            return {
                ...action,
                ...details,
                priorityClass: `priority-badge ${details.priority.toLowerCase()}`,
                learning: LEARNING[action.key] || (action.key.startsWith('staff_') ? LEARNING.staff : action.key === 'duplicate_indicator' ? LEARNING.duplicates : LEARNING.data)
            };
        }).sort((a, b) => order[a.priority] - order[b.priority]);
    }
    handleViewActions() {
        const heading = this.template.querySelector('[data-actions-heading]');
        if (heading) {
            const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            heading.scrollIntoView({ behavior: reducedMotion ? 'auto' : 'smooth', block: 'start' });
            heading.focus({ preventScroll: true });
        }
    }

    async handleCreateTasks() {
        if (this.tasksDisabled) { return; }
        this.savingTasks = true;
        this.taskMessage = undefined;
        this.taskError = undefined;
        try {
            const result = JSON.parse(await createFollowUpTasks());
            if (result.error || !Number.isInteger(result.created) || !Number.isInteger(result.reused)) {
                throw new Error('Task creation unavailable');
            }
            this.taskMessage = `Created ${result.created} tasks; ${result.reused} matching open tasks already exist.`
                + (Number.isInteger(result.updated) ? ` Updated ${result.updated} task priorities.` : '');
        } catch (error) {
            this.taskError = 'Could not create follow-up tasks. Ask your Salesforce administrator to check your task access.';
        } finally {
            this.savingTasks = false;
        }
    }
    async handleRun() {
        if (this.assessmentDisabled) return;
        this.loading = true;
        this.error = undefined;
        this.result = undefined;
        this.lastChecked = undefined;
        this.inventory = undefined;
        this.inventoryError = undefined;
        this.taskMessage = undefined;
        this.taskError = undefined;
        if (this.isDemo) {
            this.demoScenario = undefined;
            try {
                const demo = JSON.parse(await getScenario({ scenario: this.scenario }));
                if (demo.error || demo.mode !== 'simulation' || !demo.assessment) throw new Error('Simulation unavailable');
                this.demoScenario = demo;
                this.result = demo.assessment;
                this.lastChecked = new Date().toLocaleString();
            } catch (error) {
                this.error = 'Demo scenario unavailable. Run scripts/apex/seed-demo.apex in this demo org, then try again.';
            } finally {
                this.loading = false;
            }
            return;
        }
        const inventoryRequest = capabilityInventory().then(value => {
            const inventory = JSON.parse(value);
            if (inventory.error) { throw new Error('Inventory unavailable'); }
            this.inventory = inventory;
        }).catch(() => {
            this.inventoryError = 'License and feature information unavailable for your access.';
        });
        try {
            const result = JSON.parse(await assess({ scenario: 'organization' }));
            if (result.error) { throw new Error('Assessment unavailable'); }
            this.result = result;
            this.staffReview = result.staff_review || undefined;
            this.lastChecked = new Date().toLocaleString();
        } catch (error) {
            this.error = 'Assessment unavailable. Ask your Salesforce administrator to check your access and assessment setup.';
        } finally {
            await inventoryRequest;
            this.loading = false;
            if (this.refreshAfterAssessment) {
                this.refreshAfterAssessment = false;
                await this.handleRun();
            }
        }
    }
}
