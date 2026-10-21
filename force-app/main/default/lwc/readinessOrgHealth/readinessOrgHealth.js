import { LightningElement, api } from 'lwc';
import scan from '@salesforce/apex/ReadinessOrgHealth.scan';

const SETUP_LINKS = new Set([
    '/lightning/o/Contact/list',
    '/lightning/n/AI_Readiness', '/lightning/setup/DigitalExperiences/home',
    '/lightning/setup/PermSets/home',
    '/lightning/setup/Profiles/home', '/lightning/setup/Users/home',
    '/lightning/setup/Roles/home', '/lightning/setup/SecuritySession/home',
    '/lightning/setup/PasswordPolicies/home', '/lightning/setup/SharingSettings/home',
    '/lightning/setup/IdentityVerification/home', '/lightning/setup/ManageUsers/home'
]);
const safeLink = value => SETUP_LINKS.has(value) ? value : undefined;
export default class ReadinessOrgHealth extends LightningElement {
    result;
    stale = false;
    @api focusFindings() {
        const heading = this.template.querySelector('[data-findings-heading]');
        if (heading) {
            const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            heading.scrollIntoView({behavior: reducedMotion ? 'auto' : 'smooth', block: 'start'});
            heading.focus({preventScroll:true});
        }
    }
    @api markStale() { this.stale = true; }
    get historyNotice() { return this.result?.historyMessage; }
    loading = false;
    error;
    statusFilter = 'all';
    severityFilter = 'all';
    categoryFilter = 'all';
    @api displayReport(report) {
        this.stale = false;
        const result = typeof report === 'string' ? JSON.parse(report) : report;
        if (!result || result.error || !Array.isArray(result.findings) || !Number.isFinite(result.coverage)) throw new Error('Unavailable');
        this.result = result;
        this.error = undefined;
    }
    handleFilter(event) {
        const key = event.target.dataset.filter;
        if (['statusFilter', 'severityFilter', 'categoryFilter'].includes(key)) this[key] = event.target.value;
    }
    clearFilters() { this.statusFilter = 'all'; this.severityFilter = 'all'; this.categoryFilter = 'all'; }
    openChecklist(event) {
        const finding = this.findings.find(row => row.id === event.currentTarget.dataset.id);
        if (finding?.hasChecklist) this.dispatchEvent(new CustomEvent('openchecklist', { detail: {
            questionId: finding.questionId, scope: finding.checklistScope, useCaseId: finding.useCaseId
        }}));
    }
    @api async runScan() {
        this.stale = false;
        this.loading = true;
        this.result = undefined;
        this.error = undefined;
        try {
            this.displayReport(await scan());
        } catch (error) {
            this.error = 'Org health could not be checked with your access. No checks are marked as passed.';
        } finally { this.loading = false; }
    }
    get hasResult() { return Boolean(this.result); }
    get score() { return this.result?.score == null ? 'Not checked' : `${this.result.score}%`; }
    get rating() { return this.result?.rating || 'Not checked'; }
    get coverage() { return `${this.result?.coverage ?? 0}%`; }
    get observedAt() { return this.result?.observedAt || ''; }
    get passed() { return this.result?.passed ?? 0; }
    get failed() { return this.result?.failed ?? 0; }
    get unknown() { return this.result?.unknown ?? 0; }
    get ringStyle() {
        const score = Math.max(0, Math.min(100, Number(this.result?.score) || 0));
        return `background: conic-gradient(#df8b38 ${score}%, #e5e7eb 0);`;
    }
    get banner() { return this.result?.banner || 'Review failed and unmeasured checks before starting an AI pilot.'; }
    get scope() { return this.result?.scope || 'Accessible organization data and configuration'; }
    get sourceLabel() { return this.result?.source || 'Live assessment'; }
    get filterSummary() { return `${this.filteredFindings.length} of ${this.findings.length} findings shown. Filters do not change the score or checks completed.`; }
    get noMatches() { return this.filteredFindings.length === 0; }
    get statusOptions() { return this.options(['all', 'fail', 'unknown', 'pass'], this.statusFilter, ['All results', 'Needs attention', 'Not checked', 'Passed']); }
    get severityOptions() { return this.options(['all', 'Critical', 'High', 'Medium', 'Low', 'Info'], this.severityFilter, ['All severities', 'Critical', 'High', 'Medium', 'Low', 'Info']); }
    get categoryOptions() {
        const names = [...new Set(this.findings.map(row => row.group))];
        return this.options(['all', ...names], this.categoryFilter, ['All categories', ...names]);
    }
    options(values, selected, labels) { return values.map((value, index) => ({ value, label: labels[index], selected: value === selected })); }
    get filteredFindings() { return this.findings.filter(row =>
        (this.statusFilter === 'all' || row.status === this.statusFilter) &&
        (this.severityFilter === 'all' || row.severity === this.severityFilter) &&
        (this.categoryFilter === 'all' || row.group === this.categoryFilter)); }
    get findingGroups() {
        const groups = new Map();
        this.filteredFindings.forEach(row => {
            if (!groups.has(row.group)) groups.set(row.group, []);
            groups.get(row.group).push(row);
        });
        return [...groups].map(([label, rows]) => ({ label, rows, summary: `${label} (${rows.length})` }));
    }
    get categories() { return (this.result?.categories || []).map(row => ({...row,
        scoreLabel: row.score == null ? 'Not checked' : `${row.score}%`,
        coverageLabel: `${row.coverage ?? 0}%`
    })); }
    get findings() {
        const order = { fail: 0, unknown: 1, pass: 2 };
        const severity = { Critical: 0, High: 1, Medium: 2, Low: 3, Info: 4 };
        return (this.result?.findings || []).map(row => ({ ...row,
            statusLabel: row.status === 'pass' ? 'Passed' : row.status === 'fail' ? 'Needs attention' : 'Not checked',
            badgeClass: `badge ${['pass', 'fail'].includes(row.status) ? row.status : 'unknown'}`,
            group: row.group || row.category || 'Other checks',
            why: row.why || (row.status === 'pass' ? 'The observed result meets this check. A passed check does not establish overall readiness.' : row.status === 'fail' ? 'The observed result does not meet this check. Review the expected value and address the gap.' : 'There is not enough evidence to decide this check. Missing evidence is not a pass.'),
            how: row.how || row.action || 'Review the expected outcome and record supporting evidence.',
            hasChecklist: row.status === 'unknown' && Boolean(row.questionId) && ['company', 'org', 'implementation'].includes(row.checklistScope),
            safeUrl: safeLink(row.url)
        })).sort((a,b) => (order[a.status] ?? 1) - (order[b.status] ?? 1) || (severity[a.severity] ?? 4) - (severity[b.severity] ?? 4));
    }
    get inventory() { return (this.result?.inventory || []).map(row => ({...row, countLabel: row.count == null ? 'Not checked' : row.count})); }
}
