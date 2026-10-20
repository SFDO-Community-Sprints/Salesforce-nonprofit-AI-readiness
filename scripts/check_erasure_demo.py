#!/usr/bin/env python3
"""Synthetic soft-deletion exercise; not a legal erasure/compliance verdict."""
import json
import uuid
from scratch_demo import STATE, sf, query, verify
from run_demo import exchange, payload


def snapshot():
    return payload(exchange([('tools/call',{'name':'readiness_check','arguments':{'scenario':'pilot'}})])[0])


def main():
    state=json.loads(STATE.read_text())
    verify(state)
    accounts=query(state['alias'],"SELECT Id FROM Account WHERE Name = 'SYNTHETIC AI Readiness pilot'")
    if len(accounts)!=1:
        raise RuntimeError('Exactly one prepared practice group is required')
    before=snapshot()
    marker='FICTIONAL-ERASURE-'+uuid.uuid4().hex
    record_id=None
    try:
        record_id=sf('data','create','record','--sobject','Contact','--values',
                     f"LastName='{marker}' Email='{uuid.uuid4().hex}@example.invalid' AccountId='{accounts[0]['Id']}' Description='Fictional privacy exercise only'",
                     '--target-org',state['alias'])['id']
        during=snapshot()
        if during['metrics']['contacts'] != before['metrics']['contacts']+1:
            raise RuntimeError('New fictional record was not reflected in a fresh assessment')
        if marker in json.dumps(during):
            raise RuntimeError('Privacy boundary returned a fictional sentinel')
    finally:
        if record_id:
            sf('data','delete','record','--sobject','Contact','--record-id',record_id,'--target-org',state['alias'])
    after=snapshot()
    if after['metrics']!=before['metrics']:
        raise RuntimeError('Deleted fictional record remains in assessment or practice data changed concurrently')
    retained=sf('data','query','--all-rows','--query',
                f"SELECT COUNT(Id) retained FROM Contact WHERE Id = '{record_id}' AND IsDeleted = true",
                '--target-org',state['alias'])['records'][0]['retained']
    if retained != 1:
        raise RuntimeError('Could not verify expected Recycle Bin state')
    report={'synthetic_record_included_then_excluded':True,'agent_received_personal_values':False,
            'soft_delete_remains_recoverable':True,'right_to_erasure_readiness':'not_assessed',
            'not_verified':['physical_erasure','backups','integrations','exports','AI_logs','legal_retention']}
    (STATE.parent/'erasure-demo-results.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PASS — fresh assessment excludes the deleted fictional contact; no personal values returned')
    print('LIMIT — record remains recoverable in Recycle Bin; complete erasure readiness is not assessed')


if __name__=='__main__':
    main()
