import { createElement } from 'lwc';
import AirUseCases from 'c/airUseCases';
import getUseCases from '@salesforce/apex/AIR_Controller.getUseCases';

jest.mock('@salesforce/apex/AIR_Controller.getUseCases', () => ({ default: jest.fn() }), { virtual: true });

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-air-use-cases', () => {
    it('lists use cases and opens the intake form', async () => {
        getUseCases.mockResolvedValue([
            { id: 'a01000000000001', name: 'Donor FAQ agent', status: 'Approved', assessmentId: 'a00', score: 50, coverage: 75, health: 'Needs attention', criticalFailures: 0 }
        ]);
        const element = createElement('c-air-use-cases', { is: AirUseCases });
        document.body.appendChild(element);
        await flush();
        const table = element.shadowRoot.querySelector('lightning-datatable');
        expect(table.data[0].scoreText).toBe('50%');
        expect(table.data[0].coverageText).toBe('75%');

        const newButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(
            (b) => b.label === 'New use case'
        );
        newButton.click();
        await flush();
        expect(element.shadowRoot.querySelector('lightning-record-edit-form')).toBeTruthy();
        expect(element.shadowRoot.textContent).toContain('never as a System Administrator');
    });
});
