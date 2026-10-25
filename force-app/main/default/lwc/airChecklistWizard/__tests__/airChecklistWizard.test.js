import { createElement } from 'lwc';
import AirChecklistWizard from 'c/airChecklistWizard';
import getChecklist from '@salesforce/apex/AIR_Controller.getChecklist';
import getUseCases from '@salesforce/apex/AIR_Controller.getUseCases';
import saveChecklist from '@salesforce/apex/AIR_Controller.saveChecklist';

jest.mock('@salesforce/apex/AIR_Controller.getChecklist', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AIR_Controller.saveChecklist', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AIR_Controller.getUseCases', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AIR_Controller.setAgentUser', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AIR_Controller.runUseCaseChecks', () => ({ default: jest.fn() }), { virtual: true });

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const CHECKLIST = {
    level: 'Company',
    owners: {},
    summary: { score: 0, coverage: 0, passed: 0, attention: 0, notChecked: 1, health: 'Not checked' },
    automated: [],
    categories: [
        {
            code: 'STAFF',
            label: 'Staff readiness',
            summary: {},
            results: [
                {
                    code: 'C01_DPO',
                    title: 'Data Protection Officer',
                    topic: 'T5',
                    critical: true,
                    question: 'Have you appointed a DPO?',
                    passCriteria: 'A DPO is named.',
                    advice: 'Appoint one.',
                    resources: [],
                    status: 'Not checked'
                }
            ]
        }
    ]
};

describe('c-air-checklist-wizard', () => {
    it('walks from responsible people to the questions and saves', async () => {
        getUseCases.mockResolvedValue([]);
        getChecklist.mockResolvedValue(CHECKLIST);
        saveChecklist.mockResolvedValue(CHECKLIST);
        const element = createElement('c-air-checklist-wizard', { is: AirChecklistWizard });
        document.body.appendChild(element);
        await flush();

        expect(element.shadowRoot.textContent).toContain('Responsible people');
        const next = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((b) => b.label === 'Next');
        next.click();
        await flush();
        expect(saveChecklist).toHaveBeenCalled();
        expect(element.shadowRoot.textContent).toContain('Have you appointed a DPO?');
        const finish = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(
            (b) => b.label === 'Finish'
        );
        expect(finish).toBeTruthy();
    });
});
