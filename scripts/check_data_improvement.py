#!/usr/bin/env python3
"""Temporarily correct the optional fictional failures, prove score changes, restore."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from readiness_mcp import tool_call
from scratch_demo import ROOT, STATE, query, verify
from seed_failure_demo import COUNT, NAMES, PREFIX

RECOVERY = ROOT / '.local' / 'data-improvement-recovery.json'
REPORT = ROOT / '.local' / 'data-improvement-results.json'


def snapshot():
    result = tool_call('readiness_check', {'scenario': 'organization'})
    if result['metrics'] is None:
        raise RuntimeError('Organization measurements unavailable')
    return {'metrics': result['metrics'], 'score': result['data']['score']}


def patch_contacts(state, records):
    with tempfile.TemporaryDirectory(prefix='readiness-improvement-') as directory:
        path = Path(directory) / 'update.json'
        path.write_text(json.dumps({'allOrNone': True, 'records': records}))
        process = subprocess.run(['sf', 'api', 'request', 'rest', '/services/data/v67.0/composite/sobjects',
            '--target-org', state['alias'], '--method', 'PATCH', '--body', '@' + str(path)],
            cwd=ROOT, capture_output=True, text=True, timeout=120)
        try:
            rows = json.loads(process.stdout)
        except ValueError:
            raise RuntimeError('Atomic Contact update response unavailable') from None
        if process.returncode or not isinstance(rows, list) or len(rows) != len(records) or not all(row.get('success') is True for row in rows):
            raise RuntimeError('Atomic Contact update did not confirm success')


def originals(state):
    rows = query(state['alias'], "SELECT Id, LastName, Email, AccountId FROM Contact WHERE LastName LIKE '" + PREFIX + "%' LIMIT 61")
    if len(rows) != COUNT or {row.get('LastName') for row in rows} != NAMES:
        raise RuntimeError('Expected exactly the original sixty fictional failure contacts')
    records = []
    for row in sorted(rows, key=lambda value: value['LastName']):
        number = int(row['LastName'][-2:])
        expected = 'synthetic-failure-demo@example.invalid' if number <= 10 else None
        if row.get('Email') != expected or row.get('AccountId') is not None or not re.fullmatch(r'[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?', row.get('Id', '')):
            raise RuntimeError('Fictional failure contact drift detected; no records changed')
        records.append({'attributes': {'type': 'Contact'}, 'Id': row['Id'], 'Email': expected, 'AccountId': None})
    if len({row['Id'] for row in records}) != COUNT:
        raise RuntimeError('Ambiguous fictional Contact identifiers')
    return records


def restore(state, recovery):
    verify(state)
    if type(recovery) is not dict or set(recovery) != {'status', 'org_id', 'originals', 'baseline'} or recovery['status'] not in ('pending', 'restored'):
        raise RuntimeError('Invalid recovery schema')
    if recovery['org_id'] != state['org_id']:
        raise RuntimeError('Recovery belongs to another scratch org')
    current = query(state['alias'], "SELECT Id, LastName FROM Contact WHERE LastName LIKE '" + PREFIX + "%' LIMIT 61")
    if len(current) != COUNT or {row.get('LastName') for row in current} != NAMES:
        raise RuntimeError('Recovery no longer matches the sixty fictional contacts')
    expected = [{'attributes': {'type': 'Contact'}, 'Id': row['Id'],
                 'Email': 'synthetic-failure-demo@example.invalid' if int(row['LastName'][-2:]) <= 10 else None,
                 'AccountId': None} for row in sorted(current, key=lambda value: value['LastName'])]
    if recovery['originals'] != expected:
        raise RuntimeError('Recovery payload does not match original fictional values')
    patch_contacts(state, recovery['originals'])
    if snapshot() != recovery['baseline']:
        raise RuntimeError('Restored records but baseline measurements differ; review locally')
    recovery['status'] = 'restored'
    RECOVERY.write_text(json.dumps(recovery, indent=2) + '\n')


def run(state):
    verify(state)
    if RECOVERY.exists() and json.loads(RECOVERY.read_text()).get('status') != 'restored':
        raise RuntimeError('Unfinished recovery exists; run this script with --restore first')
    records = originals(state)
    accounts = query(state['alias'], "SELECT Id FROM Account WHERE Name = 'SYNTHETIC AI Readiness pilot' LIMIT 2")
    if len(accounts) != 1 or not re.fullmatch(r'[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?', accounts[0].get('Id', '')):
        raise RuntimeError('Expected exactly one original pilot Account')
    collisions = query(state['alias'], "SELECT COUNT(Id) n FROM Contact WHERE Email LIKE 'synthetic-improvement-demo-%@example.invalid'")
    if len(collisions) != 1 or collisions[0]['n'] != 0:
        raise RuntimeError('Reserved synthetic correction addresses already exist')
    baseline = snapshot()
    recovery = {'status': 'pending', 'org_id': state['org_id'], 'originals': records, 'baseline': baseline}
    RECOVERY.parent.mkdir(exist_ok=True)
    RECOVERY.write_text(json.dumps(recovery, indent=2) + '\n')
    RECOVERY.chmod(0o600)
    report = None
    try:
        updated = [{**row, 'Email': f'synthetic-improvement-demo-{index:02d}@example.invalid',
                    'AccountId': accounts[0]['Id']} for index, row in enumerate(records, 1)]
        patch_contacts(state, updated)
        improved = snapshot()
        expected = dict(baseline['metrics'])
        expected['email_present'] += 50
        expected['linked_contacts'] += 60
        expected['repeated_email_rows'] -= 9
        if improved['metrics'] != expected or float(improved['score']) <= float(baseline['score']):
            raise RuntimeError('Fresh measurements did not show the expected correction and score increase')
        report = {'source': 'live_synthetic_scratch', 'before': baseline, 'improved': improved, 'restored': True}
    finally:
        try:
            restore(state, recovery)
        except Exception:
            raise RuntimeError('RESTORATION NOT CONFIRMED. Recovery saved in .local/data-improvement-recovery.json; run python3 scripts/check_data_improvement.py --restore and verify before further demos.') from None
    REPORT.write_text(json.dumps(report, indent=2) + '\n')
    print(f"PASS: fictional corrections increased data score {baseline['score']}% to {improved['score']}%; original data restored.")
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--restore', action='store_true', help='Retry restoration from the saved local recovery file')
    args = parser.parse_args()
    try:
        state = json.loads(STATE.read_text())
        if args.restore:
            restore(state, json.loads(RECOVERY.read_text()))
            print('PASS: saved fictional records restored and baseline measurements confirmed.')
        else:
            run(state)
    except Exception as error:
        message = str(error) if isinstance(error, RuntimeError) else 'Improvement exercise unavailable; inspect local setup without exporting credentials.'
        print(message, file=sys.stderr)
        sys.exit(1)
