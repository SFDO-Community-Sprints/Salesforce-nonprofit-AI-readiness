import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import loadWorkspace from '@salesforce/apex/ReadinessWorkspace.loadWorkspace';
import saveUseCase from '@salesforce/apex/ReadinessWorkspace.saveUseCase';
import saveAnswer from '@salesforce/apex/ReadinessWorkspace.saveAnswer';
import loadHistory from '@salesforce/apex/ReadinessWorkspace.loadHistory';
import scanUseCase from '@salesforce/apex/ReadinessWorkspace.scanUseCase';

const FIELDS = [
    ['name', 'Implementation name'], ['owner', 'Business owner'], ['purpose', 'Purpose and intended users'],
    ['integrationUsername', 'Actual AI integration username'], ['groundingFields', 'Grounding fields, one Object.Field per line'],
    ['allowedActions', 'Allowed actions'], ['excludedActions', 'Excluded actions'], ['value', 'Expected value'],
    ['successCriteria', 'Success criteria and KPIs'], ['risks', 'Risks and possible losses'], ['mitigation', 'Risk mitigation'],
    ['handover', 'Human handover points and responsible person'], ['stopOwner', 'Who can stop the assistant'],
    ['costs', 'Expected costs'], ['gains', 'Expected gains and social impact'], ['decisionNotes', 'Cost versus gains decision'],
    ['approver', 'Accountable approver'], ['policyReference', 'Approved data-quality policy reference']
];
const SCOPES = [{label:'Company',value:'company'}, {label:'Org',value:'org'}, {label:'Implementation',value:'implementation'}];
const ANSWERS = [{label:'Yes',value:'yes'}, {label:'Partially',value:'partial'}, {label:'No',value:'no'}, {label:'Not sure',value:'unknown'}];
const STATUSES = ['Draft', 'Proposed', 'In progress', 'Approved', 'Paused', 'Retired'].map(value => ({label:value,value}));
const parse = value => typeof value === 'string' ? JSON.parse(value) : value;
function ageLabel(value) {
    if (!value) return 'Date not recorded';
    const timestamp=Date.parse(value);
    if (!Number.isFinite(timestamp)) return 'Date not available';
    const days=Math.floor((Date.now()-timestamp)/86400000);
    return days < 0 ? 'Recorded date is in the future; review it' : days === 0 ? 'Recorded today' : `Recorded ${days} day${days === 1 ? '' : 's'} ago`;
}

function scopeDetails(scope) {
    if (!scope) return [{key:'missing',label:'Scope definition',value:'Not recorded'}];
    if (scope.scope === 'organization') return [{key:'scope',label:'Scope',value:'Organization'}, {key:'collector',label:'Collector',value:scope.collector || 'Not recorded'}];
    return [
        {key:'fields',label:'Grounding fields',value:(scope.groundingFields || []).join(', ') || 'Not declared'},
        {key:'age',label:'Maximum record age',value:scope.freshDays == null ? 'No approved threshold' : `${scope.freshDays} days`},
        {key:'completeness',label:'Minimum completeness',value:scope.minimumCompleteness == null ? 'No approved threshold' : `${scope.minimumCompleteness}%`},
        {key:'approval',label:'Policy approval recorded',value:scope.policyApproved ? 'Yes' : 'No'},
        {key:'binding',label:'Identity and policy references',value:'Stored as comparison fingerprints; no credentials are stored'}
    ];
}

