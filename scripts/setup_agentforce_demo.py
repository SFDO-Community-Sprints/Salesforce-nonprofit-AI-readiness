#!/usr/bin/env python3
"""Prepare the reviewed employee readiness agent in a separate fictional scratch org."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import sys

from check_agentforce_preview import command
from demo import ROOT
from scratch_demo import deploy, seed, sf, verify
from seed_failure_demo import seed as seed_failures

STATE = ROOT / '.local/agentforce-scratch.json'
ALIAS = 'nonprofit-readiness-agent-test'
DEFINITION = ROOT / 'references/nonprofit-agentforce-scratch-def.json'
AUTHORING = ROOT / 'agentforce/main/default/aiAuthoringBundles/Nonprofit_Readiness/Nonprofit_Readiness.agent'


def validate_state(state):
    if (type(state) is not dict or state.get('alias') != ALIAS
            or type(state.get('hub')) is not str or not re.fullmatch(r'[A-Za-z0-9_@.+-]{1,150}',state['hub'])
            or type(state.get('org_id')) is not str or not re.fullmatch(r'00D[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?',state['org_id'])):
        raise RuntimeError('Saved Agentforce scratch identity is invalid')


def require_success(result):
    if type(result) is not dict or result.get('success') is not True:
        raise RuntimeError('Agentforce operation did not confirm success')


def setup(hub=None, state_path=STATE):
    if not AUTHORING.is_file() or not DEFINITION.is_file():
        raise RuntimeError('Reviewed agent source or scratch definition is missing')
    if state_path.exists():
        state = json.loads(state_path.read_text())
        validate_state(state)
        if hub is not None and hub != state['hub']:
            raise RuntimeError('Dev Hub does not match the saved scratch identity')
    else:
        if type(hub) is not str or not re.fullmatch(r'[A-Za-z0-9_@.+-]{1,150}',hub):
            raise RuntimeError('Initial setup requires --hub')
        aliases = sf('alias','list')
        if type(aliases) is not list or any(type(row) is not dict for row in aliases):
            raise RuntimeError('Cannot validate existing aliases')
        if any(row.get('alias') == ALIAS for row in aliases):
            raise RuntimeError('Agentforce alias exists without saved provenance; no changes made')
        created = sf('org','create','scratch','--definition-file',str(DEFINITION),
                     '--target-dev-hub',hub,'--alias',ALIAS,'--duration-days','7','--wait','5')
        state = {'alias':ALIAS,'hub':hub,'org_id':created.get('orgId') if type(created) is dict else None,
                 'created_at':datetime.now(timezone.utc).isoformat()}
        validate_state(state)
        state_path.parent.mkdir(exist_ok=True)
        # Preserve provenance for recovery; never replace an existing saved target.
        with state_path.open('x') as saved:
            saved.write(json.dumps(state,indent=2)+'\n')
    verify(state)
    print('Verified the separate disposable Agentforce scratch environment.')
    seed(state)
    seed_failures(state)
    deploy(state)
    print('Fictional records and the read-only readiness app are prepared.')
    target = ('--target-org',ALIAS,'--api-version','67.0')
    require_success(command('agent','validate','authoring-bundle','--api-name','Nonprofit_Readiness',*target))
    print('Reviewed readiness Agent Script validated.')
    require_success(command('agent','publish','authoring-bundle','--api-name','Nonprofit_Readiness',
                            '--skip-retrieve',*target))
    print('Published the reviewed employee agent; reruns create a new version.')
    require_success(command('agent','activate','--api-name','Nonprofit_Readiness',*target))
    print('Readiness agent activated. Run the published-agent checks next; activation alone is not a readiness pass.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--hub',help='Authenticated Dev Hub alias; required only for initial scratch creation')
    args = parser.parse_args()
    try:
        setup(args.hub)
    except Exception:
        print('Agentforce setup incomplete. Check saved provenance, source and local CLI access; no defaults were changed.',file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
