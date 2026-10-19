"""Fictional sensitive-data matrix; no Salesforce connection is made."""
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

import readiness_mcp as mcp
from privacy import build_data_result

SENTINELS = {
    'Name': 'Fictional Maribel Hiddenperson',
    'Phone': '+31-20-555-0187-fictional',
    'MailingStreet': 'Fictional 29 Confidential Lane',
    'HealthNotes__c': 'Fictional beneficiary receives treatment for a private condition',
    'SafeguardingNotes__c': 'Fictional child must not be contacted by the named household member',
    'UnclassifiedCustom__c': 'Fictional private unclassified donor circumstances',
    'Id': '003000000000999AAA',
    'Credential': 'Bearer FICTIONAL-private-session-token-DO-NOT-USE',
}
METRICS = dict(contacts=10, email_present=9, linked_contacts=10, repeated_email_rows=0)


def request(arguments):
    return {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
            'params': {'name': 'readiness_check', 'arguments': arguments}}


class SensitiveMatrixTests(unittest.TestCase):
    def test_all_raw_fields_rejected_without_echo(self):
        for key, sentinel in SENTINELS.items():
            with self.subTest(field=key):
                with self.assertRaises(ValueError) as error:
                    build_data_result({**METRICS, key: sentinel})
                self.assertEqual(str(error.exception), 'Invalid aggregate metrics')
                self.assertNotIn(sentinel, str(error.exception))
                with patch.object(mcp, 'verify') as verify, patch.object(mcp, 'query') as query:
                    result = mcp.dispatch(request({'scenario': 'organization', key: sentinel}))
                    self.assertTrue(result['result']['isError'])
                    self.assertNotIn(sentinel, json.dumps(result))
                    verify.assert_not_called()
                    query.assert_not_called()

    def test_cli_exception_matrix_has_no_values_on_stdout_or_stderr(self):
        # Run the real stdio loop in a child process with every org access mocked.
        harness = '''
import json, sys
from unittest.mock import patch
import readiness_mcp as mcp
stage = sys.argv[1]
sentinel = sys.argv[2]
with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify') as verify, patch.object(mcp, 'query') as query:
    state.read_text.return_value = json.dumps({'alias': 'fictional'})
    if stage == 'verify':
        verify.side_effect = RuntimeError(sentinel)
    else:
        query.side_effect = RuntimeError(sentinel)
    mcp.main()
'''
        directory = Path(__file__).resolve().parent
        wire_request = json.dumps(request({'scenario': 'organization'})) + '\n'
        for stage in ('verify', 'query'):
            for key, sentinel in SENTINELS.items():
                with self.subTest(stage=stage, field=key):
                    child = subprocess.run([sys.executable, '-c', harness, stage, sentinel],
                                           input=wire_request, text=True, capture_output=True,
                                           cwd=directory, timeout=10, check=True)
                    result = json.loads(child.stdout)
                    self.assertTrue(result['result']['isError'])
                    self.assertEqual(child.stderr, '')
                    for value in SENTINELS.values():
                        self.assertNotIn(value, child.stdout + child.stderr)
                    self.assertNotIn('Traceback', child.stdout + child.stderr)

    def test_unexpected_raw_query_fields_are_not_serialized(self):
        for key, sentinel in SENTINELS.items():
            with self.subTest(field=key), patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query:
                state.read_text.return_value = json.dumps({'alias': 'fictional'})
                query.side_effect = [[{**METRICS, key: sentinel}], []]
                result = mcp.dispatch(request({'scenario': 'organization'}))
                self.assertFalse(result['result']['isError'])
                self.assertNotIn(sentinel, json.dumps(result))
                self.assertNotIn(key, result['result']['structuredContent']['metrics'])


if __name__ == '__main__':
    unittest.main()
