import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssessmentDetail from '@salesforce/apex/AIR_Controller.getAssessmentDetail';
import runOrgScan from '@salesforce/apex/AIR_Controller.runOrgScan';
import {
    STATUS,
    TABS,
    countsLine,
    errorMessage,
    formatDateTime,
    formatPercent,
    navItem,
    statusClass
} from 'c/airUtils';

const STATUS_FILTERS = [
    { label: 'All', value: 'all' },
    { label: 'Needs attention', value: STATUS.ATTENTION },
    { label: 'Not checked', value: STATUS.NOT_CHECKED },
    { label: 'Passed', value: STATUS.PASSED },
    { label: 'Critical', value: 'critical' }
];

export default class AirScanResults extends NavigationMixin(LightningElement) {
    detail;
    error;
    busy = false;
    statusFilter = 'all';
    categoryFilter = 'all';
    expanded = {};

    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        const category = pageRef && pageRef.state && pageRef.state.c__category;
        if (category) {
            this.categoryFilter = category;
        }
    }

    connectedCallback() {
        this.load();
    }

    async load() {
        this.busy = true;
        try {
            this.detail = await getAssessmentDetail({ assessmentId: null });
            this.error = undefined;
        } catch (e) {
            this.error = errorMessage(e);
        } finally {
            this.busy = false;
        }
    }

    get subtitle() {
        if (!this.detail || !this.detail.assessmentId) {
            return 'No org scan has run yet. Run a scan to check your org settings automatically.';
        }
        const by = this.detail.runBy ? ` by ${this.detail.runBy}` : '';
        return `${this.detail.name}: last run ${formatDateTime(this.detail.runDate)}${by}. Automated results older than 24 hours should be refreshed.`;
    }

    get stale() {
        return this.detail && this.detail.stale;
    }

    get summary() {
        return (this.detail && this.detail.summary) || {};
    }

    get summaryScore() {
        return formatPercent(this.summary.score);
    }

    get summaryCoverage() {
        return formatPercent(this.summary.coverage);
    }

    get statusFilters() {
        return STATUS_FILTERS.map((f) => ({ ...f, variant: f.value === this.statusFilter ? 'brand' : 'neutral' }));
    }

    get categoryOptions() {
        const cats = (this.detail && this.detail.categories) || [];
        return [{ label: 'All categories', value: 'all' }, ...cats.map((c) => ({ label: c.label, value: c.code }))];
    }

    matches(item) {
        if (this.statusFilter === 'all') {
            return true;
        }
        if (this.statusFilter === 'critical') {
            return item.critical;
        }
        return item.status === this.statusFilter;
    }

    get visibleCategories() {
        const cats = (this.detail && this.detail.categories) || [];
        return cats
            .filter((c) => this.categoryFilter === 'all' || c.code === this.categoryFilter)
            .map((c) => {
                const items = c.results
                    .filter((r) => this.matches(r))
                    .map((r) => {
                        const open = !!this.expanded[r.code];
                        const resources = r.resources || [];
                        return {
                            ...r,
                            open,
                            isManual: r.checkType === 'Manual',
                            statusClass: statusClass(r.status),
                            toggleLabel: open ? 'Hide details' : 'Why and how to fix',
                            hasResources: resources.length > 0,
                            resourceList: resources.map((res, i) => ({ ...res, key: `${r.code}-${i}` }))
                        };
                    });
                return {
                    code: c.code,
                    sectionLabel: `${c.label} – ${formatPercent(c.summary.score)} · ${countsLine(c.summary)}`,
                    items
                };
            })
            .filter((c) => c.items.length > 0);
    }

    get openSections() {
        return this.visibleCategories.map((c) => c.code);
    }

    get hasResults() {
        return this.visibleCategories.length > 0;
    }

    handleStatusFilter(event) {
        this.statusFilter = event.currentTarget.dataset.value;
    }

    handleCategoryFilter(event) {
        this.categoryFilter = event.detail.value;
    }

    toggleFix(event) {
        const code = event.currentTarget.dataset.code;
        this.expanded = { ...this.expanded, [code]: !this.expanded[code] };
    }

    async handleScan() {
        this.busy = true;
        try {
            await runOrgScan();
            this.detail = await getAssessmentDetail({ assessmentId: null });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Org scan complete',
                    message: 'Results are up to date.',
                    variant: 'success'
                })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Org scan failed', message: errorMessage(e), variant: 'error' })
            );
        } finally {
            this.busy = false;
        }
    }

    openOrgChecklist() {
        this[NavigationMixin.Navigate](navItem(TABS.CHECKLISTS, { c__level: 'Org' }));
    }
}
