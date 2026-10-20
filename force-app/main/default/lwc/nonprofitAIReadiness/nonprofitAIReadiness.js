import { LightningElement } from 'lwc';
import hasFollowUpPermission from '@salesforce/customPermission/Readiness_Create_Follow_Up';
import assess from '@salesforce/apex/NonprofitAIReadiness.assessScenario';
import createFollowUpTasks from '@salesforce/apex/NonprofitAIReadiness.createFollowUpTasks';
import capabilityInventory from '@salesforce/apex/NonprofitAIReadiness.capabilityInventory';
import assessOrgConfiguration from '@salesforce/apex/ReadinessOrgChecks.assess';

const LABELS = {
    sufficient_data: 'At least 10 contact records',
    email_completeness: 'At least 90% have email addresses',
    account_linkage: 'All contacts linked to accounts',
    duplicate_indicator: 'No repeated email addresses'
};
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
    activeResultTab = 'overview';
    get resultTabs() {
        return [['overview','Overview'],['contacts','Contact data'],['configuration','Package configuration'],['licenses','Licenses and features'],['verification','Safeguard tests'],['evidence','Evidence and freshness'],['staff','Staff exercises']].map(([value,label]) => ({
            value, label, id: `readiness-tab-${value}`, panelId: `readiness-panel-${value}`,
            selected: this.activeResultTab === value ? 'true' : 'false',
            tabIndex: this.activeResultTab === value ? 0 : -1,
            className: `slds-tabs_default__item${this.activeResultTab === value ? ' slds-is-active' : ''}`
        }));
    }
    get hideOverview() { return this.activeResultTab !== 'overview'; }
    get hideContacts() { return this.activeResultTab !== 'contacts'; }
    get hideConfiguration() { return this.activeResultTab !== 'configuration'; }
    get hideLicenses() { return this.activeResultTab !== 'licenses'; }
    get hideVerification() { return this.activeResultTab !== 'verification'; }
    get hideEvidence() { return this.activeResultTab !== 'evidence'; }
    get hideStaff() { return this.activeResultTab !== 'staff'; }
    handleResultTab(event) {
        const value = event.currentTarget.dataset.tab;
        if (this.resultTabs.some(tab => tab.value === value)) this.activeResultTab = value;
    }
    handleResultTabKey(event) {
        const tabs = this.resultTabs;
        const current = tabs.findIndex(tab => tab.value === event.currentTarget.dataset.tab);
        let next;
        if (event.key === 'ArrowRight') next = (current + 1) % tabs.length;
        else if (event.key === 'ArrowLeft') next = (current + tabs.length - 1) % tabs.length;
        else if (event.key === 'Home') next = 0;
        else if (event.key === 'End') next = tabs.length - 1;
        else return;
        event.preventDefault();
        this.activeResultTab = tabs[next].value;
        this.template.querySelector(`[data-tab="${tabs[next].value}"]`)?.focus();
    }
    result;

    scenario = 'organization';
    scenarioOptions = [
        { label: 'All accessible Contacts', value: 'organization' },
        { label: 'Demo records: poor', value: 'poor' },
        { label: 'Demo records: improving', value: 'improving' },
        { label: 'Demo records: blocked', value: 'blocked' },
        { label: 'Demo records: pilot', value: 'pilot' },
        { label: 'Demo records: unknown', value: 'unknown' }
    ];
    get isOrganizationScope() { return this.scenario === 'organization'; }
    get scopeLabel() { return 'Live Salesforce data · Four data checks · Selected Contact records you can access. Staff and configuration checks remain organization-wide.'; }
    handleScenarioChange(event) {
        if (this.assessmentDisabled) return;
        this.scenario = event.detail.value;
        this.result = undefined;
        this.staffReview = undefined;
        this.safeguardEvidence = undefined;
        this.erasureEvidence = undefined;
        this.lastChecked = undefined;
        this.error = undefined;
        this.taskMessage = undefined;
        this.taskError = undefined;
    }
    handleVerificationChange() { this.template?.querySelector?.('c-readiness-org-health')?.runScan(); }
    safeguardEvidence;
    erasureEvidence;
    handleEvidenceReview(event) {
        if (event.detail.kind === 'safeguards') this.safeguardEvidence = event.detail.result;
        if (event.detail.kind === 'erasure') this.erasureEvidence = event.detail.result;
    }
    orgConfiguration;
    orgConfigurationError;
    get safeguardsLabel() { return 'See org health findings'; }
    get safeguardsCoverage() { return 'Org-wide security and access findings are shown above; runtime probes are shown below.'; }
    get erasureLabel() { return 'Incomplete'; }
    get erasureCoverage() { return 'Source deletion, recoverability and downstream copies require separate evidence.'; }
    get configurationSource() { return this.orgConfiguration ? `${this.orgConfiguration.scope} · ${this.orgConfiguration.version} · ${this.orgConfiguration.observed_at}` : ''; }
    get configurationChecks() {
        return ['access', 'privacy'].flatMap(area => (this.orgConfiguration?.[area]?.checks || []).map(check => ({
            ...check, key: `${area}:${check.id}`, area: area === 'access' ? 'Access and safeguards' : 'Privacy and erasure',
            statusLabel: check.status === 'pass' ? 'Passed' : check.status === 'fail' ? 'Needs attention' : 'Not assessed'
        })));
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
    get staffPractice() { return this.staffReview?.provenance === 'seeded_practice' || this.staffReview?.source === 'seeded_practice'; }
    get staffScore() { return this.staffReview?.staff?.score == null ? 'Not assessed' : `${this.staffPractice ? 'Practice answers: ' : ''}${this.staffReview.staff.score}%`; }
    get staffCoverage() { return this.staffPractice ? 'Seeded input records; no observed staff competency' : this.staffReview ? `Checks completed: ${this.staffReview.staff.coverage}%. Your reviewed exercises only.` : 'Staff practice and review required'; }
    async handleStaffReview(event) {
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
    get tasksDisabled() { return !this.isOrganizationScope || !this.canCreateFollowUp || this.loading || this.savingTasks || !this.result || this.suppressed; }
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
        if (this.hideOverview) {
            this.activeResultTab = 'overview';
            Promise.resolve().then(() => this.handleViewActions());
            return;
        }
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
        this.orgConfiguration = undefined;
        this.orgConfigurationError = undefined;
        this.inventory = undefined;
        this.inventoryError = undefined;
        this.taskMessage = undefined;
        this.taskError = undefined;
        const configurationRequest = assessOrgConfiguration().then(value => {
            const configuration = JSON.parse(value);
            if (!configuration || configuration.error || !configuration.access || !configuration.privacy) throw new Error('Configuration unavailable');
            this.orgConfiguration = configuration;
        }).catch(() => {
            this.orgConfigurationError = 'Organization configuration unavailable for your access. These checks are not assessed.';
        });
        const healthRequest = this.template?.querySelector?.('c-readiness-org-health')?.runScan();
        const verificationRequest = this.template?.querySelector?.('c-readiness-verification')?.runChecks();
        const inventoryRequest = capabilityInventory().then(value => {
            const inventory = JSON.parse(value);
            if (inventory.error) { throw new Error('Inventory unavailable'); }
            this.inventory = inventory;
        }).catch(() => {
            this.inventoryError = 'License and feature information unavailable for your access.';
        });
        try {
            const result = JSON.parse(await assess({ scenario: this.scenario }));
            if (result.error) { throw new Error('Assessment unavailable'); }
            this.result = result;
            this.staffReview = result.staff_review || undefined;
            this.lastChecked = new Date().toLocaleString();
        } catch (error) {
            this.error = 'Assessment unavailable. Ask your Salesforce administrator to check your access and assessment setup.';
        } finally {
            await Promise.all([inventoryRequest, configurationRequest, verificationRequest, healthRequest]);
            this.loading = false;
            if (this.refreshAfterAssessment) {
                this.refreshAfterAssessment = false;
                await this.handleRun();
            }
        }
    }
}
