#!/usr/bin/env python3
"""Verify the deployed Agentforce-compatible action using fictional demo groups."""
import json
import subprocess

from demo import ROOT
from scratch_demo import STATE, SCENARIOS, verify
from privacy import build_data_result
from run_demo import exchange, payload
from mcp_connection import load_connection


def main():
    state = json.loads(STATE.read_text())
    verify(state)
    body = STATE.parent/'action-input.json'
    body.write_text(json.dumps({'inputs':[{'scenario':name} for name in SCENARIOS+['organization']]+[{'scenario':'reject-raw-email@example.invalid'}]}))
    p = subprocess.run(['sf','api','request','rest','/services/data/v67.0/actions/custom/apex/NonprofitAIReadiness',
                        '--method','POST','--body','@'+str(body),'--target-org',state['alias']],
                       cwd=ROOT,text=True,capture_output=True,timeout=180)
    if p.returncode:
        raise RuntimeError('Salesforce action invocation failed; inspect setup locally')
    results = json.loads(p.stdout)
    if len(results) != 7:
        raise RuntimeError('Unexpected Salesforce action response count')
    reports = {}
    for name,result in zip(SCENARIOS,results):
        if not result.get('isSuccess'):
            raise RuntimeError('Salesforce action returned an error')
        report=json.loads(result['outputValues']['output'])
        expected=json.loads((ROOT/'demo'/name/'expected.json').read_text())
        private=build_data_result(expected['metrics'])
        if (report['specification_version'] != private['specification_version']
                or report['profile_overrides'] != private['profile_overrides']
                or report['metrics'] != private['metrics'] or report['data']['score'] !=
                (float(private['data']['score']) if private['data']['score'] is not None else None)
                or [(item['key'],item['priority']) for item in report['priorities']] != [(item['key'],item['priority']) for item in private['priorities']]
                or report['privacy'] != private['privacy']
                or report['decision'] != 'readiness_not_established'):
            raise RuntimeError(f'{name}: Salesforce action differs from the shared check expectations')
        reports[name]=report
        score=report['data']['score']
        print(f'{name}: PASS — '+('withheld for privacy' if score is None else f'data score {score}%'))
    human_organization = json.loads(results[-2]['outputValues']['output'])
    mcp_state = load_connection()
    body.write_text(json.dumps({'inputs': [{'scenario': 'organization'}]}))
    dedicated = subprocess.run(['sf','api','request','rest','/services/data/v67.0/actions/custom/apex/ReadinessMCP',
        '--method','POST','--body','@'+str(body),'--target-org',mcp_state['alias']],
        cwd=ROOT,text=True,capture_output=True,timeout=180)
    if dedicated.returncode:
        raise RuntimeError('Dedicated native aggregate action unavailable')
    native_results = json.loads(dedicated.stdout)
    if len(native_results) != 1 or native_results[0].get('isSuccess') is not True:
        raise RuntimeError('Dedicated native aggregate action unavailable')
    organization = json.loads(native_results[0]['outputValues']['output'])
    connected = payload(exchange([('tools/call', {'name':'readiness_check','arguments':{'scenario':'organization'}})])[0])
    if (organization['specification_version'] != connected['specification_version']
            or organization['profile_overrides'] != connected['profile_overrides']
            or organization['metrics'] != connected['metrics']
            or organization['data']['checks'] != connected['data']['checks']
            or organization['decision'] != connected['decision']
            or [(item['key'],item['priority']) for item in organization['priorities']] != [(item['key'],item['priority']) for item in connected['priorities']]
            or organization['scope'] != 'sharing_scoped_organization_records'):
        raise RuntimeError('Dedicated native action and restricted connection do not agree')
    if 'staff_review' in organization or 'staff_review' in connected:
        raise RuntimeError('Dedicated MCP must not expose employee staff evidence')
    score = connected['data']['score']
    if organization['data']['score'] != (None if score is None else float(score)):
        raise RuntimeError('Organization scores differ between connection paths')
    reports['human_organization'] = human_organization
    reports['organization'] = organization
    print('organization: PASS — Dedicated native action and restricted connection agree')
    invalid=json.loads(results[-1]['outputValues']['output'])
    if invalid != {'error':'invalid_scenario'}:
        raise RuntimeError('Invalid-input denial failed')
    (STATE.parent/'salesforce-action-results.json').write_text(json.dumps(reports,indent=2)+'\n')
    print('PASS — fixed action inputs, summary-only output, and withheld small groups')


if __name__ == '__main__':
    main()
