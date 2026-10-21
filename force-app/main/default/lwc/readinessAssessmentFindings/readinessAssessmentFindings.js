import { LightningElement, api } from 'lwc';
import loadHistory from '@salesforce/apex/ReadinessWorkspace.loadHistory';

export default class ReadinessAssessmentFindings extends LightningElement {
    _recordId;
    connected = false;
    request = 0;
    loading = false;
    error;
    findings = [];
    columns = [
        {label:'Finding',fieldName:'label',wrapText:true},
        {label:'Result',fieldName:'outcome'}, {label:'Severity',fieldName:'severity'},
        {label:'Category',fieldName:'group',wrapText:true},
        {label:'Actual value',fieldName:'actual',wrapText:true,initialWidth:220},
        {label:'Expected value',fieldName:'expected',wrapText:true,initialWidth:220},
        {label:'Next action',fieldName:'action',wrapText:true}
    ];
    @api get recordId() { return this._recordId; }
    set recordId(value) {
        if (value === this._recordId) return;
        this._recordId=value;
        if (this.connected) this.load();
    }
    connectedCallback() { this.connected=true; this.load(); }
    disconnectedCallback() { this.connected=false; this.request++; }
    async load() {
        const request=++this.request;
        this.findings=[]; this.error=undefined;
        if (!this.recordId) { this.loading=false; return; }
        this.loading=true;
        try {
            const raw=await loadHistory({assessmentId:this.recordId});
            const report=typeof raw === 'string' ? JSON.parse(raw) : raw;
            if (request !== this.request) return;
            if (!report || report.error || !Array.isArray(report.findings)) throw new Error('Unavailable');
            this.findings=report.findings.map((row,index) => ({...row,key:`finding-${index}`,outcome:row.status === 'pass' ? 'Passed' : row.status === 'fail' ? 'Needs attention' : 'Not checked'}));
        } catch(error) {
            if (request === this.request) this.error='Saved findings could not be loaded with your access. No results are inferred.';
        } finally { if (request === this.request) this.loading=false; }
    }
    get empty() { return !this.loading && !this.error && this.findings.length === 0; }
}
