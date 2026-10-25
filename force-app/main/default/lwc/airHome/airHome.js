import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getDashboard from '@salesforce/apex/AIR_Controller.getDashboard';
import runOrgScan from '@salesforce/apex/AIR_Controller.runOrgScan';
import {
    HEALTH,
    TABS,
    countsLine,
    errorMessage,
    formatDateTime,
    formatPercent,
    navItem
} from 'c/airUtils';

const CIRCUMFERENCE = 2 * Math.PI * 50;

export default class AirHome extends NavigationMixin(LightningElement) {
    data;
    error;
    scanning = false;
    wiredResult;
    accessIntroHidden = false;

    @wire(getDashboard)
    wiredDashboard(result) {
        this.wiredResult = result;
        if (result.data) {
            this.data = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = errorMessage(result.error);
        }
    }

    connectedCallback() {
        try {
            this.accessIntroHidden = window.sessionStorage.getItem('air.accessIntroHidden') === '1';
        } catch (e) {
            this.accessIntroHidden = false;
        }
        // Pick up changes made on other tabs (checklists, scans) when the page is revisited.
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
    }

    get overall() {
        return (this.data && this.data.overall) || {};
    }

    get overallScore() {
        return formatPercent(this.overall.score);
    }

    get overallCoverage() {
        return formatPercent(this.overall.coverage);
    }

    get dashArray() {
        const score = Math.max(0, Math.min(100, Number(this.overall.score) || 0));
        const arc = (score / 100) * CIRCUMFERENCE;
        return `${arc} ${CIRCUMFERENCE}`;
    }

    get arcClass() {
        switch (this.overall.health) {
            case HEALTH.READY:
                return 'air-donut__arc air-donut__arc_ready';
            case HEALTH.BLOCKED:
                return 'air-donut__arc air-donut__arc_blocked';
            case HEALTH.ATTENTION:
                return 'air-donut__arc air-donut__arc_attention';
            default:
                return 'air-donut__arc air-donut__arc_unchecked';
        }
    }

    get subtitle() {
        const rules =
            'Automated results older than 24 hours should be refreshed. Unknown checks earn no points; score = passed / all defined checks.';
        if (!this.data || !this.data.hasScan) {
            return `No org scan has run yet. ${rules}`;
        }
        const by = this.data.lastScanBy ? ` by ${this.data.lastScanBy}` : '';
        return `Last org scan: ${formatDateTime(this.data.lastScanDate)}${by}. ${rules}`;
    }

    get scanStale() {
        return this.data && this.data.scanStale;
    }

    get showAccessIntro() {
        return !this.accessIntroHidden;
    }

    hideAccessIntro() {
        this.accessIntroHidden = true;
        try {
            window.sessionStorage.setItem('air.accessIntroHidden', '1');
        } catch (e) {
            // storage unavailable: hide for this page view only
        }
    }

    openUseCases() {
        this[NavigationMixin.Navigate](navItem(TABS.USE_CASES));
    }

    get showCompanyBanner() {
        return this.data && !this.data.companyAnswered;
    }

    get categories() {
        const cats = (this.data && this.data.categories) || [];
        return cats.map((cat) => {
            const unchecked = cat.summary.health === HEALTH.NOT_CHECKED;
            return {
                ...cat,
                headline: unchecked ? 'Not checked' : formatPercent(cat.summary.score),
                coverage: formatPercent(cat.summary.coverage),
                counts: countsLine(cat.summary),
                ariaLabel: `Open ${cat.label} results`
            };
        });
    }

    get criticalFailures() {
        const items = (this.data && this.data.criticalFailures) || [];
        return items.map((item) => ({
            ...item,
            linkLabel: item.checkType === 'Automated' ? 'Open in Org scan' : `Answer in ${item.level} checklist`
        }));
    }

    get hasCriticalFailures() {
        return this.criticalFailures.length > 0;
    }

    async handleScan() {
        this.scanning = true;
        try {
            await runOrgScan();
            await refreshApex(this.wiredResult);
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
            this.scanning = false;
        }
    }

    openCategory(event) {
        this[NavigationMixin.Navigate](navItem(TABS.ORG_SCAN, { c__category: event.currentTarget.dataset.category }));
    }

    openCategoryKey(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.openCategory(event);
        }
    }

    openItem(event) {
        const item = this.criticalFailures.find((i) => i.code === event.currentTarget.dataset.code);
        if (!item) {
            return;
        }
        if (item.checkType === 'Automated') {
            this[NavigationMixin.Navigate](navItem(TABS.ORG_SCAN, { c__category: item.category }));
        } else {
            this[NavigationMixin.Navigate](navItem(TABS.CHECKLISTS, { c__level: item.level }));
        }
    }

    openCompanyChecklist() {
        this[NavigationMixin.Navigate](navItem(TABS.CHECKLISTS, { c__level: 'Company' }));
    }
}
