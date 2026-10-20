import { LightningElement } from 'lwc';
import canReview from '@salesforce/customPermission/Readiness_Review_Evidence';
import assessFreshness from '@salesforce/apex/ReadinessDataFreshness.assess';
import evaluateErasure from '@salesforce/apex/ReadinessEvidence.evaluateErasure';
import evaluateSafeguards from '@salesforce/apex/ReadinessEvidence.evaluateSafeguards';

const LABELS = {
    prerequisites: 'Required setup and operating prerequisites', runtime_access: 'Access with the actual assistant identity',
    approval: 'Human approval before consequential actions', export_block: 'Blocked unapproved exports',
    stop_control: 'Stopping the assistant and recovering safely',
    active_read_absent: 'Information absent from active Salesforce reads', recycle_bin_absent: 'Approved Recycle Bin outcome reviewed',
    agent_output_absent: 'Information absent from assistant answers', retention_approval: 'Retention decision approved',
    destination_absent: 'Information absent from connected destination', sync_no_reintroduction: 'Next sync prevents reintroduction',
    stored_log_absent: 'Stored logs reviewed for removal', new_log_no_reappearance: 'New logs prevent reappearance',
    restore_no_reintroduction: 'Restore rehearsal prevents reintroduction', export_copy_absent: 'Exported copy removal verified'
};
const PROBES = {
    salesforce: ['active_read_absent', 'recycle_bin_absent', 'agent_output_absent', 'retention_approval'],
    integrations: ['destination_absent', 'sync_no_reintroduction', 'retention_approval'],
    logs: ['stored_log_absent', 'new_log_no_reappearance', 'retention_approval'],
    backups: ['restore_no_reintroduction', 'retention_approval'], exports: ['export_copy_absent', 'retention_approval']
};
function blankCheck(id) { return { id, label: LABELS[id], result: 'unknown', evidence_ref: '', reviewer_ref: '', hasEvidence: false }; }

export default class ReadinessEvidence extends LightningElement {
    canReview = Boolean(canReview);
    policyVersion = '';
    windowDays = '';
    minimumRecentPercent = '';
    minimumCohort = '';
    approvedPolicy = false;
    kind = 'safeguards';
    mode = 'actual';
    safeguards = ['prerequisites', 'runtime_access', 'approval', 'export_block', 'stop_control'].map(blankCheck);
    destinations = [];
    nextDestination = 0;
    modes = [{ label: 'Actual reported evidence', value: 'actual' }, { label: 'Fictional simulation', value: 'simulation' }];
    results = [{ label: 'Not observed', value: 'unknown' }, { label: 'Observed pass', value: 'pass' }, { label: 'Observed failure', value: 'fail' }];
    categories = [{ label: 'Salesforce', value: 'salesforce' }, { label: 'Integrations', value: 'integrations' },
        { label: 'Logs', value: 'logs' }, { label: 'Backups', value: 'backups' }, { label: 'Exports', value: 'exports' }];
    busy = false;
    error;
    freshnessResult;
    evidenceResult;
    kinds = [{ label: 'Access and safeguards', value: 'safeguards' }, { label: 'Privacy and erasure', value: 'erasure' }];

