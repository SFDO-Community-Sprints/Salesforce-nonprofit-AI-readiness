#!/usr/bin/env python3
"""Score structured reviewer observations; never infer competence from prose."""
import argparse
import copy
from datetime import date
import json
from pathlib import Path
import re
import sys

from demo import ROOT, summarize

KEY = json.loads((ROOT / 'references/staff-answer-key.json').read_text())
ANSWERS = {'yes', 'partly', 'no', 'unknown'}
FIELDS = {'question_id', 'answer', 'reviewer_confirmed', 'evidence_ref', 'actions', 'critical_failures'}


def template():
    return {'version': KEY['version'], 'mode': 'actual', 'reviews': [
        {'question_id': q['id'], 'answer': 'unknown', 'reviewer_confirmed': False,
         'evidence_ref': None, 'actions': {a['id']: 'unknown' for a in q['required_actions']},
         'critical_failures': []} for q in KEY['questions']]}


def _evaluate(snapshot):
    def invalid():
        raise ValueError('Invalid staff review evidence')
    if (type(snapshot) is not dict or set(snapshot) not in ({'version', 'reviews'}, {'version', 'mode', 'reviews'})
            or snapshot['version'] != KEY['version'] or snapshot.get('mode', 'actual') not in ('actual', 'simulation')
            or type(snapshot['reviews']) is not list
            or len(snapshot['reviews']) > 7):
        invalid()
    questions = {q['id']: q for q in KEY['questions']}
    checks = dict.fromkeys(questions, 'unknown')
    seen = set()
    critical = []
    for review in snapshot['reviews']:
        if type(review) is not dict or set(review) != FIELDS:
            invalid()
        qid = review['question_id']
        if type(qid) is not str or qid not in questions or qid in seen:
            invalid()
        seen.add(qid)
        q = questions[qid]
        actions = review['actions']
        failures = review['critical_failures']
        ref = review['evidence_ref']
        if (type(review['answer']) is not str or review['answer'] not in ANSWERS
                or type(review['reviewer_confirmed']) is not bool
                or (ref is not None and (type(ref) is not str or not re.fullmatch(r'[A-Za-z0-9_-]{1,80}', ref)))
                or type(actions) is not dict
                or not set(actions).issubset({a['id'] for a in q['required_actions']})
                or any(type(v) is not str or v not in ANSWERS for v in actions.values())
                or type(failures) is not list
                or any(type(f) is not str or f not in {a['id'] for a in q['critical_failures']} for f in failures)
                or len(failures) != len(set(failures))):
            invalid()
        # Evidence refs are opaque local IDs; source artifacts stay outside agent output.
        if not review['reviewer_confirmed'] or not ref:
            continue
        if failures:
            checks[qid] = 'fail'
            critical.extend(qid + ':' + marker for marker in failures)
        elif review['answer'] in {'partly', 'no'} or any(v in {'partly', 'no'} for v in actions.values()):
            checks[qid] = 'fail'
        elif (review['answer'] == 'yes' and set(actions) == {a['id'] for a in q['required_actions']}
              and all(v == 'yes' for v in actions.values())):
            checks[qid] = 'pass'
    decision = ('blocked_by_observed_critical_failure' if critical else
                'staff_evidence_complete' if all(v == 'pass' for v in checks.values()) else
                'staff_readiness_not_established')
    simulated = snapshot.get('mode', 'actual') == 'simulation'
    if simulated:
        decision = ('blocked_by_simulated_critical_failure' if critical else
                    'staff_evidence_complete_simulation' if decision == 'staff_evidence_complete' else
                    'staff_readiness_not_established_simulation')
    follow_up = []
    for qid, status in checks.items():
        if status == 'pass':
            continue
        observed_critical = any(marker.startswith(qid + ':') for marker in critical)
        priority = 'Critical' if observed_critical else 'High' if status == 'fail' else 'Medium'
        follow_up.append({'question_id': qid, 'priority': priority,
            'impact': ('An observed unsafe action blocks a pilot until corrected and retested.' if observed_critical else
                       'Required staff actions were not fully demonstrated.' if status == 'fail' else
                       'Staff capability has not been established by confirmed evidence.'),
            'next_step': 'Demonstrate: ' + ' '.join(a['criterion'] for a in questions[qid]['required_actions'])})
    follow_up.sort(key=lambda item: {'Critical': 0, 'High': 1, 'Medium': 2}[item['priority']])
    return {'version': KEY['version'], 'evidence_mode': 'synthetic_simulation' if simulated else 'reviewer_confirmed_observations',
            'staff': summarize(checks), 'critical_failures': sorted(critical), 'follow_up': follow_up,
            'decision': decision, 'scope': 'reviewer_confirmed_exercises_only',
            'limitation': 'Staff results do not establish technical controls, legal compliance or pilot approval.'}


def evaluate(snapshot):
    if type(snapshot) is dict and 'freshness_policy' in snapshot:
        return evaluate_with_freshness({key: value for key, value in snapshot.items()
                                       if key != 'freshness_policy'}, snapshot['freshness_policy'])
    return _evaluate(snapshot)


def evaluate_with_freshness(snapshot, policy):
    """Apply an explicit offline policy without changing Salesforce scoring defaults."""
    _evaluate(snapshot)  # Validate the evidence before applying any policy.
    questions = {q['id'] for q in KEY['questions']}
    if (type(policy) is not dict or set(policy) != {'as_of', 'max_age_days', 'observed_on'}
            or type(policy['max_age_days']) is not int or not 0 <= policy['max_age_days'] <= 2147483647
            or type(policy['observed_on']) is not dict
            or not set(policy['observed_on']).issubset(questions)):
        raise ValueError('Invalid staff freshness policy')

    def parse_date(value):
        if type(value) is not str or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', value):
            raise ValueError('Invalid staff freshness policy')
        return date.fromisoformat(value)

    as_of = parse_date(policy['as_of'])
    statuses = dict.fromkeys(sorted(questions), 'missing')
    for qid, value in policy['observed_on'].items():
        age = (as_of - parse_date(value)).days
        if age < 0:
            raise ValueError('Invalid staff freshness policy')
        statuses[qid] = 'current' if age <= policy['max_age_days'] else 'expired'
    adjusted = copy.deepcopy(snapshot)
    for review in adjusted['reviews']:
        # Expiry cannot clear an observed critical failure; correction needs a new review.
        if statuses[review['question_id']] != 'current' and not review['critical_failures']:
            review['reviewer_confirmed'] = False
    result = _evaluate(adjusted)
    result['freshness'] = {'scope': 'offline_reviewer_validation_only',
                           'as_of': policy['as_of'], 'max_age_days': policy['max_age_days'],
                           'checks': statuses}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['template', 'evaluate'])
    parser.add_argument('snapshot', nargs='?', type=Path)
    parser.add_argument('--freshness-policy', type=Path,
                        help='Offline JSON policy: as_of, max_age_days, observed_on by question ID')
    args = parser.parse_args()
    try:
        if args.action == 'template':
            if args.snapshot is not None or args.freshness_policy is not None:
                raise ValueError()
            output = template()
        else:
            if args.snapshot is None:
                raise ValueError()
            snapshot = json.loads(args.snapshot.read_text())
            output = (evaluate_with_freshness(snapshot, json.loads(args.freshness_policy.read_text()))
                      if args.freshness_policy else evaluate(snapshot))
        print(json.dumps(output, indent=2))
    except (ValueError, OSError, TypeError, KeyError):
        print('Staff review unavailable: invalid or unreadable structured evidence.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
