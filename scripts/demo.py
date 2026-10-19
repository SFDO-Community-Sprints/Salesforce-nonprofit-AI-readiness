#!/usr/bin/env python3
"""Generate synthetic fixtures and replay a deliberately small demo rubric."""
import argparse
import json
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def validate_profile(profile):
    """Validate the fixed MVP profile before using its thresholds or gates."""
    try:
        categories = profile['categories']
        assert set(categories) == {'data', 'technical', 'staff'}
        checks = [key for category in categories.values() for key in category['checks']]
        assert len(checks) == len(set(checks)) and all(isinstance(key, str) and key for key in checks)
        assert profile['version'] == 'donor-summary-demo-v1'
        assert set(profile['critical_gates']) <= set(checks)
        thresholds = profile['thresholds']
        assert set(thresholds) == {'minimum_contacts','email_completeness_pass_percent','account_linkage_pass_percent',
            'maximum_repeated_email_rows','minimum_privacy_cohort','email_high_below_percent',
            'duplicate_high_at_least_percent','unlinked_high_above_percent'}
        assert all(type(value) is int and value >= 0 for value in thresholds.values())
        assert all(value <= 100 for key, value in thresholds.items() if key.endswith('_percent'))
        assert 0 < thresholds['minimum_privacy_cohort'] <= thresholds['minimum_contacts']
        assert thresholds['email_high_below_percent'] <= thresholds['email_completeness_pass_percent']
        assert profile['priority']['order'] == ['Critical','High','Medium','Low']
        assert set(profile['scoring']['statuses']) == {'pass','fail','unknown','not_applicable'}
    except (KeyError, TypeError, AssertionError, AttributeError):
        raise ValueError('Invalid readiness profile') from None
    return profile


PROFILE = validate_profile(json.loads((ROOT / 'demo' / 'rubric.json').read_text()))
VERSION = PROFILE['version']
SPECIFICATION_VERSION = json.loads((ROOT / 'references/check-specifications.json').read_text())['version']
THRESHOLDS = PROFILE['thresholds']
TECH = PROFILE['categories']['technical']['checks']
STAFF = PROFILE['categories']['staff']['checks']
CRITICAL = set(PROFILE['critical_gates'])


def percentage(numerator, denominator):
    if not denominator:
        return None
    return str((Decimal(numerator) * 100 / Decimal(denominator)).quantize(Decimal('.1'), rounding=ROUND_HALF_UP))


def summarize(checks):
    assert all(x in PROFILE['scoring']['statuses'] for x in checks.values())
    applicable = sum(x != 'not_applicable' for x in checks.values())
    passed = list(checks.values()).count('pass')
    completed = sum(x in {'pass', 'fail'} for x in checks.values())
    return {'checks': checks, 'passed': passed, 'applicable': applicable,
            'score': percentage(passed, applicable), 'coverage': percentage(completed, applicable)}


def data_checks(metrics):
    n = metrics["contacts"]
    populated = metrics["email_present"]
    linked = metrics["linked_contacts"]
    checks = {k: 'unknown' for k in PROFILE['categories']['data']['checks']}
    if n:
        checks = {'sufficient_data': 'pass' if n >= THRESHOLDS['minimum_contacts'] else 'fail',
                  'email_completeness': 'pass' if populated * 100 >= n * THRESHOLDS['email_completeness_pass_percent'] else 'fail',
                  'account_linkage': 'pass' if linked * 100 >= n * THRESHOLDS['account_linkage_pass_percent'] else 'fail',
                  'duplicate_indicator': 'pass' if metrics['repeated_email_rows'] <= THRESHOLDS['maximum_repeated_email_rows'] else 'fail'}
    return checks


