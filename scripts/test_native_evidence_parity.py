"""Keep the shared Apex parity cases tied to the original Python scorers."""
import json
import unittest

from demo import ROOT, summarize
from erasure_evidence import evaluate


class NativeEvidenceParityTests(unittest.TestCase):
    def test_native_cases_match_python(self):
        cases = json.loads((ROOT / 'force-app/main/default/staticresources/ReadinessEvidenceParity.resource').read_text())
        self.assertEqual(len(cases), 8)
        for case in cases:
            with self.subTest(case=case['name']):
                if case['kind'] == 'erasure':
                    self.assertEqual(evaluate(case['input']), case['expected'])
                    if case['name'] != 'actual_complete':
                        self.assertEqual(case['input'], json.loads((ROOT / 'demo' / (case['name'] + '.json')).read_text()))
                else:
                    fixture = json.loads((ROOT / 'demo' / case['name'] / 'fixture.json').read_text())
                    statuses = {key: item['status'] for key, item in fixture['simulated_evidence']['technical'].items()}
                    expected = summarize(statuses)
                    self.assertEqual(case['expected'], {key: expected[key] for key in ('score', 'coverage', 'passed', 'applicable')})
                    actual = {item['check_id']: item['result'] for item in case['input']['evidence']}
                    self.assertEqual(actual, {key: status for key, status in statuses.items() if status != 'unknown'})


if __name__ == '__main__':
    unittest.main()
