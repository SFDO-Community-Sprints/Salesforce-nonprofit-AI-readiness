import { LightningElement, api } from 'lwc';
import scan from '@salesforce/apex/ReadinessOrgHealth.scan';

const SETUP_LINKS = new Set([
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
    loading = false;
    error;
    @api async runScan() {
        this.loading = true;
        this.result = undefined;
        this.error = undefined;
        try {
            const result = JSON.parse(await scan());
            if (!result || result.error || !Array.isArray(result.findings) || !Number.isFinite(result.coverage)) throw new Error('Unavailable');
            this.result = result;
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
    get categories() { return (this.result?.categories || []).map(row => ({...row,
        scoreLabel: row.score == null ? 'Not checked' : `${row.score}%`,
        coverageLabel: `${row.coverage ?? 0}%`
    })); }
    get findings() {
        const order = { fail: 0, unknown: 1, pass: 2 };
        return (this.result?.findings || []).map(row => ({ ...row,
            statusLabel: row.status === 'pass' ? 'Passed' : row.status === 'fail' ? 'Needs attention' : 'Not checked',
            badgeClass: `badge ${['pass', 'fail'].includes(row.status) ? row.status : 'unknown'}`,
            safeUrl: safeLink(row.url)
        })).sort((a,b) => (order[a.status] ?? 1) - (order[b.status] ?? 1));
    }
    get inventory() { return (this.result?.inventory || []).map(row => ({...row, countLabel: row.count == null ? 'Not checked' : row.count})); }
}