def recommendations(metrics, technical=None, staff=None, erasure_unknown=True):
    """Fixed priorities from aggregate measurements and explicit control evidence."""
    items = []
    def add(key, priority, impact, recommendation):
        items.append({'key': key, 'priority': priority, 'impact': impact, 'recommendation': recommendation})
    technical = technical or dict.fromkeys(TECH, 'unknown')
    staff = staff or dict.fromkeys(STAFF, 'unknown')
    if any(technical.get(key) == 'fail' for key in TECH if key in CRITICAL):
        add('controls', 'Critical', 'A tested safeguard failed and can permit unauthorized or consequential actions.',
            'Fix the failed safeguard and repeat the test before enabling the agent.')
    elif any(technical.get(key, 'unknown') != 'pass' for key in TECH):
        add('controls', 'High', 'Required safeguards have not all been verified.',
            'Test access restrictions, approvals, export blocking, and the stop control.')
    if erasure_unknown:
        add('privacy', 'High', 'Sensitive-data handling and erasure have not been verified end to end.',
            'Verify masking, permitted data, retention, and erasure across agent responses and logs.')
    if any(staff.get(key) == 'fail' for key in STAFF if key in CRITICAL):
        add('staff', 'Critical', 'A demonstrated staff knowledge gap can bypass an essential safeguard.',
            'Train the affected staff and repeat the relevant guardrail exercises before access is enabled.')
    elif any(staff.get(key, 'unknown') != 'pass' for key in STAFF):
        add('staff', 'Medium', 'Staff readiness is incomplete or has not been demonstrated.',
            'Complete the seven staff readiness questions and observed safety exercises.')
    if metrics is not None and metrics['contacts']:
        n = metrics['contacts']
        if metrics['email_present'] * 100 < n * THRESHOLDS['email_completeness_pass_percent']:
            add('email_completeness', 'High' if metrics['email_present'] * 100 < n * THRESHOLDS['email_high_below_percent'] else 'Medium',
                'Missing email data can make donor summaries and outreach incomplete.',
                'Review missing email values using approved sources before using this data for outreach.')
        if metrics['repeated_email_rows'] > THRESHOLDS['maximum_repeated_email_rows']:
            add('duplicate_indicator', 'High' if metrics['repeated_email_rows'] * 100 >= n * THRESHOLDS['duplicate_high_at_least_percent'] else 'Medium',
                'Repeated email values can cause duplicate outreach or misleading donor summaries.',
                'Review repeated email values and confirm the intended donor records without automatically merging them.')
        if metrics['linked_contacts'] * 100 < n * THRESHOLDS['account_linkage_pass_percent']:
            add('account_linkage', 'High' if (n - metrics['linked_contacts']) * 100 > n * THRESHOLDS['unlinked_high_above_percent'] else 'Medium',
                'Missing account links can omit donor context or associate work with the wrong organization.',
                'Review contacts without an account and correct links where the relationship is known.')
        if n < THRESHOLDS['minimum_contacts']:
            add('sufficient_data', 'Low', 'The sample is too small to demonstrate reliable data readiness.',
                'Repeat the check with a sufficiently representative permitted sample.')
    rank = {priority: index for index, priority in enumerate(PROFILE['priority']['order'])}
    return sorted(items, key=lambda item: rank[item['priority']])


def evaluate(fixture):
    assert fixture['rubric_version'] == VERSION
    contacts = fixture['salesforce_tree']['records'][0]['Contacts']['records']
    n = len(contacts)
    emails = [c.get('Email', '').strip().lower() for c in contacts if c.get('Email')]
    linked = sum(bool(c.get('AccountId') or fixture['salesforce_tree']['records'][0].get('Name')) for c in contacts)
    # Contacts are nested under their parent Account, so the import establishes linkage.
    metrics = {'contacts': n, 'email_present': len(emails), 'linked_contacts': linked,
               'repeated_email_rows': len(emails) - len(set(emails))}
    checks = data_checks(metrics)
    evidence = fixture['simulated_evidence']
    tech = {k: evidence['technical'][k]['status'] for k in TECH}
    staff = {k: evidence['staff'][k]['status'] for k in STAFF}
    combined = {**checks, **tech, **staff}
    if any(combined[k] == 'fail' for k in CRITICAL):
        decision = 'not_ready'
    elif any(v == 'unknown' for v in combined.values()):
        decision = 'readiness_not_established'
    elif any(v == 'fail' for v in combined.values()):
        decision = 'not_ready'
    else:
        decision = 'ready_for_bounded_pilot_simulation'
    return {'rubric_version': VERSION, 'evidence_mode': 'synthetic_simulation', 'metrics': metrics,
            'data': summarize(checks), 'technical': summarize(tech), 'staff': summarize(staff), 'decision': decision,
            'priorities': recommendations(metrics, tech, staff)}


