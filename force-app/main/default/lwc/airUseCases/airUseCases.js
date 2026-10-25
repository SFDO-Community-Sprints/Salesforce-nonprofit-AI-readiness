import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUseCases from '@salesforce/apex/AIR_Controller.getUseCases';
import { TABS, errorMessage, formatPercent, navItem } from 'c/airUtils';

const ACTIONS = [
    { label: 'Assess', name: 'assess' },
    { label: 'Edit', name: 'edit' },
    { label: 'Open record', name: 'open' }
];

const COLUMNS = [
    { label: 'Name', fieldName: 'name', wrapText: true },
    { label: 'Status', fieldName: 'status', initialWidth: 120 },
    { label: 'Business owner', fieldName: 'businessOwner' },
    { label: 'Score', fieldName: 'scoreText', initialWidth: 100 },
    { label: 'Checks completed', fieldName: 'coverageText', initialWidth: 150 },
    { label: 'Health', fieldName: 'health', initialWidth: 150 },
    { label: 'Critical failures', fieldName: 'criticalFailures', type: 'number', initialWidth: 140 },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class AirUseCases extends NavigationMixin(LightningElement) {
    useCases = [];
    busy = false;
    loaded = false;
    error;
    showForm = false;
    editId;
    savedId;
    savedName;

    columns = COLUMNS;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.busy = true;
        try {
            this.useCases = await getUseCases();
            this.error = undefined;
        } catch (e) {
            this.error = errorMessage(e);
        } finally {
            this.busy = false;
            this.loaded = true;
        }
    }

    get rows() {
        return this.useCases.map((u) => ({
            ...u,
            scoreText: u.assessmentId ? formatPercent(u.score) : '–',
            coverageText: u.assessmentId ? formatPercent(u.coverage) : '–',
            criticalFailures: u.assessmentId ? u.criticalFailures : null
        }));
    }

    get hasUseCases() {
        return this.useCases && this.useCases.length > 0;
    }

    get formTitle() {
        return this.editId ? 'Edit use case' : 'New AI use case';
    }

    handleNew() {
        this.editId = undefined;
        this.showForm = true;
        this.savedId = undefined;
    }

    handleCancel() {
        this.showForm = false;
        this.editId = undefined;
    }

    handleSuccess(event) {
        this.savedId = event.detail.id;
        const nameField = event.detail.fields && event.detail.fields.Name;
        this.savedName = nameField ? nameField.value : 'The use case';
        this.showForm = false;
        this.editId = undefined;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Use case saved',
                message: 'Start its implementation assessment from the banner.',
                variant: 'success'
            })
        );
        this.load();
    }

    handleFormError(event) {
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Could not save', message: errorMessage(event.detail), variant: 'error' })
        );
    }

    handleRowAction(event) {
        const { name } = event.detail.action;
        const row = event.detail.row;
        if (name === 'assess') {
            this.openAssessment(row.id);
        } else if (name === 'edit') {
            this.editId = row.id;
            this.showForm = true;
            this.savedId = undefined;
        } else if (name === 'open') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: row.id, objectApiName: 'AIR_Use_Case__c', actionName: 'view' }
            });
        }
    }

    startSavedAssessment() {
        this.openAssessment(this.savedId);
    }

    dismissSaved() {
        this.savedId = undefined;
    }

    openAssessment(useCaseId) {
        this[NavigationMixin.Navigate](
            navItem(TABS.CHECKLISTS, { c__level: 'Implementation', c__useCaseId: useCaseId })
        );
    }
}
