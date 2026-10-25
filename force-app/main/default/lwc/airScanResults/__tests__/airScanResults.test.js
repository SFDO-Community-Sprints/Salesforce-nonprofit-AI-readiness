import { createElement } from 'lwc';
import AirScanResults from 'c/airScanResults';
import getAssessmentDetail from '@salesforce/apex/AIR_Controller.getAssessmentDetail';

jest.mock('@salesforce/apex/AIR_Controller.getAssessmentDetail', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AIR_Controller.runOrgScan', () => ({ default: jest.fn() }), { virtual: true });

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-air-scan-results', () => {
    it('renders results grouped by category with filters', async () => {
        getAssessmentDetail.mockResolvedValue({
            assessmentId: 'a00000000000001',
            name: 'AIR-0001',
            runDate: '2026-10-20T09:00:00.000Z',
            runBy: 'Admin',
            stale: false,
            summary: { score: 50, coverage: 100, passed: 1, attention: 1, notChecked: 0, criticalFailures: 1 },
            categories: [
                {
                    code: 'ACCESS',
                    label: 'Access and safeguards',
                    summary: { score: 50, coverage: 100, passed: 1, attention: 1, notChecked: 0 },
                    results: [
                        {
                            code: 'A11_ViewModifyAllData',
                            title: 'Few users can see all data',
                            topic: 'T4',
                            status: 'Needs attention',
                            critical: true,
                            checkType: 'Automated',
                            evidence: '5 active users hold View All Data',
                            resources: [{ label: 'Trailhead', url: 'https://trailhead.salesforce.com' }]
                        },
                        {
                            code: 'O04_IntegrationReview',
                            title: 'Integrations reviewed yearly',
                            topic: 'T1',
                            status: 'Passed',
                            critical: false,
                            checkType: 'Manual',
                            evidence: 'Answered: Yes.',
                            resources: []
                        }
                    ]
                }
            ]
        });
        const element = createElement('c-air-scan-results', { is: AirScanResults });
        document.body.appendChild(element);
        await flush();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('Few users can see all data');
        expect(text).toContain('Manual – answer in Checklists');
        expect(element.shadowRoot.querySelectorAll('.air-item').length).toBe(2);

        // Filter to Passed only
        const passedButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(
            (b) => b.dataset.value === 'Passed'
        );
        passedButton.click();
        await flush();
        expect(element.shadowRoot.querySelectorAll('.air-item').length).toBe(1);
    });
});
