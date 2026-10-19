#!/usr/bin/env python3
"""Narrow, read-only MCP interface to the saved, verified demo scratch org."""
from datetime import datetime, timezone
import json
import os
import re
import sys

from privacy import build_data_result
from scratch_demo import SCENARIOS, STATE, query, verify

ASSESSMENT_SCENARIOS = [*SCENARIOS, 'organization']

TOOLS = [
    {'name': 'org_identity', 'description': 'Verify the saved active disposable scratch org; return no identifying values.',
     'inputSchema': {'type': 'object', 'properties': {}, 'additionalProperties': False},
     'annotations': {'readOnlyHint': True, 'destructiveHint': False, 'idempotentHint': True, 'openWorldHint': True}},
    {'name': 'org_capabilities', 'description': 'Read AI-readiness-relevant product license allocation and fixed feature availability; assignments and available records do not establish actual feature usage.',
     'inputSchema': {'type': 'object', 'properties': {}, 'additionalProperties': False},
     'annotations': {'readOnlyHint': True, 'destructiveHint': False, 'idempotentHint': True, 'openWorldHint': True}},
    {'name': 'readiness_check', 'description': 'Measure accessible organization Contact records or fixed synthetic demo groups using aggregate queries only. Scope is the authenticated identity, not guaranteed whole-org access. Technical and staff readiness remain unknown.',
     'inputSchema': {'type': 'object', 'properties': {'scenario': {'type': 'string', 'enum': ASSESSMENT_SCENARIOS}},
                     'required': ['scenario'], 'additionalProperties': False},
     'annotations': {'readOnlyHint': True, 'destructiveHint': False, 'idempotentHint': True, 'openWorldHint': True}},
]


def license_relevance(name):
    label = name.lower()
    if label == 'salesforce':
        return 'Core Salesforce access for assessment'
    if 'fundraising' in label and any(term in label for term in ('agent', 'einstein')):
        return 'Fundraising agent entitlement; assignment does not prove the feature is enabled'
    if any(term in label for term in ('data cloud', 'customer data platform')):
        return 'Data grounding option; not required for every AI use case'
    if any(term in label for term in ('agentforce', 'einstein', 'copilot', 'prompt')):
        return 'AI feature entitlement; verify setup and use-case requirements'
    if 'fundraising' in label:
        return 'Fundraising grounding; does not itself enable AI'
    return None


def org_capabilities(state):
    result = {'source': 'salesforce', 'collected_at': datetime.now(timezone.utc).isoformat(),
              'licenses': [], 'capabilities': [], 'sections': {},
              'limitations': 'Only AI-readiness-relevant licenses are shown. Allocation does not establish enablement or actual feature usage. Feature record counts below five are withheld. Missing access is unknown, not disabled. Accessible records do not establish whole-org coverage.'}
    def count(value):
        if type(value) is not int or value < 0:
            raise ValueError('Invalid aggregate count')
        return value if value >= 5 else None
    for table, label, kind, section in [('UserLicense', 'Name', 'user', 'user_licenses'),
                                       ('PermissionSetLicense', 'MasterLabel', 'permission_set', 'permission_set_licenses')]:
        try:
            rows = query(state['alias'], f'SELECT {label}, TotalLicenses, UsedLicenses FROM {table} ORDER BY {label} LIMIT 100')
            if not isinstance(rows, list) or len(rows) > 100:
                raise ValueError('Invalid license result')
            licenses = []
            for row in rows:
                if set(row) - {label, 'TotalLicenses', 'UsedLicenses', 'attributes'}:
                    raise ValueError('Invalid license result')
                name, total, assigned = row[label], row['TotalLicenses'], row['UsedLicenses']
                if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9 ()+.,/_&:'-]{1,120}", name):
                    raise ValueError('Invalid product label')
                if type(total) is not int or total < -1 or type(assigned) is not int or assigned < 0 or (total != -1 and assigned > total):
                    raise ValueError('Invalid license counts')
                relevance = license_relevance(name)
                if relevance is None:
                    continue
                licenses.append({'name': name, 'relevance': relevance, 'total': total if total >= 0 else None, 'assigned': assigned,
                                 'remaining': total - assigned if total >= 0 else None,
                                 'kind': kind})
            result['licenses'].extend(licenses)
            result['sections'][section] = 'limited' if len(rows) == 100 else 'available'
        except Exception:
            result['sections'][section] = 'unavailable'
    for name, table in [('Fundraising', 'GiftTransaction'), ('Service cases', 'Case'), ('Knowledge', 'KnowledgeArticleVersion')]:
        feature = {'name': name, 'availability': 'unknown', 'visibleRecords': None, 'usage': 'not_verified'}
        try:
            rows = query(state['alias'], f'SELECT COUNT(Id) visible_records FROM {table}')
            if len(rows) != 1 or set(rows[0]) - {'attributes', 'visible_records'}:
                raise ValueError('Invalid aggregate result')
            feature['visibleRecords'] = count(rows[0]['visible_records'])
            feature['availability'] = 'available'
        except Exception:
            pass
        result['capabilities'].append(feature)
    return result


