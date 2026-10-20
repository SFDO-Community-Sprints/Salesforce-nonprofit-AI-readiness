#!/usr/bin/env python3
"""Run the complete automated MVP checks; --live includes the prepared scratch org."""
import argparse
import json
import subprocess
import sys
from demo import ROOT
from scratch_demo import STATE, sf, verify
from run_demo import exchange, payload


def run(*arguments):
    subprocess.run([sys.executable,*arguments],cwd=ROOT,check=True)


def main(live, agentforce=False):
    run('-m','unittest','discover','-s','scripts','-p','test_*.py')
    run('scripts/demo.py','test')
    run('scripts/demo_failures.py')
    subprocess.run(['node',str(ROOT/'scripts/check_screen_priorities.cjs')],cwd=ROOT,check=True)
    subprocess.run(['node',str(ROOT/'scripts/check_staff_form.cjs')],cwd=ROOT,check=True)
    subprocess.run(['node',str(ROOT/'scripts/check_staff_refresh.cjs')],cwd=ROOT,check=True)
    subprocess.run(['node',str(ROOT/'scripts/test_native_evidence_ui.cjs')],cwd=ROOT,check=True)
    subprocess.run(['node',str(ROOT/'scripts/test_demo_scenarios_ui.cjs')],cwd=ROOT,check=True)
    if not live:
        print('Local checks passed. Use --live for Salesforce, connected assessments, inventory and deletion exercises.')
        return
    state=json.loads(STATE.read_text())
    verify(state)
    run('scripts/seed_failure_demo.py')
    run('scripts/check_data_improvement.py')
    tests_ran = 0
    for test_class in ('NonprofitAIReadinessTest','ReadinessStaffReviewTest','ReadinessMCPTest','ReadinessDataFreshnessTest','ReadinessEvidenceTest','ReadinessDemoSeedTest','ReadinessDemoScenariosTest'):
        apex=sf('apex','run','test','--class-names',test_class,'--synchronous',
                '--result-format','json','--target-org',state['alias'])
        summary=apex.get('summary',{})
        if summary.get('outcome')!='Passed':
            raise RuntimeError('Salesforce action tests did not pass')
        tests_ran += summary['testsRan']
    print(f'Salesforce tests: {tests_ran} passed',flush=True)
    run('scripts/run_demo.py','--live')
    run('scripts/test_salesforce_action.py')
    inventory=payload(exchange([('tools/call',{'name':'org_capabilities','arguments':{}})])[0])
    if not isinstance(inventory.get('licenses'),list) or not isinstance(inventory.get('capabilities'),list):
        raise RuntimeError('Capability inventory contract failed')
    if any(row.get('usage')!='not_verified' for row in inventory['capabilities']):
        raise RuntimeError('Inventory incorrectly implied verified usage')
    if any(value not in {'available','limited','unavailable'} for value in inventory.get('sections',{}).values()):
        raise RuntimeError('Practice inventory was unavailable or returned an unexpected section status')
    print('License and feature inventory contract passed; restricted sections and actual usage remain unverified',flush=True)
    run('scripts/check_erasure_demo.py')
    if agentforce:
        run('scripts/check_agentforce_action.py')
    report={'automated_checks':'passed','salesforce_tests':tests_ran,
            'connected_scoring':'passed','synthetic_data_correction_and_restore':'passed','capability_inventory':'passed','synthetic_deletion_exercise':'passed',
            'browser_checks':'separate_manual_evidence','agentforce_conversations':'published_action_evidence_collected_review_required' if agentforce else 'not_exercised',
            'organizational_readiness':'not_established'}
    (STATE.parent/'full-check-results.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PASS — all automated MVP checks. Screen behavior and Agentforce conversations are separate checks.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--live',action='store_true',help='Use verified practice scratch org; seeds fictional failures, temporarily corrects/restores them, and soft-deletes one fictional contact')
    p.add_argument('--agentforce',action='store_true',help='Also collect activated Agentforce action evidence in the separately prepared agent scratch org; refusal text requires review')
    args=p.parse_args()
    if args.agentforce and not args.live:
        p.error('--agentforce requires --live and the separate prepared Agentforce scratch org')
    try:
        main(args.live,args.agentforce)
    except (RuntimeError,subprocess.CalledProcessError,subprocess.TimeoutExpired) as error:
        print('Full check did not complete successfully; review the last named check.',file=sys.stderr)
        sys.exit(1)