def fixture(name, count, populated, duplicate, tech_status, staff_status):
    contacts = []
    for i in range(count):
        c = {'attributes': {'type': 'Contact', 'referenceId': f'Contact{i+1}'},
             'LastName': f'SYNTHETIC {name} Donor {i+1}'}
        if i < populated:
            c['Email'] = f'{name}-donor-{0 if duplicate and i < 2 else i}@example.invalid'
        contacts.append(c)
    def evidence(keys, statuses):
        return {k: {'status': s, 'source': 'SIMULATED demo evidence; no actual control test or staff assessment'}
                for k, s in zip(keys, statuses)}
    return {'name': name, 'rubric_version': VERSION, 'as_of': '2026-10-19T00:00:00Z',
            'salesforce_tree': {'records': [{'attributes': {'type': 'Account', 'referenceId': 'DemoAccount'},
                'Name': f'SYNTHETIC AI Readiness {name}', 'Contacts': {'records': contacts}}]},
            'simulated_evidence': {'technical': evidence(TECH, tech_status), 'staff': evidence(STAFF, staff_status)}}


def generate():
    cases = [
        fixture('poor', 4, 1, False, ['pass','unknown','fail','fail','unknown'], ['pass']+['fail']*6),
        fixture('improving', 10, 8, True, ['pass','pass','pass','unknown','unknown'], ['pass']*5+['unknown']*2),
        fixture('pilot', 10, 10, False, ['pass']*5, ['pass']*7),
        fixture('blocked', 10, 10, False, ['pass','pass','pass','fail','pass'], ['pass']*7),
        fixture('unknown', 0, 0, False, ['unknown']*5, ['unknown']*7),
    ]
    for f in cases:
        directory = ROOT / 'demo' / f['name']
        directory.mkdir(parents=True, exist_ok=True)
        for filename, value in [('fixture.json', f), ('salesforce-tree.json', f['salesforce_tree']),
                                ('expected.json', evaluate(f))]:
            (directory / filename).write_text(json.dumps(value, indent=2)+'\n')


def self_test():
    # Independent expected scores protect the demonstration against scorer drift.
    expected = {'poor': ('50.0','20.0','14.3','not_ready'),
                'improving': ('50.0','60.0','71.4','readiness_not_established'),
                'pilot': ('100.0','100.0','100.0','ready_for_bounded_pilot_simulation'),
                'blocked': ('100.0','80.0','100.0','not_ready'),
                'unknown': ('0.0','0.0','0.0','readiness_not_established')}
    for name, scores in expected.items():
        directory = ROOT / 'demo' / name
        f = json.loads((directory/'fixture.json').read_text())
        actual = evaluate(f)
        assert actual == json.loads((directory/'expected.json').read_text()), name
        assert tuple(actual[k]['score'] for k in ['data','technical','staff'])+(actual['decision'],) == scores, name
        assert evaluate(json.loads(json.dumps(f))) == actual
    assert summarize({'a':'not_applicable'})['score'] is None
    assert summarize({'a':'pass','b':'unknown'})['coverage'] == '50.0'
    assert percentage(1, 16) == '6.3'
    f = fixture('boundary', 10, 9, False, ['pass']*5, ['pass']*7)
    assert evaluate(f)['data']['checks']['email_completeness'] == 'pass'
    f['salesforce_tree']['records'][0]['Contacts']['records'][8].pop('Email')
    assert evaluate(f)['data']['checks']['email_completeness'] == 'fail'
    blocked = evaluate(fixture('blocked', 10, 10, False, ['pass','pass','pass','fail','pass'], ['pass']*7))
    assert blocked['priorities'][0]['priority'] == 'Critical'
    assert not any(item['priority'] == 'Critical' for item in recommendations(None))
    assert [x['key'] for x in recommendations(None)] == ['controls', 'privacy', 'staff']
    def priority_for(key, populated=9, repeated=0, linked=10):
        rows = recommendations({'contacts': 10, 'email_present': populated, 'linked_contacts': linked, 'repeated_email_rows': repeated})
        return next(item['priority'] for item in rows if item['key'] == key)
    assert priority_for('email_completeness', populated=4) == 'High'
    assert priority_for('email_completeness', populated=5) == 'Medium'
    assert priority_for('duplicate_indicator', repeated=1) == 'High'
    assert priority_for('account_linkage', linked=8) == 'Medium'
    assert priority_for('account_linkage', linked=7) == 'High'
    assert all(item['priority'] in {'Critical','High','Medium','Low'} for item in blocked['priorities'])
    print('PASS: five scenarios, replay, empty data, unknown coverage, N/A, rounding, and threshold boundary')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['generate', 'test', 'score'])
    parser.add_argument('fixture', nargs='?', type=Path)
    args = parser.parse_args()
    if args.action == 'generate':
        generate()
    elif args.action == 'test':
        self_test()
    else:
        if not args.fixture:
            parser.error('score requires a fixture.json path')
        print(json.dumps(evaluate(json.loads(args.fixture.read_text())), indent=2))