export default class ReadinessWorkspace extends NavigationMixin(LightningElement) {
    @api mode = 'all';
    routeState;
    localReport;
    localReportPending = false;
    @wire(CurrentPageReference) receivePage(page) {
        this.routeState=page?.state;
        if (this.workspaceLoaded) this.applyRoute();
    }
    applyRoute() {
        const state=this.routeState;
        if (!state) return;
        this.routeState=undefined;
        const id=state.c__useCaseId;
        if (id && this.data.useCases.some(row => row.id === id)) this.selectCase({detail:{value:id}});
        if (state.c__questionId) this.openChecklist({questionId:state.c__questionId,scope:state.c__scope,useCaseId:id});
        else if (['company','org','implementation'].includes(state.c__scope)) this.scope=state.c__scope;
        if (state.c__assessmentId && this.mode === 'history') this.chooseHistory({detail:{value:state.c__assessmentId},target:{dataset:{}}});
    }
    get showCases() { return this.mode === 'all' || this.mode === 'cases'; }
    get showChecklists() { return this.mode === 'all' || this.mode === 'checklists'; }
    get showHistory() { return this.mode === 'all' || this.mode === 'history'; }
    get combinedMode() { return this.mode === 'all'; }
    get pageDescription() {
        if (this.mode === 'history') return 'Review saved observations and compare their scope, rubric and age. Run a new assessment for current data.';
        if (this.mode === 'checklists') return 'Record accountable people and reported policies for your company, org or a selected implementation. Yes requires a responsible person, evidence reference and review date. Reported policies do not establish executed safeguards or staff competency.';
        return 'Name an AI use case, define its data and actions, assign accountable people and run an assessment of that scope. Business approval is separate from measured readiness.';
    }
    get pageTitle() { return this.mode === 'cases' ? 'AI use cases' : this.mode === 'checklists' ? 'Guided checklists' : this.mode === 'history' ? 'Assessment history' : 'Plan an AI implementation'; }
    data = {useCases:[],answers:[],questions:[],history:[],canEdit:false};
    selectedId = '';
    scope = 'company';
    stage = '';
    draft = {};
    answerDrafts = {};
    dirty = false;
    busy = false;
    error;
    message;
    historyMessage;
    workspaceLoaded = false;
    historyId = '';
    comparisonId = '';
    historyReport;
    comparisonReport;
    accountability = 'all';
    scopes = SCOPES;
    answerChoices = ANSWERS;
    statuses = STATUSES;
    accountabilityOptions = [{label:'All questions',value:'all'}, {label:'Unassigned gaps',value:'unassigned'}, {label:'Overdue gaps',value:'overdue'}];
    connectedCallback() { this.load(); }
    @api async load() {
        this.busy = true;
        this.error = undefined;
        try {
            const data = parse(await loadWorkspace());
            if (!data || data.error || !Array.isArray(data.useCases) || !Array.isArray(data.questions) || !Array.isArray(data.answers) || !Array.isArray(data.history)) throw new Error('Invalid workspace');
            this.data = data;
            this.workspaceLoaded = true;
            this.applyRoute();
            if (!this.dirty) this.draft = {...(data.useCases.find(row => row.id === this.selectedId) || {})};
        } catch (error) { this.workspaceLoaded = false; this.data = {...this.data,canEdit:false}; this.error = 'Workspace could not be loaded with your access. Refresh or ask your administrator.'; }
        finally { this.busy = false; }
    }
    get disabled() { return this.busy || !this.data.canEdit; }
    get noRecorder() { return this.data.canRecord === false; }
    get policyApproved() { return Boolean(this.draft.policyApproved); }
    get freshDays() { return this.draft.freshDays; }
    get minimumCompleteness() { return this.draft.minimumCompleteness; }
    get scanDisabled() { return this.busy || !this.workspaceLoaded || !this.selectedId || this.dirty; }
    get implementationScope() { return this.scope === 'implementation'; }
    get needsImplementation() { return this.implementationScope && !this.selectedId; }
    get caseOptions() { return [{label:this.mode === 'history' ? 'All implementations and organization scans' : this.mode === 'checklists' ? 'Choose an implementation for its checklist' : 'New implementation',value:''}, ...this.data.useCases.map(row => ({label:row.name,value:row.id}))]; }
    get caseFields() { return FIELDS.map(([key,label]) => ({key,label,maximum:key === 'name' ? 80 : 2000,value:key === 'groundingFields' ? (Array.isArray(this.draft[key]) ? this.draft[key].join('\n') : this.draft[key] || '') : this.draft[key] || ''})); }
    get lifecycle() { return this.draft.status || 'Draft'; }
    get stages() { return [...new Set(this.data.questions.filter(row => row.scope === this.scope).map(row => row.stage))].map(value => ({label:value,value})); }
    get currentStage() { return this.stages.some(row => row.value === this.stage) ? this.stage : this.stages[0]?.value; }
    get questions() {
        if (this.needsImplementation) return [];
        const today = new Date().toISOString().slice(0,10);
        return this.data.questions.filter(row => row.scope === this.scope && row.stage === this.currentStage).map(row => {
            const key = `${this.scope}:${this.implementationScope ? this.selectedId : ''}:${row.id}`;
            const stored = this.data.answers.find(answer => answer.scope === this.scope && answer.questionId === row.id && (this.scope !== 'implementation' || answer.useCaseId === this.selectedId));
            const answer = {...(stored || {}), ...(this.answerDrafts[key] || {})};
            return {...row, key, answer:answer.answer || 'unknown', notes:answer.notes || '', responsible:answer.responsible || '', dueDate:answer.dueDate || '', evidence:answer.evidence || '', reviewDate:answer.reviewDate || '',
                reviewAge:ageLabel(answer.reviewDate), audit:answer.updatedAt ? `Last saved ${answer.updatedAt} by ${answer.updatedBy || 'recorded reviewer'}` : 'Not yet saved', overdue:Boolean(answer.dueDate && answer.dueDate < today && answer.answer !== 'yes'), unassigned:!answer.responsible && answer.answer !== 'yes'};
        }).filter(row => this.accountability === 'all' || row[this.accountability]);
    }
    historyColumns = [
        {label:'Assessment',fieldName:'name'}, {label:'Observed',fieldName:'observedAt',type:'date'},
        {label:'Implementation',fieldName:'implementation'}, {label:'Score',fieldName:'scoreLabel'}, {label:'Checks completed',fieldName:'coverageLabel'},
        {type:'button',typeAttributes:{label:'Review',name:'review'}}, {type:'button',typeAttributes:{label:'Compare',name:'compare'}}
    ];
    get showImplementationSelector() { return this.mode !== 'history'; }
    get historyRows() { return this.data.history.filter(row => !this.selectedId || row.useCaseId === this.selectedId).map(row => ({
        ...row, name:row.name || 'Saved assessment', observedAt:row.observedAt || 'Not recorded',
        implementation:row.useCaseId ? this.data.useCases.find(useCase => useCase.id === row.useCaseId)?.name || 'Implementation not visible' : 'Organization',
        scoreLabel:row.score == null ? 'Unknown' : `${row.score}%`, coverageLabel:`${row.coverage ?? 0}%`,
        reviewLabel:`Review ${row.name || 'saved assessment'}`, compareLabel:`Compare ${row.name || 'saved assessment'}`,
        selectedLabel:row.id === this.historyId ? 'Reviewing' : row.id === this.comparisonId ? 'Comparing' : ''
    })); }
    get noHistory() { return this.historyRows.length === 0; }
    reviewHistory(event) {
        const {action,row}=event.detail || {};
        if (!row?.id || !['review','compare'].includes(action?.name)) return;
        return this.chooseHistory({detail:{value:row.id},target:{dataset:{comparison:action.name === 'compare' ? 'true' : 'false'}}});
    }
    get snapshotRows() { return [{key:'first',label:'Saved assessment',report:this.historyReport}, {key:'second',label:'Comparison',report:this.comparisonReport}].filter(row => row.report).map(row => ({...row, name:this.data.history.find(saved => saved.id === (row.key === 'first' ? this.historyId : this.comparisonId))?.name || row.label, implementation:row.report.useCaseId ? this.data.useCases.find(useCase => useCase.id === row.report.useCaseId)?.name || 'Implementation not visible' : 'Organization', assessmentId:row.report.assessmentId || (row.key === 'first' ? this.historyId : this.comparisonId), useCaseId:row.report.useCaseId || 'Organization', age:ageLabel(row.report.observedAt), scopeDetails:scopeDetails(row.report.scopeDefinition), scope:typeof row.report.scope === 'string' ? row.report.scope : JSON.stringify(row.report.scope), version:row.report.version, observedAt:row.report.observedAt, score:row.report.score == null ? 'Unknown' : `${row.report.score}%`, coverage:`${row.report.coverage ?? 0}%`, passed:row.report.passed ?? 0, failed:row.report.failed ?? 0, unknown:row.report.unknown ?? 0, findings:(row.report.findings || []).map((finding,index) => ({...finding,key:`${row.key}-${index}`,title:finding.label || finding.title || finding.id,outcome:finding.status || finding.outcome,action:finding.action || finding.recommendation}))})); }
    get comparisonWarning() {
        if (!this.historyReport || !this.comparisonReport) return '';
        return this.historyReport.useCaseId !== this.comparisonReport.useCaseId || JSON.stringify(this.historyReport.scopeDefinition || this.historyReport.scope) !== JSON.stringify(this.comparisonReport.scopeDefinition || this.comparisonReport.scope) || this.historyReport.version !== this.comparisonReport.version ? 'Scope or rubric differs. These scores are not directly comparable.' : 'Same saved scope and rubric. Compare individual findings as well as score and coverage.';
    }
    selectCase(event) {
        this.selectedId = event.detail.value;
        // Keep unsaved implementation forms when switching between implementations.
        this.caseDrafts = {...this.caseDrafts, [this.previousId || '']:this.draft};
        this.draft = {...(this.caseDrafts[this.selectedId] || this.data.useCases.find(row => row.id === this.selectedId) || {})};
        this.previousId = this.selectedId;
        this.dirty = Boolean(this.draft._dirty);
    }
    caseDrafts = {};
    previousId = '';
    changeCase(event) {
        const field=event.target.dataset.field;
        const value=field === 'policyApproved' ? event.target.checked : event.detail?.value ?? event.target.value;
        this.draft = {...this.draft,[field]:value,_dirty:true};
        if (field === 'integrationUsername') this.draft.integrationUserId = null;
        this.dirty = true;
    }
    @api openChecklist({questionId,scope,useCaseId} = {}) {
        const question=this.data.questions.find(row => row.id === questionId && (!scope || row.scope === scope));
        if (!question) return;
        if (useCaseId && useCaseId !== this.selectedId) this.selectCase({detail:{value:useCaseId}});
        this.scope=question.scope; this.stage=question.stage; this.accountability='all';
        this.focusQuestion=questionId;
    }
    renderedCallback() {
        if (this.localReportPending) {
            const view=this.template.querySelector('c-readiness-org-health');
            if (view) { view.displayReport(this.localReport); this.localReportPending=false; }
        }
        if (!this.focusQuestion) return;
        const heading=[...this.template.querySelectorAll('[data-question]')].find(node => node.dataset.question === this.focusQuestion);
        if (heading) { heading.focus(); this.focusQuestion=undefined; }
    }
    changeScope(event) { this.scope = event.detail.value; this.stage = ''; }
    changeStage(event) { this.stage = event.detail.value; }
    changeFilter(event) { this.accountability = event.detail.value; }
    changeAnswer(event) {
        const {key,field} = event.target.dataset;
        this.answerDrafts = {...this.answerDrafts,[key]:{...this.answerDrafts[key],[field]:event.detail?.value ?? event.target.value}};
    }
    async saveCase() {
        if (this.disabled) return;
        if ([...(this.template?.querySelectorAll('[data-case-form] lightning-input, [data-case-form] lightning-textarea') || [])].some(field => field.reportValidity && !field.reportValidity())) return;
        const input = {...this.draft};
        if (!input.name?.trim() || !input.owner?.trim() || !input.purpose?.trim()) { this.error='Enter an implementation name, business owner and purpose.'; return; }
        const thresholds=[input.freshDays,input.minimumCompleteness].some(value => value != null && value !== '');
        if (thresholds && (!input.policyApproved || !input.policyReference?.trim())) { this.error='Thresholds require an approved policy and a recorded policy reference.'; return; }
        delete input._dirty;
        input.groundingFields = Array.isArray(input.groundingFields) ? input.groundingFields : (input.groundingFields || '').split(/\r?\n/).map(value => value.trim()).filter(Boolean);
        const priorId=this.selectedId;
        await this.perform(async () => {
            const saved = parse(await saveUseCase({input:JSON.stringify(input)}));
            this.selectedId = saved.id; this.previousId = saved.id; this.draft = saved; this.dirty = false;
            delete this.caseDrafts[saved.id]; delete this.caseDrafts[priorId];
            this.changed(); await this.load(); this.message = 'Implementation saved. Lifecycle approval does not establish measured readiness.';
        }, 'Implementation could not be saved. Check the required fields, field identifiers and your access.');
    }
    async saveQuestion(event) {
        if (this.disabled) return;
        const row = this.questions.find(question => question.key === event.target.dataset.key);
        if (!row) return;
        const input = {scope:this.scope,useCaseId:this.implementationScope ? this.selectedId : null,questionId:row.id,answer:row.answer,notes:row.notes,responsible:row.responsible,dueDate:row.dueDate || null,evidence:row.evidence,reviewDate:row.reviewDate || null};
        if (input.answer === 'yes' && (!input.responsible?.trim() || !input.evidence?.trim() || !input.reviewDate)) { this.error='A reported Yes needs a responsible person, evidence reference and review date.'; return; }
        await this.perform(async () => {
            await saveAnswer({input:JSON.stringify(input)}); delete this.answerDrafts[row.key];
            this.changed(); await this.load(); this.message = 'Answer saved as a reported policy or responsibility, not an executed test.';
        }, 'Answer could not be saved. Check the dates and your authorized scope.');
    }
    async runScan() {
        if (this.scanDisabled) return;
        await this.perform(async () => {
            const report = parse(await scanUseCase({useCaseId:this.selectedId}));
            if (!report || report.error || !Array.isArray(report.findings) || !Number.isFinite(report.coverage)) throw new Error('Invalid report');
            this.dispatchEvent(new CustomEvent('scopedresult',{detail:{report}}));
            this.historyMessage = report.historySaved ? 'Assessment history saved.' : (report.historyMessage || 'Assessment history was not saved.');
            await this.load(); this.message = 'Scoped assessment completed. Unmeasured checks remain unknown.';
            if (this.mode !== 'all' && report.historySaved && report.assessmentId) {
                this[NavigationMixin.Navigate]({type:'standard__navItemPage',attributes:{apiName:'AI_Readiness'},state:{c__assessmentId:report.assessmentId}});
            } else if (this.mode !== 'all') { this.localReport=report; this.localReportPending=true; }
        }, 'Scoped assessment could not run with your access. No checks are marked as passed.');
    }
    async chooseHistory(event) {
        const comparison = event.target.dataset.comparison === 'true';
        const id = event.detail.value;
        if (comparison && id && id === this.historyId) { this.comparisonId=''; this.comparisonReport=undefined; this.message='Choose a different saved assessment to compare. This scan is already being reviewed.'; return; }
        if (!comparison && id && id === this.comparisonId) { this.comparisonId=''; this.comparisonReport=undefined; }
        if (comparison) { this.comparisonId=id; this.comparisonReport=undefined; }
        else { this.historyId=id; this.historyReport=undefined; }
        if (!id) return;
        await this.perform(async () => {
            const report = parse(await loadHistory({assessmentId:id}));
            if (!report || report.error || !Array.isArray(report.findings) || !Number.isFinite(report.coverage)) throw new Error('Invalid snapshot');
            if ((comparison ? this.comparisonId : this.historyId) !== id) return;
            if (comparison) this.comparisonReport=report; else this.historyReport=report;
        }, 'Saved assessment could not be read with your access.');
    }
    navigateChecklist(event) {
        const {questionId,scope,useCaseId}=event.detail || {};
        if (!questionId || !['company','org','implementation'].includes(scope)) return;
        const state={c__questionId:questionId,c__scope:scope};
        if (useCaseId) state.c__useCaseId=useCaseId;
        this[NavigationMixin.Navigate]({type:'standard__navItemPage',attributes:{apiName:'AI_Checklists'},state});
    }
    changed() { this.dispatchEvent(new CustomEvent('workspacechange')); }
    async perform(action,message) {
        this.busy=true; this.error=undefined; this.message=undefined;
        try { await action(); } catch(error) { this.error=message; } finally { this.busy=false; }
    }
}
