"""Fail-closed output boundary: only validated aggregate counts may reach agents."""
from demo import VERSION, data_checks, summarize, recommendations

METRIC_KEYS = frozenset({'contacts', 'email_present', 'linked_contacts', 'repeated_email_rows'})
MINIMUM_COHORT = 5


def build_data_result(metrics, synthetic=False):
    """Return aggregate evidence, suppressing small real cohorts and derived checks."""
    if (type(synthetic) is not bool or type(metrics) is not dict
            or metrics.keys() != METRIC_KEYS
            or any(type(value) is not int or value < 0 for value in metrics.values())):
        raise ValueError('Invalid aggregate metrics')
    n = metrics['contacts']
    populated = metrics['email_present']
    if (populated > n or metrics['linked_contacts'] > n
            or metrics['repeated_email_rows'] > max(0, populated - 1)):
        raise ValueError('Invalid aggregate metrics')
    suppressed = n < MINIMUM_COHORT and not synthetic
    checks = data_checks(metrics)
    if suppressed:
        checks = dict.fromkeys(checks, 'unknown')
    data = summarize(checks)
    if suppressed:
        data['score'] = None
    return {
        'rubric_version': VERSION,
        'evidence_mode': 'synthetic_simulation' if synthetic else 'live_aggregate',
        'metrics': None if suppressed else dict(metrics),
        'data': data,
        'priorities': recommendations(None if suppressed else metrics),
        'privacy': {'mode': 'aggregate_only', 'minimum_cohort': MINIMUM_COHORT,
                    'suppressed': suppressed},
    }
