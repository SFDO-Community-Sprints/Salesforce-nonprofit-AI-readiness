import { LightningElement, api } from 'lwc';
import canErase from '@salesforce/customPermission/Readiness_Run_Erasure_Probe';
import canManage from '@salesforce/customPermission/Readiness_Manage_Control';
import inspect from '@salesforce/apex/ReadinessRuntimeProbe.inspect';
import runErasure from '@salesforce/apex/ReadinessErasureProbe.run';
import targetHost from '@salesforce/apex/ReadinessErasureProbe.targetHost';
import controlStatus from '@salesforce/apex/ReadinessControl.status';
import setDisabled from '@salesforce/apex/ReadinessControl.setDisabled';

export default class ReadinessVerification extends LightningElement {
    runtime;
    erasure;
    busy = false;
    error;
    confirmed = false;
    expectedHost = '';
    disabled = false;
    canErase = Boolean(canErase);
    canManage = Boolean(canManage);
    async connectedCallback() {
        try { const state = JSON.parse(await controlStatus()); if (typeof state.disabled !== 'boolean') throw new Error('Unavailable'); this.disabled = state.disabled; }
        catch (error) { this.error = 'Execution-control status unavailable.'; }
    }
    @api async runChecks() {
        if (this.busy) return;
        this.busy = true;
        this.error = undefined;
        this.runtime = undefined;
        try {
            const result = JSON.parse(await inspect());
            if (!Array.isArray(result.checks) || !Array.isArray(result.gaps)) throw new Error('Unavailable');
            this.runtime = result;
            this.disabled = JSON.parse(await controlStatus()).disabled;
        } catch (error) { this.error = 'Runtime verification unavailable. No outcome inferred.'; }
        finally { this.busy = false; }
    }
    get checks() { return (this.runtime?.checks || []).map(item => ({ ...item, outcome: item.status === 'pass' ? 'Passed' : item.status === 'fail' ? 'Failed' : 'Not measured' })); }
    get gaps() { return this.runtime?.gaps || []; }
    get monitoring() { return this.runtime?.monitoring?.recorded ? 'A sanitized local operational event was recorded.' : 'Local operational event recording not verified.'; }
    get runtimeScope() { return this.runtime ? `${this.runtime.scope} · ${this.runtime.version} · ${this.runtime.observed_at}` : 'Run the assessment to execute current-identity checks.'; }
    get erasureDisabled() { return this.busy || !this.canErase || !this.confirmed; }
    get controlLabel() { return this.disabled ? 'Resume package assessments' : 'Stop package assessments'; }
    get controlState() { return this.disabled ? 'Stopped' : 'Enabled'; }
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
        } catch (error) { this.error = 'Source-erasure exercise did not complete. Check tester access, scratch target and validation rules; no erasure pass inferred.'; }
        finally { this.busy = false; }
    }
    get erasureChecks() {
        if (!this.erasure) return [];
        return [
            { id: 'active', label: 'Canary absent from active Salesforce reads', status: this.erasure.sourceActiveAbsent },
            { id: 'aggregate', label: 'Fresh aggregate count excludes the canary', status: this.erasure.aggregateExclusion },
            { id: 'recycle', label: 'Canary absent from the Recycle Bin', status: this.erasure.recycleBinErased }
        ];
    }
    get external() { return this.erasure?.external || []; }
    async toggleControl() {
        if (!this.canManage || this.busy) return;
        this.busy = true;
        this.error = undefined;
        try { const state = JSON.parse(await setDisabled({ disabled: !this.disabled })); if (typeof state.disabled !== 'boolean') throw new Error('Unavailable'); this.disabled = state.disabled; }
        catch (error) { this.error = 'Execution-control change failed. Refresh status before continuing.'; }
        finally { this.busy = false; }
    }
}
