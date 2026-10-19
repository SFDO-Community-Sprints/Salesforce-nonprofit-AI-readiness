#!/usr/bin/env python3
"""Create, seed, and check a dedicated Nonprofit Cloud demo scratch org."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys

from demo import ROOT, VERSION, data_checks, summarize

STATE = ROOT / '.local' / 'scratch.json'
SCENARIOS = ['poor', 'improving', 'pilot', 'blocked', 'unknown']


def sf(*args):
    p = subprocess.run(['sf', *args, '--json'], cwd=ROOT, capture_output=True, text=True, timeout=600)
    try:
        d = json.loads(p.stdout)
    except ValueError:
        raise RuntimeError('Salesforce CLI returned non-JSON output; check CLI installation/authentication') from None
    if p.returncode or d.get('status'):
        # Avoid echoing arbitrary CLI output that may include credentials.
        raise RuntimeError(f'Salesforce command failed ({d.get("name", "unknown error")}); inspect locally with credential redaction')
    return d['result']


def query(alias, soql):
    return sf('data', 'query', '--target-org', alias, '--query', soql)['records']


def verify(state):
    org = query(state['alias'], 'SELECT Id, Name, IsSandbox FROM Organization')[0]
    if org['Id'] != state['org_id'] or not org['IsSandbox']:
        raise RuntimeError('Target does not match the saved disposable scratch org')
    records = query(state['hub'], "SELECT ScratchOrg, Status, ExpirationDate FROM ScratchOrgInfo WHERE ScratchOrg = '"+org['Id'][:15]+"'")
    if len(records) != 1 or records[0]['Status'] != 'Active':
        raise RuntimeError('Dev Hub cannot confirm this is an active scratch org')
    return org


def create(hub, alias):
    if STATE.exists():
        raise RuntimeError('Saved org already exists; use seed/test, or delete it explicitly before creating another')
    # No default org/Dev Hub is changed. CLI rejects an already-used alias here.
    existing = sf('alias', 'list')
    if any(row.get('alias') == alias for row in existing):
        raise RuntimeError('Alias already exists; choose a new alias')
    result = sf('org', 'create', 'scratch', '--definition-file', str(ROOT/'references/nonprofit-scratch-def.json'),
                '--target-dev-hub', hub, '--alias', alias, '--duration-days', '7', '--wait', '5')
    state = {'alias': alias, 'hub': hub, 'org_id': result['orgId'], 'created_at': datetime.now(timezone.utc).isoformat()}
    STATE.parent.mkdir(exist_ok=True)
    STATE.write_text(json.dumps(state, indent=2)+'\n')
    verify(state)
    print(f'Created {alias} ({state["org_id"]}); state saved under .local/')


def seed(state):
    verify(state)
    for name in SCENARIOS:
        account_name = 'SYNTHETIC AI Readiness '+name
        accounts = query(state['alias'], "SELECT Id FROM Account WHERE Name = '"+account_name+"'")
        if accounts:
            if len(accounts) != 1:
                raise RuntimeError('Multiple demo accounts found; refusing to import more')
            print(f'{name}: account already present; skipping import (test will verify its data)')
            continue
        # The unknown scenario needs an empty Account, not an empty child relationship import.
        if name == 'unknown':
            sf('data','create','record','--target-org',state['alias'],'--sobject','Account','--values',f"Name='{account_name}'")
        else:
            sf('data','import','tree','--target-org',state['alias'],'--files',str(ROOT/'demo'/name/'salesforce-tree.json'))
        print(f'{name}: seeded')


def deploy(state):
    verify(state)
    result = sf('project', 'deploy', 'start', '--source-dir', str(ROOT/'metadata'),
                '--target-org', state['alias'], '--test-level', 'RunSpecifiedTests',
                '--tests', 'NonprofitAIReadinessTest', '--tests', 'ReadinessStaffReviewTest',
                '--tests', 'ReadinessMCPTest', '--wait', '5')
    if not result.get('success'):
        raise RuntimeError('Salesforce app deployment did not pass')
    username = sf('org', 'display', '--target-org', state['alias'])['username']
    escaped = username.replace("\\", "\\\\").replace("'", "\\'")
    assigned = query(state['alias'], "SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Readiness_Assessor' AND Assignee.Username = '" + escaped + "'")
    if not assigned:
        sf('org', 'assign', 'permset', '--name', 'Readiness_Assessor', '--target-org', state['alias'])
    tests = result.get('details', {}).get('runTestResult', {})
    print(f"Salesforce app installed; {tests.get('numTestsRun', 0)} action tests passed. Readiness Assessor assigned to the signed-in test user.")


def test(state):
    org = verify(state)
    described = sf('sobject','describe','--target-org',state['alias'],'--sobject','GiftTransaction')
    if not described['queryable']:
        raise RuntimeError('GiftTransaction is not queryable; nonprofit setup is incomplete')
    report = {'rubric_version': VERSION, 'org_id': org['Id'], 'collected_at': datetime.now(timezone.utc).isoformat(),
              'scope': 'synthetic Account cohorts only', 'nonprofit_object': described['name'], 'scenarios': {}}
    for name in SCENARIOS:
        accounts = query(state['alias'], "SELECT Id FROM Account WHERE Name = 'SYNTHETIC AI Readiness "+name+"'")
        if len(accounts) != 1:
            raise RuntimeError(f'{name}: expected exactly one seeded Account')
        rows = query(state['alias'], "SELECT Email, AccountId FROM Contact WHERE AccountId = '"+accounts[0]['Id']+"'")
        emails = [r['Email'].strip().lower() for r in rows if r.get('Email')]
        metrics = {'contacts':len(rows), 'email_present':len(emails), 'linked_contacts':sum(bool(r.get('AccountId')) for r in rows),
                   'repeated_email_rows':len(emails)-len(set(emails))}
        actual = summarize(data_checks(metrics))
        expected = json.loads((ROOT/'demo'/name/'expected.json').read_text())
        if metrics != expected['metrics'] or actual != expected['data']:
            raise RuntimeError(f'{name}: live measurements differ from expected fixture; no pass reported')
        # Never merge simulated passing controls into this live conclusion.
        report['scenarios'][name] = {'live_metrics':metrics, 'live_data':actual,
            'live_technical_and_staff':'unknown; not exercised', 'live_decision':'readiness_not_established',
            'simulated_comparison':{k:expected[k] for k in ['technical','staff','decision']}}
        print(f'{name}: PASS — live data score {actual["score"]}%, coverage {actual["coverage"]}%')
    path = STATE.parent/'live-results.json'
    path.write_text(json.dumps(report,indent=2)+'\n')
    print(f'Sanitized aggregate report: {path}')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=['create','seed','deploy','test'])
    p.add_argument('--hub')
    p.add_argument('--alias',default='nonprofit-readiness-demo')
    a=p.parse_args()
    try:
        if a.action == 'create':
            if not a.hub:
                p.error('create requires --hub')
            create(a.hub,a.alias)
        else:
            if not STATE.exists():
                raise RuntimeError('No saved demo scratch org; run create first')
            state=json.loads(STATE.read_text())
            {'seed':seed, 'deploy':deploy, 'test':test}[a.action](state)
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)
