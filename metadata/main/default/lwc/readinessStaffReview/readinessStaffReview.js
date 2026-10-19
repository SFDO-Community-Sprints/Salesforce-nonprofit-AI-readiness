import { LightningElement } from 'lwc';
import hasReviewPermission from '@salesforce/customPermission/Readiness_Review_Staff';
import getQuestions from '@salesforce/apex/ReadinessStaffReview.getQuestions';
import getLatestReview from '@salesforce/apex/ReadinessStaffReview.getLatestReview';
import saveReview from '@salesforce/apex/ReadinessStaffReview.saveReview';

const TITLES = {
    scope: 'Approved scope and human decisions', sensitive_data: 'Sensitive data and deletion requests',
    untrusted_content: 'False claims and unsafe source instructions', access: 'What the assistant can access',
    quality: 'Reliable information and stewardship', review: 'Review before consequential actions',
    incident: 'Detection, stopping and recovery'
};
const CHOICES = [
    { label: 'Demonstrated', value: 'yes' }, { label: 'Partly demonstrated', value: 'partly' },
    { label: 'Not demonstrated', value: 'no' }, { label: 'Not observed', value: 'unknown' }
];

function buildSnapshot(version, questions) {
    return { version, mode: 'actual', reviews: questions.map(question => {
        const actions = Object.fromEntries(question.required_actions.map(action => [action.id, action.value]));
        const values = Object.values(actions);
        const answer = values.length && values.every(value => value === 'yes') ? 'yes' :
            values.includes('no') ? 'no' : values.includes('partly') ? 'partly' : 'unknown';
        return { question_id: question.id, answer, reviewer_confirmed: question.reviewer_confirmed,
            evidence_ref: question.evidence_ref || null, actions,
            critical_failures: question.critical_failures.filter(failure => failure.checked).map(failure => failure.id) };
    }) };
}

export default class ReadinessStaffReview extends LightningElement {
    questions = [];
    version;
    loading = true;
    saving = false;
    error;
    message;
    latest;
    choices = CHOICES;
    canReview = Boolean(hasReviewPermission);

    async connectedCallback() {
        try {
            const [keyText, reviewText] = await Promise.all([getQuestions(), getLatestReview()]);
            const key = JSON.parse(keyText);
            this.version = key.version;
            this.questions = key.questions.map((question, index) => ({ ...question,
                title: `${index + 1}. ${TITLES[question.id] || 'Staff exercise'}`,
                reviewer_confirmed: false, evidence_ref: '',
                required_actions: question.required_actions.map(action => ({ ...action, value: 'unknown' })),
                critical_failures: question.critical_failures.map(failure => ({ ...failure, checked: false })) }));
            this.acceptResult(JSON.parse(reviewText));
        } catch (error) {
            this.error = 'Staff review could not be loaded. Refresh or contact your Salesforce administrator.';
            this.acceptResult(null);
        } finally {
            this.loading = false;
        }
    }

    acceptResult(result) {
        if (result && (!result.staff || result.error)) throw new Error('Review unavailable');
        this.latest = result;
        this.dispatchEvent(new CustomEvent('staffreview', { detail: result }));
    }

    changeQuestion(event) {
        const { question, action, failure, field } = event.target.dataset;
        this.questions = this.questions.map(item => item.id !== question ? item : {
            ...item,
            ...(field === 'confirmation' ? { reviewer_confirmed: event.target.checked } : {}),
            ...(field === 'evidence' ? { evidence_ref: event.target.value } : {}),
            required_actions: item.required_actions.map(entry => entry.id === action ?
                { ...entry, value: event.detail.value } : entry),
            critical_failures: item.critical_failures.map(entry => entry.id === failure ?
                { ...entry, checked: event.target.checked } : entry)
        });
        this.message = undefined;
    }

    async save() {
        if (this.disabled) return;
        const valid = [...this.template.querySelectorAll('lightning-input')].map(input => input.reportValidity()).every(Boolean);
        if (!valid) return;
        this.saving = true;
        this.error = undefined;
        this.message = undefined;
        try {
            const result = JSON.parse(await saveReview({ snapshot: JSON.stringify(buildSnapshot(this.version, this.questions)) }));
            this.acceptResult(result);
            this.message = 'Your observed staff review was saved. This does not establish whole-team or technical readiness.';
        } catch (error) {
            this.error = 'Staff review was not saved. Check your access and evidence references, then try again.';
        } finally {
            this.saving = false;
        }
    }

    get disabled() { return !this.canReview || this.loading || this.saving || !this.questions.length; }
    get score() { return this.latest && this.latest.staff.score !== null ? `${this.latest.staff.score}%` : 'Not assessed'; }
    get coverage() { return this.latest ? `${this.latest.staff.coverage}%` : 'Not assessed'; }
    get reviewedAt() { return this.latest && this.latest.reviewed_at; }
    get savedChecks() {
        return Object.keys(TITLES).map(id => ({ id,
            label: TITLES[id], outcome: this.latest?.staff?.checks[id] === 'pass' ? 'Demonstrated' : this.latest?.staff?.checks[id] === 'fail' ? 'Needs attention' : 'Not assessed' }));
    }
}