    change(event) {
        const field = event.target.dataset.field;
        this[field] = field === 'approvedPolicy' ? event.target.checked : event.target.value;
        this.freshnessResult = undefined;
    }
    changeKind(event) {
        this.notifyEvidence(null);
        this.kind = event.detail.value;
        this.evidenceResult = undefined;
        this.error = undefined;
    }
    clearEvidence() {
        this.evidenceResult = undefined;
        this.error = undefined;
        this.notifyEvidence(null);
    }
    changeMode(event) {
        this.mode = event.detail.value;
        this.clearEvidence();
    }
    changeCheck(event) {
        const { destination, check, field } = event.target.dataset;
        const value = event.detail?.value ?? event.target.value;
        const update = item => item.id === check ? { ...item, [field]: value,
            ...(field === 'result' ? { hasEvidence: value !== 'unknown' } : {}) } : item;
        if (destination) this.destinations = this.destinations.map(row => row.key === destination ? { ...row, probes: row.probes.map(update) } : row);
        else this.safeguards = this.safeguards.map(update);
        this.clearEvidence();
    }
    addDestination() {
        this.destinations = [...this.destinations, { key: String(++this.nextDestination), id: '', category: 'salesforce',
            destination_ref: '', owner_ref: '', retention_policy_ref: '', privacy_approver_ref: '',
            probes: PROBES.salesforce.map(blankCheck) }];
        this.clearEvidence();
    }
    removeDestination(event) {
        this.destinations = this.destinations.filter(row => row.key !== event.target.dataset.destination);
        this.clearEvidence();
    }
    changeDestination(event) {
        const { destination, field } = event.target.dataset;
        const value = event.detail?.value ?? event.target.value;
        this.destinations = this.destinations.map(row => row.key === destination ? { ...row, [field]: value,
            ...(field === 'category' ? { probes: PROBES[value].map(blankCheck) } : {}) } : row);
        this.clearEvidence();
    }
    get actualMode() { return this.mode === 'actual'; }
    buildEvidence() {
        const reference = check => ({ evidence_ref: check.evidence_ref, reviewer_ref: check.reviewer_ref });
        if (!this.isErasure) return { mode: this.mode, evidence: this.safeguards.filter(check => check.hasEvidence)
            .map(check => ({ check_id: check.id, result: check.result, ...reference(check) })) };
        return { mode: this.mode, systems: this.destinations.map(row => ({ id: row.id, category: row.category,
            ...(this.actualMode ? { destination_ref: row.destination_ref, owner_ref: row.owner_ref,
                retention_policy_ref: row.retention_policy_ref, privacy_approver_ref: row.privacy_approver_ref } : {}) })),
        evidence: this.destinations.flatMap(row => row.probes.filter(check => check.hasEvidence).map(check => ({
            system_id: row.id, probe_id: check.id, result: check.result === 'pass' ? 'observed' : 'failed', ...reference(check) }))) };
    }
    notifyEvidence(result) {
        this.dispatchEvent(new CustomEvent('evidencereview', { detail: { kind: this.kind, result } }));
    }
    get disabled() { return this.busy; }
    get freshnessDisabled() { return this.busy || !this.approvedPolicy; }
    get isErasure() { return this.kind === 'erasure'; }
    get freshnessSummary() {
        const result = this.freshnessResult;
        if (!result) return '';
        const score = result.reason === 'measured' && result.freshness.score !== null ? `${result.freshness.score}%` : 'Not assessed';
        return `Freshness score: ${score}; evidence coverage: ${result.freshness.coverage}%. ${result.reason}.`;
    }
    get freshnessScope() { return this.freshnessResult?.coverage_note; }
    get evidenceSummary() {
        const result = this.evidenceResult;
        if (!result) return '';
        if (result.mode === 'simulation') return 'Simulation only — fictional evidence does not assess this org.';
        if (this.isErasure) return `${result.reported_observations} reported observations; ${result.reported_failures} reported failures; ${result.unknown_checks} unknown checks out of ${result.required_checks}. Erasure remains not assessed.`;
        return `Reported control score: ${result.score ?? 'Not assessed'}%; coverage: ${result.coverage}%. Access and safeguards remain not assessed pending independent verification.`;
    }
    get limitation() { return this.evidenceResult?.limitation || 'Reported references are not independently verified. External systems, approvals and runtime behavior need observed evidence.'; }
    get actions() {
        if (!this.evidenceResult) return [];
        if (this.isErasure) return this.evidenceResult.follow_ups.map((item, index) => ({ id: String(index), text: `${item.priority} · ${item.owner}: ${item.action}` }));
        return Object.entries(this.evidenceResult.checks).filter(([, value]) => !['reported_pass', 'simulated_pass'].includes(value))
            .map(([id, value]) => ({ id, text: `${LABELS[id] || id}: ${value === 'unknown' ? 'not observed' : 'reported failure'}. Record and review an observed test for this control.` }));
    }
    async assess() {
        if (this.freshnessDisabled) return;
        if (![...this.template.querySelectorAll('.freshness-input')].map(input => input.reportValidity()).every(Boolean)) return;
        this.busy = true;
        this.error = undefined;
        this.freshnessResult = undefined;
        try {
            const result = JSON.parse(await assessFreshness({ policyVersion: this.policyVersion,
                windowDays: Number(this.windowDays), minimumRecentPercent: Number(this.minimumRecentPercent),
                minimumCohort: Number(this.minimumCohort) }));
            if (result.error) throw new Error('Invalid policy');
            this.freshnessResult = result;
        } catch (error) {
            this.error = 'Freshness could not be assessed. Check the explicit policy values and Readiness Assessor access.';
        } finally { this.busy = false; }
    }
    async evaluate() {
        if (!this.canReview || this.busy) return;
        if (![...this.template.querySelectorAll('.evidence-input')].map(input => input.reportValidity()).every(Boolean)) return;
        this.busy = true;
        this.error = undefined;
        this.evidenceResult = undefined;
        this.notifyEvidence(null);
        try {
            const payload = JSON.stringify(this.buildEvidence());
            const result = JSON.parse(await (this.isErasure ? evaluateErasure({ inventoryJson: payload }) :
                evaluateSafeguards({ evidenceJson: payload })));
            if (result.error) throw new Error('Invalid evidence');
            this.evidenceResult = result;
            this.notifyEvidence(result);
        } catch (error) {
            this.error = 'Evidence could not be evaluated. Check required evidence references, unique destination references and Readiness Evidence Reviewer access.';
        } finally { this.busy = false; }
    }
}
