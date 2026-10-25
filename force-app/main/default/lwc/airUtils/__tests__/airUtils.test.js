import { countsLine, formatPercent, statusClass } from 'c/airUtils';

describe('c/airUtils', () => {
    it('formats percentages with at most one decimal and no trailing .0', () => {
        expect(formatPercent(40)).toBe('40%');
        expect(formatPercent(40.0)).toBe('40%');
        expect(formatPercent(38.5)).toBe('38.5%');
        expect(formatPercent(24.24)).toBe('24.2%');
        expect(formatPercent(null)).toBe('–');
    });

    it('builds the counts line', () => {
        expect(countsLine({ passed: 0, attention: 0, notChecked: 7 })).toBe('0 passed · 0 need attention · 7 not checked');
        expect(countsLine({ passed: 1, attention: 1, notChecked: 6 })).toBe('1 passed · 1 need attention · 6 not checked');
    });

    it('maps statuses to classes', () => {
        expect(statusClass('Passed')).toContain('passed');
        expect(statusClass('Needs attention')).toContain('attention');
        expect(statusClass('Not checked')).toContain('unchecked');
    });
});
