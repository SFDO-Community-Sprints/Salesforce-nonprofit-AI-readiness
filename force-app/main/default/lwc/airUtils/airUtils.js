// Shared helpers for the AI Readiness Check components.

export const STATUS = {
    PASSED: 'Passed',
    ATTENTION: 'Needs attention',
    NOT_CHECKED: 'Not checked'
};

export const HEALTH = {
    NOT_CHECKED: 'Not checked',
    BLOCKED: 'Blocked',
    READY: 'Ready for pilot',
    ATTENTION: 'Needs attention'
};

export const TABS = {
    HOME: 'AIR_Home',
    ORG_SCAN: 'AIR_Org_Scan',
    CHECKLISTS: 'AIR_Checklists',
    USE_CASES: 'AIR_Use_Cases'
};

/** 40 -> "40%", 38.5 -> "38.5%", 24.24 -> "24.2%". Null or undefined -> "–". */
export function formatPercent(value) {
    if (value === null || value === undefined || value === '') {
        return '–';
    }
    const rounded = Math.round(Number(value) * 10) / 10;
    return `${rounded}%`;
}

export function formatCount(value) {
    return value === null || value === undefined ? '–' : String(value);
}

export function formatDateTime(value) {
    if (!value) {
        return '';
    }
    try {
        return new Intl.DateTimeFormat(undefined, {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(new Date(value));
    } catch (e) {
        return String(value);
    }
}

export function statusClass(status) {
    switch (status) {
        case STATUS.PASSED:
            return 'air-status air-status_passed';
        case STATUS.ATTENTION:
            return 'air-status air-status_attention';
        default:
            return 'air-status air-status_unchecked';
    }
}

export function healthClass(health) {
    switch (health) {
        case HEALTH.READY:
            return 'air-health air-health_ready';
        case HEALTH.BLOCKED:
            return 'air-health air-health_blocked';
        case HEALTH.ATTENTION:
            return 'air-health air-health_attention';
        default:
            return 'air-health air-health_unchecked';
    }
}

/** "2 passed · 2 need attention · 1 not checked" */
export function countsLine(summary) {
    if (!summary) {
        return '';
    }
    return `${summary.passed} passed · ${summary.attention} need attention · ${summary.notChecked} not checked`;
}

export function navItem(apiName, state) {
    return {
        type: 'standard__navItemPage',
        attributes: { apiName },
        state: state || {}
    };
}

/** Readable message from an Apex / LDS error. */
export function errorMessage(error) {
    if (!error) {
        return 'Unknown error';
    }
    if (Array.isArray(error.body)) {
        return error.body.map((e) => e.message).join(', ');
    }
    if (error.body && error.body.message) {
        return error.body.message;
    }
    return error.message || JSON.stringify(error);
}
