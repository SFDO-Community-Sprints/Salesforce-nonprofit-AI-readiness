#!/usr/bin/env python3
"""Exercise the published agent's fixed native invocable with fictional demo prompts."""
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from check_agentforce_preview import PROMPTS, check_response, seeded_values
from demo import ROOT
from scratch_demo import verify

STATE = ROOT / '.local' / 'agentforce-scratch.json'
OUTPUT = ROOT / '.local' / 'agentforce-action-results.json'
URL = '/services/data/v67.0/actions/custom/generateAiAgentResponse/Nonprofit_Readiness'


def invoke(alias, prompt):
    body_path = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as body:
            body_path = Path(body.name)
            json.dump({'inputs': [{'userMessage': prompt}]}, body)
        process = subprocess.run(['sf', 'api', 'request', 'rest', URL, '--target-org', alias,
                                  '--method', 'POST', '--header', 'Content-Type:application/json',
                                  '--body', '@' + str(body_path)], cwd=ROOT / 'agentforce',
                                 capture_output=True, text=True, timeout=300)
        if process.returncode:
            raise ValueError()
        return parse_response(json.loads(process.stdout))
    except Exception:
        raise RuntimeError('Published agent request unavailable') from None
    finally:
        if body_path:
            body_path.unlink(missing_ok=True)


def parse_response(value):
    invalid = ValueError('Published agent response unavailable')
    if type(value) is not list or len(value) != 1 or type(value[0]) is not dict:
        raise invalid
    result = value[0]
    if (result.get('actionName') != 'Nonprofit_Readiness' or result.get('isSuccess') is not True
            or result.get('errors') or type(result.get('outputValues')) is not dict):
        raise invalid
    values = result['outputValues']
    try:
        content = json.loads(values['agentResponse'])
    except (ValueError, TypeError, KeyError):
        raise invalid from None
    if (type(content) is not dict or content.get('type') != 'Text'
            or type(content.get('value')) is not str or not content['value'].strip()
            or type(values.get('sessionId')) is not str or not values['sessionId']):
        raise invalid
    return {'response': content['value'], 'session_id': values['sessionId']}


def response_checks(text, sentinels):
    checks = check_response(text, sentinels)
    checks['expected_check_summary'] = bool(re.search(r'1\s+(?:of|/)\s*4', text)
                                           and re.search(r'4\s+(?:of|/)\s*4', text)
                                           and re.search(r'\b100(?:\.0)?\s*%', text))
    return checks


def run(state, execute=invoke, validate=verify, output=OUTPUT):
    report = {'mode': 'published_native_invocable', 'decision': 'requires_manual_review',
              'action_trace_verified': False,
              'limitation': 'Native invocable responses have no action trace. Refusals require manual review; '
                            'separate live authoring traces verify the fixed assessment binding.', 'cases': []}
    try:
        validate(state)
        sentinels = seeded_values()
        for name, prompt in PROMPTS:
            result = execute(state['alias'], prompt)
            text = result['response']
            checks = response_checks(text, sentinels)
            status = 'requires_manual_review'
            if name == 'assessment':
                status = 'pass' if all(checks.values()) else 'fail'
            if not checks['seeded_personal_values_absent']:
                status = 'fail'
            report['cases'].append({'name': name, **result, 'checks': checks, 'status': status})
            if status == 'fail':
                report['decision'] = 'fail'
    except Exception:
        report['error'] = 'Published agent check unavailable; inspect local setup without sharing credentials.'
        report['decision'] = 'fail'
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + '\n')
    return report


if __name__ == '__main__':
    try:
        result = run(json.loads(STATE.read_text()))
    except Exception:
        print('Published agent check unavailable; verify saved scratch-org setup.', file=sys.stderr)
        sys.exit(1)
    print('Published agent responses saved under .local/; refusal responses require manual review.')
    sys.exit(1 if result['decision'] == 'fail' else 0)
