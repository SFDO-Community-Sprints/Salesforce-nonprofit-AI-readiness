"""Measure erasure evidence coverage; never assert erasure or legal compliance."""
import argparse
import json
import re

REQUIRED = {
    'salesforce': ('active_read_absent', 'recycle_bin_absent', 'agent_output_absent', 'retention_approval'),
    'integrations': ('destination_absent', 'sync_no_reintroduction', 'retention_approval'),
    'logs': ('stored_log_absent', 'new_log_no_reappearance', 'retention_approval'),
    'backups': ('restore_no_reintroduction', 'retention_approval'),
    'exports': ('export_copy_absent', 'retention_approval'),
}
ACTIONS = {
    'destination_inventory': ('Privacy lead', 'List the systems and copies that receive this information, and name an owner for each.'),
    'active_read_absent': ('Salesforce admin', 'Check that erased information no longer appears in active Salesforce records.'),
    'recycle_bin_absent': ('Salesforce admin', 'Review approved deletion from the Recycle Bin and confirm what remains recoverable.'),
    'agent_output_absent': ('AI service owner', 'Stop affected agent use and check that erased information cannot appear in agent answers.'),
    'retention_approval': ('Privacy lead', 'Document which information may be retained, why, for how long and who approved it.'),
    'destination_absent': ('Integration owner', 'Check that the connected service removed the information covered by the request.'),
    'sync_no_reintroduction': ('Integration owner', 'Test the next synchronization and prevent erased information from being copied back.'),
    'stored_log_absent': ('Operations owner', 'Review retained logs and apply the approved removal or retention procedure.'),
    'new_log_no_reappearance': ('Operations owner', 'Test new activity and ensure erased information is not written into logs again.'),
    'restore_no_reintroduction': ('Backup owner', 'Rehearse an approved restore with fictional records and prevent erased information from becoming active again.'),
    'export_copy_absent': ('Data owner', 'Locate exported copies, contact their owners and verify the approved removal or retention outcome.'),
}

IDENTIFIER = re.compile(r'[a-z][a-z0-9_-]{0,79}\Z')


def identifier(value):
    return type(value) is str and IDENTIFIER.fullmatch(value) is not None


def evaluate(inventory):
    """Accept canonical references, never subject identifiers or raw test artifacts."""
    invalid = ValueError('Invalid erasure evidence inventory')
    if (type(inventory) is not dict or set(inventory) != {'mode', 'systems', 'evidence'}
            or inventory['mode'] not in ('actual', 'simulation')
            or type(inventory['systems']) is not list or type(inventory['evidence']) is not list):
        raise invalid
    systems = {}
    for system in inventory['systems']:
        if (type(system) is not dict or set(system) != {'id', 'category'}
                or not identifier(system['id']) or type(system['category']) is not str
                or system['category'] not in REQUIRED or system['id'] in systems):
            raise invalid
        systems[system['id']] = system['category']
    evidence = {}
    for item in inventory['evidence']:
        if (type(item) is not dict or set(item) != {'system_id', 'probe_id', 'result', 'evidence_ref', 'reviewer_ref'}
                or not all(identifier(item[key]) for key in ('system_id', 'probe_id', 'evidence_ref', 'reviewer_ref'))
                or type(item['result']) is not str or item['result'] not in ('observed', 'failed')
                or item['system_id'] not in systems
                or item['probe_id'] not in REQUIRED[systems[item['system_id']]]):
            raise invalid
        key = (item['system_id'], item['probe_id'])
        if key in evidence:
            raise invalid
        evidence[key] = item
    checks = []
    for category, probes in REQUIRED.items():
        matching = [sid for sid, kind in systems.items() if kind == category]
        if not matching:
            checks.append({'category': category, 'system_id': None,
                           'probe_id': 'destination_inventory', 'status': 'unknown'})
        for sid in matching:
            for probe in probes:
                entry = evidence.get((sid, probe))
                status = 'unknown'
                if entry:
                    status = ('simulated_' if inventory['mode'] == 'simulation' else 'reported_') + entry['result']
                checks.append({'category': category, 'system_id': sid, 'probe_id': probe,
                               'status': status})
    follow_ups = []
    for check in checks:
        if check['status'] not in ('unknown', 'reported_failed', 'simulated_failed'):
            continue
        owner, action = ACTIONS[check['probe_id']]
        failed = check['status'].endswith('_failed')
        priority = 'High' if failed or check['probe_id'] == 'destination_inventory' else 'Medium'
        follow_ups.append({**check, 'priority': priority, 'owner': owner,
                           'action': action, 'basis': 'fictional_failure' if check['status'] == 'simulated_failed'
                           else 'reported_failure' if failed else 'missing_evidence'})
    follow_ups.sort(key=lambda item: 0 if item['priority'] == 'High' else 1)
    return {
        'version': 'erasure-evidence-coverage-v1', 'mode': inventory['mode'],
        'decision': 'not_assessed', 'independently_verified': False,
        'required_checks': len(checks),
        'reported_observations': sum(c['status'] == 'reported_observed' for c in checks),
        'reported_failures': sum(c['status'] == 'reported_failed' for c in checks),
        'simulated_failures': sum(c['status'] == 'simulated_failed' for c in checks),
        'follow_ups': follow_ups,
        'unknown_checks': sum(c['status'] == 'unknown' for c in checks),
        'checks': checks,
        'limitation': 'Coverage only. References and reviewers are reported, not independently verified. '
                      'Actual destinations, retention decisions, executable probes and restore/sync tests '
                      'must be verified before assessing end-to-end erasure; no compliance conclusion is made.',
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('inventory')
    args = parser.parse_args()
    try:
        with open(args.inventory) as source:
            result = evaluate(json.load(source))
    except (OSError, ValueError, TypeError):
        parser.exit(1, 'Erasure evidence unavailable or invalid.\n')
    print(json.dumps(result, indent=2))
