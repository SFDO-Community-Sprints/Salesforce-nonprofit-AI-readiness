#!/usr/bin/env python3
"""Verify the deployed Agentforce-compatible action using fictional demo groups."""
import json
import subprocess

from demo import ROOT
from scratch_demo import STATE, SCENARIOS, verify
from privacy import build_data_result
from run_demo import exchange, payload


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
        if (report['metrics'] != private['metrics'] or report['data']['score'] !=
                (float(private['data']['score']) if private['data']['score'] is not None else None)
                or [(item['key'],item['priority']) for item in report['priorities']] != [(item['key'],item['priority']) for item in private['priorities']]
                or report['privacy'] != private['privacy']
                or report['decision'] != 'readiness_not_established'):
            raise RuntimeError(f'{name}: Salesforce action differs from the shared check expectations')
        reports[name]=report
        score=report['data']['score']
        print(f'{name}: PASS — '+('withheld for privacy' if score is None else f'data score {score}%'))
    organization = json.loads(results[-2]['outputValues']['output'])
    connected = payload(exchange([('tools/call', {'name':'readiness_check','arguments':{'scenario':'organization'}})])[0])
    if (organization['metrics'] != connected['metrics']
            or organization['data']['checks'] != connected['data']['checks']
            or [(item['key'],item['priority']) for item in organization['priorities']] != [(item['key'],item['priority']) for item in connected['priorities']]
            or organization['scope'] != 'accessible_organization_records'):
        raise RuntimeError('Salesforce screen/action and restricted connection do not agree')
    score = connected['data']['score']
    if organization['data']['score'] != (None if score is None else float(score)):
        raise RuntimeError('Organization scores differ between connection paths')
    reports['organization'] = organization
    print('organization: PASS — Salesforce screen/action and restricted connection agree')
    invalid=json.loads(results[-1]['outputValues']['output'])
    if invalid != {'error':'invalid_scenario'}:
        raise RuntimeError('Invalid-input denial failed')
    (STATE.parent/'salesforce-action-results.json').write_text(json.dumps(reports,indent=2)+'\n')
    print('PASS — fixed action inputs, summary-only output, and withheld small groups')


if __name__ == '__main__':
    main()
