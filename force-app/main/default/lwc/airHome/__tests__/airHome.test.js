import { createElement } from 'lwc';
import AirHome from 'c/airHome';
import getDashboard from '@salesforce/apex/AIR_Controller.getDashboard';

jest.mock(
    '@salesforce/apex/AIR_Controller.getDashboard',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock('@salesforce/apex/AIR_Controller.runOrgScan', () => ({ default: jest.fn() }), { virtual: true });

const summary = (score, coverage, passed, attention, notChecked, health) => ({
    score,
    coverage,
    passed,
    attention,
    notChecked,
    total: passed + attention + notChecked,
    criticalFailures: 0,
    health
});

// Numbers from docs/mockup-home-dashboard.png
const MOCK = {
    hasScan: true,
    lastScanDate: '2026-10-20T09:00:00.000Z',
    lastScanBy: 'Admin User',
    scanStale: false,
    companyAnswered: true,
    overall: summary(24.2, 39.4, 8, 5, 20, 'Needs attention'),
    categories: [
        { code: 'DQ', label: 'Data quality', summary: summary(40, 80, 2, 2, 1, 'Needs attention'), results: [] },
        {
            code: 'ACCESS',
            label: 'Access and safeguards',
            summary: summary(38.5, 53.8, 5, 2, 6, 'Needs attention'),
            results: []
        },
        { code: 'STAFF', label: 'Staff readiness', summary: summary(0, 0, 0, 0, 7, 'Not checked'), results: [] },
        { code: 'PRIVACY', label: 'Privacy and erasure', summary: summary(12.5, 25, 1, 1, 6, 'Needs attention'), results: [] }
    ],
    criticalFailures: []
};

describe('c-air-home', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the dashboard like the mockup', async () => {
        const element = createElement('c-air-home', { is: AirHome });
        document.body.appendChild(element);
        getDashboard.emit(MOCK);
        await Promise.resolve();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('AI readiness health');
        expect(text).toContain('24.2%');
        expect(text).toContain('39.4%');
        expect(text).not.toContain('Access inventory');
        expect(text).toContain('Data quality');
        expect(text).toContain('40%');
        expect(text).toContain('Checks completed: 80%');
        expect(text).toContain('2 passed · 2 need attention · 1 not checked');
        expect(text).toContain('38.5%');
        expect(text).toContain('Checks completed: 53.8%');
        expect(text).toContain('12.5%');
        expect(text).toContain('No critical failures');
        expect(text).toContain('never use a System Administrator account');

        const cards = element.shadowRoot.querySelectorAll('.air-grid_4 .air-card');
        expect(cards.length).toBe(4);
        expect(cards[2].querySelector('.air-big').textContent).toBe('Not checked');

        const arc = element.shadowRoot.querySelector('.air-donut__arc');
        expect(arc.getAttribute('class')).toContain('air-donut__arc_attention');
    });

    it('shows critical failures', async () => {
        const element = createElement('c-air-home', { is: AirHome });
        document.body.appendChild(element);
        getDashboard.emit({
            ...MOCK,
            overall: { ...MOCK.overall, criticalFailures: 1, health: 'Blocked' },
            criticalFailures: [
                {
                    code: 'C01_DPO',
                    title: 'Data Protection Officer',
                    categoryLabel: 'Staff readiness',
                    topic: 'T5',
                    level: 'Company',
                    checkType: 'Manual',
                    evidence: 'Answered: No.',
                    advice: 'Appoint a DPO.'
                }
            ]
        });
        await Promise.resolve();
        const text = element.shadowRoot.textContent;
        expect(text).toContain('Data Protection Officer');
        expect(text).toContain('Appoint a DPO.');
        expect(element.shadowRoot.querySelector('.air-donut__arc').getAttribute('class')).toContain('blocked');
    });
});
