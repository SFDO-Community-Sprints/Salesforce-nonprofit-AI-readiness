import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChecklist from '@salesforce/apex/AIR_Controller.getChecklist';
import saveChecklist from '@salesforce/apex/AIR_Controller.saveChecklist';
import getUseCases from '@salesforce/apex/AIR_Controller.getUseCases';
import setAgentUser from '@salesforce/apex/AIR_Controller.setAgentUser';
import runUseCaseChecks from '@salesforce/apex/AIR_Controller.runUseCaseChecks';
import { STATUS, TABS, countsLine, errorMessage, formatPercent, healthClass, navItem, statusClass } from 'c/airUtils';

const LEVELS = [
    { label: 'Company', value: 'Company' },
    { label: 'Org', value: 'Org' },
    { label: 'Implementation', value: 'Implementation' }
];

const ANSWER_OPTIONS = [
    { label: 'Yes', value: 'Yes' },
    { label: 'Partially', value: 'Partially' },
    { label: 'No', value: 'No' },
    { label: 'Not sure', value: 'Not sure' }
];

const OWNERS_STEP = 'owners';
const AI_USER_STEP = 'ai-user';

export default class AirChecklistWizard extends NavigationMixin(LightningElement) {
    level = 'Company';
    useCaseId;
    useCases = [];
    data;
    answers = {};
    owners = {};
    stepIndex = 0;
    finished = false;
    busy = false;
    error;
    adviceOpen = {};
    usernameInput = '';
    pageStateApplied = false;

    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        const state = (pageRef && pageRef.state) || {};
        let changed = false;
        if (state.c__level && LEVELS.some((l) => l.value === state.c__level) && state.c__level !== this.level) {
            this.level = state.c__level;
            changed = true;
        }
        if (state.c__useCaseId && state.c__useCaseId !== this.useCaseId) {
            this.useCaseId = state.c__useCaseId;
            changed = true;
        }
        if (changed && this.pageStateApplied) {
            this.load();
        }
    }

    connectedCallback() {
        this.pageStateApplied = true;
        this.loadUseCases();
        this.load();
    }

    // ------------------------------------------------------------------ loading

    async loadUseCases() {
        try {
            this.useCases = await getUseCases();
        } catch (e) {
            this.error = errorMessage(e);
        }
    }

    async load() {
        this.finished = false;
        this.stepIndex = 0;
        this.adviceOpen = {};
        if (this.isImplementation && !this.useCaseId) {
            this.data = undefined;
            return;
        }
        this.busy = true;
        try {
            this.apply(await getChecklist({ level: this.level, useCaseId: this.useCaseId || null }));
            this.error = undefined;
        } catch (e) {
            this.error = errorMessage(e);
        } finally {
            this.busy = false;
        }
    }

    apply(data) {
        this.data = data;
        const answers = {};
        (data.categories || []).forEach((cat) => {
            cat.results.forEach((r) => {
                answers[r.code] = {
                    answer: r.answer || '',
                    notes: r.notes || '',
                    responsible: r.responsible || '',
                    dueDate: r.dueDate || null
                };
            });
        });
        this.answers = answers;
        this.owners = { ...(data.owners || {}) };
        this.usernameInput = data.agentUser ? data.agentUser.username : this.usernameInput;
    }

    // ------------------------------------------------------------------ getters

    get levelButtons() {
        return LEVELS.map((l) => ({ ...l, variant: l.value === this.level ? 'brand' : 'neutral' }));
    }

    get levelLabel() {
        return this.level;
    }

    get isImplementation() {
        return this.level === 'Implementation';
    }

    get useCaseOptions() {
        return (this.useCases || []).map((u) => ({ label: `${u.name} (${u.status || 'No status'})`, value: u.id }));
    }

    get noUseCases() {
        return this.isImplementation && (!this.useCases || this.useCases.length === 0);
    }

    get showChecklist() {
        return !!this.data && (!this.isImplementation || !!this.useCaseId);
    }

    get answerOptions() {
        return ANSWER_OPTIONS;
    }

    get steps() {
        const steps = [];
        if (this.level === 'Company') {
            steps.push({ value: OWNERS_STEP, label: 'Responsible people' });
        }
        if (this.isImplementation) {
            steps.push({ value: AI_USER_STEP, label: 'AI access' });
        }
        ((this.data && this.data.categories) || []).forEach((cat) => {
            steps.push({ value: cat.code, label: cat.label });
        });
        return steps;
    }

    get currentStep() {
        return this.steps[this.stepIndex] || this.steps[0] || {};
    }

    get currentStepValue() {
        return this.currentStep.value;
    }

    get isOwnersStep() {
        return this.currentStep.value === OWNERS_STEP;
    }

    get isAiUserStep() {
        return this.currentStep.value === AI_USER_STEP;
    }

    get isCategoryStep() {
        return !this.isOwnersStep && !this.isAiUserStep;
    }

    get isFirstStep() {
        return this.stepIndex === 0;
    }

    get isLastStep() {
        return this.stepIndex >= this.steps.length - 1;
    }

    get showDpoReason() {
        return !this.owners.dpoName;
    }

    get agentUser() {
        return this.data && this.data.agentUser;
    }

    get currentItems() {
        const cat = ((this.data && this.data.categories) || []).find((c) => c.code === this.currentStep.value);
        if (!cat) {
            return [];
        }
        return cat.results.map((r) => {
            const a = this.answers[r.code] || {};
            const open = !!this.adviceOpen[r.code];
            const resources = r.resources || [];
            return {
                ...r,
                answer: a.answer,
                notes: a.notes,
                responsible: a.responsible,
                dueDate: a.dueDate,
                adviceOpen: open,
                adviceLabel: open ? 'Hide advice' : 'Show advice',
                hasResources: resources.length > 0,
                resourceList: resources.map((res, i) => ({ ...res, key: `${r.code}-${i}` }))
            };
        });
    }

    get automatedItems() {
        return ((this.data && this.data.automated) || []).map((r) => ({
            ...r,
            statusClass: statusClass(r.status),
            showAdvice: r.status === STATUS.ATTENTION
        }));
    }

    get summary() {
        return (this.data && this.data.summary) || {};
    }

    get summaryScore() {
        return formatPercent(this.summary.score);
    }

    get summaryCoverage() {
        return formatPercent(this.summary.coverage);
    }

    get summaryCounts() {
        return countsLine(this.summary);
    }

    get summaryHealthClass() {
        return `${healthClass(this.summary.health)} air-strong`;
    }

    // ------------------------------------------------------------------ handlers

    handleLevel(event) {
        const value = event.currentTarget.dataset.value;
        if (value !== this.level) {
            this.level = value;
            this.load();
        }
    }

    handleUseCase(event) {
        this.useCaseId = event.detail.value;
        this.usernameInput = '';
        this.load();
    }

    handleField(event) {
        const { code, field } = event.currentTarget.dataset;
        const current = this.answers[code] || {};
        this.answers = { ...this.answers, [code]: { ...current, [field]: event.detail.value } };
    }

    handleOwner(event) {
        const field = event.currentTarget.dataset.owner;
        this.owners = { ...this.owners, [field]: event.detail.value };
    }

    handleUsername(event) {
        this.usernameInput = event.detail.value;
    }

    toggleAdvice(event) {
        const code = event.currentTarget.dataset.code;
        this.adviceOpen = { ...this.adviceOpen, [code]: !this.adviceOpen[code] };
    }

    async handleSetUser() {
        this.busy = true;
        try {
            this.apply(await setAgentUser({ useCaseId: this.useCaseId, username: this.usernameInput }));
            this.toast('AI integration user saved', 'The access checks now run against this user.', 'success');
        } catch (e) {
            this.toast('Could not set the user', errorMessage(e), 'error');
        } finally {
            this.busy = false;
        }
    }

    async handleRunChecks() {
        this.busy = true;
        try {
            this.applyKeepingAnswers(await runUseCaseChecks({ useCaseId: this.useCaseId }));
        } catch (e) {
            this.toast('Checks failed', errorMessage(e), 'error');
        } finally {
            this.busy = false;
        }
    }

    applyKeepingAnswers(data) {
        const answers = this.answers;
        const owners = this.owners;
        this.apply(data);
        this.answers = { ...this.answers, ...answers };
        this.owners = { ...this.owners, ...owners };
    }

    async save(showToast) {
        this.busy = true;
        try {
            const answers = Object.keys(this.answers).map((code) => {
                const a = this.answers[code];
                return {
                    code,
                    answer: a.answer || null,
                    notes: a.notes || null,
                    responsible: a.responsible || null,
                    dueDate: a.dueDate || null
                };
            });
            const result = await saveChecklist({
                level: this.level,
                useCaseId: this.isImplementation ? this.useCaseId : null,
                answersJson: JSON.stringify(answers),
                ownersJson: this.level === 'Company' ? JSON.stringify(this.owners) : null
            });
            this.applyKeepingAnswers(result);
            if (showToast) {
                this.toast('Saved', 'Your answers are saved.', 'success');
            }
            return true;
        } catch (e) {
            this.toast('Could not save', errorMessage(e), 'error');
            return false;
        } finally {
            this.busy = false;
        }
    }

    handleSave() {
        this.save(true);
    }

    async handleNext() {
        if (await this.save(false)) {
            this.stepIndex = Math.min(this.stepIndex + 1, this.steps.length - 1);
            this.scrollTop();
        }
    }

    handleBack() {
        this.stepIndex = Math.max(this.stepIndex - 1, 0);
        this.scrollTop();
    }

    async handleFinish() {
        if (await this.save(false)) {
            this.finished = true;
            this.scrollTop();
        }
    }

    backToChecklist() {
        this.finished = false;
    }

    scrollTop() {
        const page = this.template.querySelector('.air-page');
        if (page && page.scrollIntoView) {
            page.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    openHome() {
        this[NavigationMixin.Navigate](navItem(TABS.HOME));
    }

    openUseCases() {
        this[NavigationMixin.Navigate](navItem(TABS.USE_CASES));
    }
}