def tool_call(name, arguments):
    if not isinstance(arguments, dict):
        raise ValueError('Invalid tool arguments')
    if name in ('org_identity', 'org_capabilities'):
        if arguments:
            raise ValueError('Invalid tool arguments')
    elif name == 'readiness_check':
        if set(arguments) != {'scenario'} or arguments['scenario'] not in ASSESSMENT_SCENARIOS:
            raise ValueError('Invalid tool arguments')
    else:
        raise ValueError('Unknown tool')
    state = json.loads(STATE.read_text())
    verify(state)
    if name == 'org_identity':
        return {'target_type': 'disposable_scratch', 'active': True, 'identity_verified': True,
                'access': 'read_only', 'scope': 'saved_synthetic_demo_cohorts'}
    if name == 'org_capabilities':
        return org_capabilities(state)
    scenario = arguments['scenario']
    where = ' FROM Contact'
    if scenario != 'organization':
        accounts = query(state['alias'], "SELECT Id FROM Account WHERE Name = 'SYNTHETIC AI Readiness " + scenario + "' LIMIT 2")
        if len(accounts) != 1 or not re.fullmatch(r'[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?', accounts[0].get('Id', '')):
            raise ValueError('Demo cohort unavailable')
        where += " WHERE AccountId = '" + accounts[0]['Id'] + "'"
    counts = query(state['alias'], 'SELECT COUNT(Id) contacts, COUNT(Email) email_present, COUNT(AccountId) linked_contacts' + where)
    if len(counts) != 1:
        raise ValueError('Aggregate result unavailable')
    duplicates = query(state['alias'], 'SELECT COUNT(Id) repeated_count' + where +
                       (' WHERE ' if scenario == 'organization' else ' AND ') +
                       'Email != null GROUP BY Email HAVING COUNT(Id) > 1')
    # No record values are selected, including the duplicate grouping field.
    metrics = {key: counts[0][key] for key in ('contacts', 'email_present', 'linked_contacts')}
    metrics['repeated_email_rows'] = sum(row['repeated_count'] - 1 for row in duplicates)
    result = build_data_result(metrics, synthetic=scenario != 'organization' and os.environ.get('READINESS_SYNTHETIC_DEMO') == '1')
    result.update({'scenario': scenario, 'scope': 'accessible_organization_records' if scenario == 'organization' else 'fixed_synthetic_demo_cohort',
                   'source': 'salesforce', 'collected_at': datetime.now(timezone.utc).isoformat(),
                   'technical_and_staff': 'unknown; not exercised', 'decision': 'readiness_not_established'})
    return result


def dispatch(request):
    if not isinstance(request, dict) or request.get('jsonrpc') != '2.0' or not isinstance(request.get('method'), str):
        return {'jsonrpc': '2.0', 'id': None, 'error': {'code': -32600, 'message': 'Invalid request'}}
    if 'id' not in request:
        return None
    response = {'jsonrpc': '2.0', 'id': request['id']}
    method = request['method']
    params = request.get('params', {})
    if not isinstance(params, dict):
        response['error'] = {'code': -32602, 'message': 'Invalid parameters'}
        return response
    if method == 'initialize':
        supported = ('2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05')
        requested = params.get('protocolVersion')
        response['result'] = {'protocolVersion': requested if requested in supported else supported[0], 'capabilities': {'tools': {'listChanged': False}},
                              'serverInfo': {'name': 'salesforce-nonprofit-ai-readiness', 'version': '0.1.0'}}
    elif method == 'ping':
        response['result'] = {}
    elif method == 'tools/list':
        response['result'] = {'tools': TOOLS}
    elif method == 'tools/call':
        try:
            if set(params) - {'name', 'arguments', '_meta'}:
                raise ValueError('Invalid parameters')
            value = tool_call(params.get('name'), params.get('arguments', {}))
            response['result'] = {'content': [{'type': 'text', 'text': json.dumps(value, separators=(',', ':'))}],
                                  'structuredContent': value, 'isError': False}
        except Exception:
            # Exceptions can contain CLI credentials or record values; never serialize them.
            response['result'] = {'content': [{'type': 'text', 'text': 'Readiness request rejected or unavailable; inspect local setup.'}],
                                  'isError': True}
    else:
        response['error'] = {'code': -32601, 'message': 'Method not found'}
    return response


def main():
    for line in sys.stdin:
        try:
            request = json.loads(line)
        except ValueError:
            response = {'jsonrpc': '2.0', 'id': None, 'error': {'code': -32700, 'message': 'Parse error'}}
        else:
            response = dispatch(request)
        if response is not None:
            print(json.dumps(response, separators=(',', ':')), flush=True)


if __name__ == '__main__':
    main()
