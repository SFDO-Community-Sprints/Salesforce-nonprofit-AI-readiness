#!/usr/bin/env python3
"""Add optional fictional data failures to the saved disposable scratch org."""
import json
import sys
import tempfile
from pathlib import Path

from scratch_demo import STATE, query, sf, verify

PREFIX = 'SYNTHETIC AI Failure Demo '
COUNT = 60
NAMES = {f'{PREFIX}{number:02d}' for number in range(1, COUNT + 1)}


def seed(state):
    verify(state)
    rows = query(state['alias'], "SELECT LastName FROM Contact WHERE LastName LIKE '" + PREFIX + "%' LIMIT 61")
    if rows:
        if len(rows) != COUNT or {row.get('LastName') for row in rows} != NAMES:
            raise RuntimeError('Optional failure seed is incomplete or ambiguous; no records changed')
        print('Optional failure demo already present; no records changed.')
        return
    records = []
    for number in range(1, COUNT + 1):
        row = {'attributes': {'type': 'Contact', 'referenceId': f'FailureContact{number}'},
               'LastName': f'{PREFIX}{number:02d}'}
        if number <= 10:
            row['Email'] = 'synthetic-failure-demo@example.invalid'
        # No AccountId deliberately demonstrates missing account relationships.
        records.append(row)
    with tempfile.TemporaryDirectory(prefix='readiness-failure-demo-') as directory:
        path = Path(directory) / 'contacts.json'
        path.write_text(json.dumps({'records': records}))
        sf('data', 'import', 'tree', '--target-org', state['alias'], '--files', str(path))
    print('Added 60 fictional contacts: all unlinked, 50 missing emails, 10 sharing one fictional email.')
    print('Organization-wide data scores intentionally decrease; the original five demo groups are unchanged.')


if __name__ == '__main__':
    try:
        seed(json.loads(STATE.read_text()))
    except Exception:
        print('Failure demo seed unavailable or incomplete; inspect local scratch setup. No reset was attempted.', file=sys.stderr)
        sys.exit(1)
