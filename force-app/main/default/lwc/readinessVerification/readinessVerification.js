import { LightningElement, api } from 'lwc';
import canErase from '@salesforce/customPermission/Readiness_Run_Erasure_Probe';
import canManage from '@salesforce/customPermission/Readiness_Manage_Control';
import inspect from '@salesforce/apex/ReadinessRuntimeProbe.inspect';
import runErasure from '@salesforce/apex/ReadinessErasureProbe.run';
import targetHost from '@salesforce/apex/ReadinessErasureProbe.targetHost';
import controlStatus from '@salesforce/apex/ReadinessControl.status';
import setDisabled from '@salesforce/apex/ReadinessControl.setDisabled';

const TESTS = {
    native_assessment: { question: 'Can this app run the assessment?', pass: 'The assessment returned summary results.', fail: 'The assessment did not return the expected summary.', unknown: 'The assessment could not be checked.', next: 'Review data findings on Overview.', fix: 'Ask your administrator to check assessment access and setup.' },
    raw_email_read_boundary: { question: 'Are forbidden Contact email reads blocked?', pass: 'Salesforce refused an email read that this account is not permitted to make.', fail: 'An email read was not denied as expected.', unknown: 'Your account can read Contact emails, so it cannot demonstrate a forbidden-read test.', next: 'Repeat the test using the actual restricted AI account.', fix: 'Review Contact and field permissions before allowing the assistant to read data.' },
    unapproved_task_action: { question: 'Are unapproved follow-up Tasks blocked?', pass: 'This account has no permission for the Task action. The app refused it without writing records.', fail: 'The Task action did not respect the expected permission boundary.', unknown: 'This account is allowed to create follow-up Tasks. A restricted account is needed for the denial test.', next: 'Test the actual AI action and its human-approval process separately.', fix: 'Review the action permission before enabling Task creation.' },
    mcp_boundary: { question: 'Does the assessment tool enforce access?', pass: 'The assessment tool respected this account’s permission and summary-only response rules.', fail: 'The tool did not return the expected permitted summary or access denial.', unknown: 'The assessment tool could not be checked.', next: 'Check every other tool available to the assistant separately.', fix: 'Review the dedicated tool permission and connection before use.' }
};
const REMAINING = {
    assistant_identity: { title: 'AI assistant access', instruction: 'Use the actual AI account to demonstrate one allowed request and one forbidden request.' },
    consequential_approval: { title: 'Human approval', instruction: 'Show that a consequential action is blocked until an authorized person approves it.' },
    stop_recovery: { title: 'Stopping the assistant', instruction: 'Demonstrate how to stop the actual assistant and recover safely. Pausing this app alone is not enough.' },
    monitoring: { title: 'Alerts and incident response', instruction: 'Trigger a rejected action and confirm the responsible person receives and responds to the alert.' },
    export_surface: { title: 'Exports and connected tools', instruction: 'Check that the assistant cannot export restricted data through any of its connected tools.' }
};
const outcome = status => status === 'pass' ? 'Passed' : status === 'fail' ? 'Needs attention' : 'Not checked';
const badge = status => `badge ${status === 'pass' ? 'pass' : status === 'fail' ? 'fail' : 'unknown'}`;

