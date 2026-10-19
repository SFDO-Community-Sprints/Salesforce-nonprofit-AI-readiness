#!/usr/bin/env python3
"""Collect fixed Contact LastActivityDate aggregates in the bound practice org."""
import argparse
from datetime import datetime, timedelta, timezone
import json
import subprocess
from data_freshness import evaluate, timestamp
from scratch_demo import STATE, query, verify


def collect(state, policy, as_of):
    # Validate policy before constructing a query; callers cannot choose fields or SOQL.
    snapshot = {'version': 'data-freshness-v1', 'as_of': as_of, 'policy': policy, 'metrics': None}
    evaluate(snapshot)
    instant = timestamp(as_of)
    if instant.time() != datetime.min.time() or instant > datetime.now(timezone.utc):
        raise ValueError('Freshness collection requires a non-future UTC day boundary')
    start = (instant - timedelta(days=policy['window_days'])).date().isoformat()
    end = instant.date().isoformat()
    verify(state)
    rows = query(state['alias'], 'SELECT COUNT(Id) records FROM Contact')
    recent = query(state['alias'], 'SELECT COUNT(Id) recent_records FROM Contact '
                   f'WHERE LastActivityDate >= {start} AND LastActivityDate <= {end}')
    if (type(rows) is not list or type(recent) is not list or len(rows) != 1 or len(recent) != 1
            or type(rows[0]) is not dict or type(recent[0]) is not dict
            or set(rows[0]) - {'attributes', 'records'} or set(recent[0]) - {'attributes', 'recent_records'}):
        raise ValueError('Invalid freshness aggregate')
    snapshot['metrics'] = {'records': rows[0]['records'], 'recent_records': recent[0]['recent_records'],
                           'window_days': policy['window_days'], 'as_of': as_of}
    result = evaluate(snapshot)
    result.update({'source': 'salesforce', 'scope': 'accessible_organization_contacts',
                   'query_version': 'contact-last-activity-v1',
                   'measurement': 'Contact.LastActivityDate; inclusive UTC calendar dates; null is not recent',
                   'collected_at': datetime.now(timezone.utc).isoformat()})
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('policy', help='Explicit policy JSON; no defaults or customer approval inferred')
    parser.add_argument('--as-of', required=True, help='UTC midnight timestamp defining the assessment day')
    args = parser.parse_args()
    try:
        with open(args.policy) as source:
            policy = json.load(source)
        with open(STATE) as source:
            state = json.load(source)
        result = collect(state, policy, args.as_of)
    except (OSError, ValueError, TypeError, KeyError, OverflowError, RuntimeError, subprocess.TimeoutExpired):
        parser.exit(1, 'Freshness collection unavailable or invalid.\n')
    print(json.dumps(result, indent=2))
