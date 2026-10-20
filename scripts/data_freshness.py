"""Evaluate a separately approved freshness policy from aggregate evidence only."""
import argparse
from datetime import datetime, timezone
import json
from demo import summarize


def timestamp(value):
    if type(value) is not str:
        raise ValueError('Invalid freshness snapshot')
    try:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        raise ValueError('Invalid freshness snapshot') from None
    if result.tzinfo is None:
        raise ValueError('Invalid freshness snapshot')
    return result.astimezone(timezone.utc)


def evaluate(snapshot):
    """Count only records with verified activity within the declared window."""
    invalid = ValueError('Invalid freshness snapshot')
    if type(snapshot) is not dict or set(snapshot) != {'version', 'as_of', 'policy', 'metrics'}:
        raise invalid
    policy = snapshot['policy']
    if (snapshot['version'] != 'data-freshness-v1' or type(policy) is not dict
            or set(policy) != {'version', 'window_days', 'minimum_recent_percent', 'minimum_cohort'}
            or type(policy['version']) is not str or not policy['version'].isascii()
            or not 1 <= len(policy['version']) <= 80
            or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-' for c in policy['version'])
            or type(policy['window_days']) is not int or policy['window_days'] <= 0
            or type(policy['minimum_recent_percent']) is not int or not 0 <= policy['minimum_recent_percent'] <= 100
            or type(policy['minimum_cohort']) is not int or policy['minimum_cohort'] < 5):
        raise invalid
    as_of = timestamp(snapshot['as_of'])
    metrics = snapshot['metrics']
    status, reason = 'unknown', 'missing_evidence'
    safe_metrics = None
    if metrics is not None:
        if (type(metrics) is not dict or set(metrics) != {'records', 'recent_records', 'window_days', 'as_of'}
                or any(type(metrics[k]) is not int for k in ('records', 'recent_records', 'window_days'))
                or not 0 <= metrics['recent_records'] <= metrics['records']
                or metrics['window_days'] != policy['window_days']
                or timestamp(metrics['as_of']) != as_of):
            raise invalid
        n = metrics['records']
        if n < policy['minimum_cohort']:
            reason = 'cohort_withheld'
        else:
            status = 'pass' if metrics['recent_records'] * 100 >= n * policy['minimum_recent_percent'] else 'fail'
            reason = 'measured'
            safe_metrics = {'records': n, 'recent_records': metrics['recent_records']}
    return {'version': 'data-freshness-v1', 'as_of': as_of.isoformat(), 'policy': dict(policy),
            'metrics': safe_metrics, 'freshness': summarize({'freshness': status}), 'reason': reason,
            'decision': 'readiness_not_established'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('snapshot')
    args = parser.parse_args()
    try:
        with open(args.snapshot) as source:
            result = evaluate(json.load(source))
    except (OSError, ValueError, TypeError, OverflowError):
        parser.exit(1, 'Freshness evidence unavailable or invalid.\n')
    print(json.dumps(result, indent=2))
