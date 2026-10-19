#!/usr/bin/env python3
"""Run offline demonstrations, optionally verifying the live MCP privacy boundary."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from demo import ROOT, evaluate, self_test


def exchange(requests, synthetic=False):
    env = os.environ.copy()
    env.pop('READINESS_SYNTHETIC_DEMO', None)
    if synthetic:
        env['READINESS_SYNTHETIC_DEMO'] = '1'
    messages = [dict(jsonrpc='2.0', id=1, method='initialize', params={
        'protocolVersion':'2025-11-25', 'capabilities':{}, 'clientInfo':{'name':'readiness-demo','version':'1.0'}}),
        dict(jsonrpc='2.0', method='notifications/initialized')]
    messages += [dict(jsonrpc='2.0',id=i+2,method=method,params=params) for i,(method,params) in enumerate(requests)]
    result = subprocess.run([sys.executable,str(ROOT/'scripts/readiness_mcp.py')],
        input=''.join(json.dumps(m)+'\n' for m in messages),text=True,capture_output=True,env=env,timeout=300)
    if result.returncode or result.stderr:
        raise RuntimeError('MCP subprocess failed or emitted unexpected stderr; inspect locally without forwarding raw logs')
    replies = [json.loads(line) for line in result.stdout.splitlines()]
    if len(replies) != len(requests)+1 or 'error' in replies[0]:
        raise RuntimeError('MCP initialization or response count failed')
    for reply, request in zip(replies, [messages[0]]+messages[2:]):
        if reply.get('id') != request['id'] or reply.get('jsonrpc') != '2.0':
            raise RuntimeError('MCP response identity mismatch')
    return replies[1:]


def payload(reply):
    if 'error' in reply or reply.get('result',{}).get('isError'):
        raise RuntimeError('Expected successful MCP tool response')
    result = reply['result']
    return result.get('structuredContent') or json.loads(result['content'][0]['text'])


def main(live):
    self_test()
    comparisons = {}
    for name in ['poor','improving','pilot','blocked','unknown']:
        fixture = json.loads((ROOT/'demo'/name/'fixture.json').read_text())
        report = evaluate(fixture)
        comparisons[name] = report
        print(f'{name}: data {report["data"]["score"]}%, technical {report["technical"]["score"]}%, '
              f'staff {report["staff"]["score"]}% — {report["decision"]} [SIMULATED controls/staff]')
    if not live:
        print('Offline demo complete. Add --live to exercise the scratch-bound MCP.')
        return
    # Test denial without depending on a live Salesforce query.
    sentinel='SENSITIVE_SENTINEL_fake-donor@example.invalid'
    denial=exchange([('tools/call',{'name':'export_records','arguments':{'query':sentinel}}),
                     ('tools/call',{'name':'readiness_check','arguments':{'scenario':'poor','raw':sentinel}})])
    for reply in denial:
        if not ('error' in reply or reply.get('result',{}).get('isError')) or sentinel in json.dumps(reply):
            raise RuntimeError('Raw-data request denial failed')
    print('MCP: forbidden export and extra raw-data arguments rejected without echoing sentinels')
    suppressed=payload(exchange([('tools/call',{'name':'readiness_check','arguments':{'scenario':'poor'}})])[0])
    if (suppressed['metrics'] is not None or suppressed['data']['score'] is not None
            or suppressed['privacy']['suppressed'] is not True):
        raise RuntimeError('Small-cohort suppression failed')
    print('MCP: default small-cohort suppression verified')
    requests=[('tools/call',{'name':'readiness_check','arguments':{'scenario':name}}) for name in comparisons]
    replies=exchange(requests, synthetic=True)
    reports={}
    for name,reply in zip(comparisons,replies):
        report=payload(reply)
        # The live result must include aggregates and share the deterministic data score.
        if (comparisons[name]['data'] != report['data']
                or comparisons[name]['metrics'] != report['metrics']
                or report['decision'] != 'readiness_not_established'):
            raise RuntimeError(f'{name}: expected live score not returned')
        reports[name]=report
        print(f'MCP {name}: live data score agrees; live staff/control readiness remains unknown')
    path=ROOT/'.local/mcp-demo-results.json'
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps({'offline_simulation':comparisons,'live_mcp':reports,
                               'privacy_checks':'export denial, argument denial, small-cohort suppression passed'},indent=2)+'\n')
    print(f'PASS — sanitized demonstration report: {path}')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live',action='store_true',help='Query the saved verified demo scratch org through MCP')
    args=parser.parse_args()
    try:
        main(args.live)
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)