export default class ReadinessVerification extends LightningElement {
    runtime;
    erasure;
    busy = false;
    error;
    confirmed = false;
    expectedHost = '';
    disabled = false;
    controlKnown = false;
    controlError;
    canErase = Boolean(canErase);
    canManage = Boolean(canManage);
    async connectedCallback() { await this.refreshControl(); }
    async refreshControl() {
        this.controlError = undefined;
        try {
            const state = JSON.parse(await controlStatus());
            if (typeof state.disabled !== 'boolean') throw new Error('Unavailable');
            this.disabled = state.disabled;
            this.controlKnown = true;
        } catch (error) {
            this.controlKnown = false;
            this.controlError = 'App status could not be checked. Refresh before trying to pause or resume.';
        }
    }
    @api async runChecks() {
        if (this.busy) return;
        this.busy = true;
        this.error = undefined;
        this.runtime = undefined;
        try {
            const result = JSON.parse(await inspect());
            if (!Array.isArray(result.checks) || !result.checks.length || !Array.isArray(result.gaps)) throw new Error('Unavailable');
            this.runtime = result;
            await this.refreshControl();
        } catch (error) { this.error = 'The safeguard tests could not run. Check your assessment access, then try again. No tests are marked as passed.'; }
        finally { this.busy = false; }
    }
    get technicalChecks() { return (this.runtime?.checks || []).map(item => ({ ...item, outcome: outcome(item.status) })); }
    get checks() {
        return (this.runtime?.checks || []).filter(item => !['contact_read','email_read'].includes(item.id)).map(item => {
            const copy = TESTS[item.id] || { question: item.label || 'Additional app check', pass: 'The additional app check passed.', fail: 'The additional app check needs attention.', unknown: 'The additional app check was not completed.', next: 'Review the technical details below.', fix: 'Ask your administrator to review the technical details before continuing.' };
            return { ...item, question: copy.question, outcome: outcome(item.status), badgeClass: badge(item.status),
                explanation: copy[item.status] || copy.unknown, nextStep: item.status === 'fail' ? copy.fix : copy.next };
        });
    }
    get passedCount() { return this.checks.filter(item => item.status === 'pass').length; }
    get failedCount() { return this.checks.filter(item => item.status === 'fail').length; }
    get unknownCount() { return this.checks.filter(item => item.status !== 'pass' && item.status !== 'fail').length; }
    get resultMessage() { return this.failedCount ? 'Some app checks need attention. Review the failed checks before continuing.' : 'These results cover this app and your account. Your AI assistant still needs the separate tests below.'; }
    get gaps() {
        const items = this.runtime?.gaps || Object.keys(REMAINING).map(id => ({ id }));
        return items.map(item => ({...item, ...(REMAINING[item.id] || {title: item.label, instruction: item.required_binding})}));
    }
    get monitoring() { return this.runtime?.monitoring?.recorded ? 'Test outcomes were recorded without donor values or request content.' : 'Recording the test outcomes could not be verified.'; }
    get runtimeScope() { return this.runtime ? `${this.runtime.scope} · ${this.runtime.version} · ${this.runtime.observed_at}` : 'No test details yet.'; }
    get controlDisabled() { return this.busy || !this.controlKnown || !this.canManage; }
    get erasureDisabled() { return this.busy || !this.canErase || !this.confirmed; }
    get controlLabel() { return this.disabled ? 'Resume this app' : 'Pause this app'; }
    get controlState() { return !this.controlKnown ? 'Not checked' : this.disabled ? 'Paused' : 'Running'; }
    changeConfirmation(event) { this.confirmed = event.target.checked; }
    async handleErasure() {
        if (this.erasureDisabled) return;
        this.busy = true;
        this.error = undefined;
        this.erasure = undefined;
        try {
            this.expectedHost = await targetHost();
            const result = JSON.parse(await runErasure({ expectedHost: this.expectedHost, confirmed: true }));
            if (result.status !== 'observed') throw new Error('Probe failed');
            this.erasure = result;
            this.dispatchEvent(new CustomEvent('verificationchange'));
        } catch (error) { this.error = 'The deletion test did not complete. Ask your administrator to check tester access, the scratch org and Contact validation rules. No deletion pass is shown.'; }
        finally { this.busy = false; }
    }
    get erasureChecks() {
        if (!this.erasure) return [];
        return [
            { id: 'active', label: 'Test Contact removed from active results', status: this.erasure.sourceActiveAbsent },
            { id: 'aggregate', label: 'New summary counts exclude the test Contact', status: this.erasure.aggregateExclusion },
            { id: 'recycle', label: 'Test Contact permanently erased', status: this.erasure.recycleBinErased }
        ].map(item => ({...item, outcome: outcome(item.status), badgeClass: badge(item.status)}));
    }
    get external() { return this.erasure?.external || []; }
    async toggleControl() {
        if (this.controlDisabled) return;
        this.busy = true;
        this.error = undefined;
        try { const state = JSON.parse(await setDisabled({ disabled: !this.disabled })); if (typeof state.disabled !== 'boolean') throw new Error('Unavailable'); this.disabled = state.disabled; }
        catch (error) { this.error = 'The app could not be paused or resumed. Refresh its status before trying again.'; }
        finally { this.busy = false; }
    }
}
