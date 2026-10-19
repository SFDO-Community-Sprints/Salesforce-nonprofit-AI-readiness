import json
import unittest

from erasure_evidence import REQUIRED, evaluate


class ErasureEvidenceTests(unittest.TestCase):
    def inventory(self, mode='actual'):
        systems = [{'id': category, 'category': category} for category in REQUIRED]
        evidence = [{'system_id': system['id'], 'probe_id': probe, 'result': 'observed',
                     'evidence_ref': 'run_20261019_probe', 'reviewer_ref': 'reviewer_01'}
                    for system in systems for probe in REQUIRED[system['category']]]
        return {'mode': mode, 'systems': systems, 'evidence': evidence}

    def test_complete_report_cannot_assert_verified_erasure(self):
        result = evaluate(self.inventory())
        self.assertEqual(result['decision'], 'not_assessed')
        self.assertFalse(result['independently_verified'])
        self.assertEqual(result['reported_observations'], 14)
        self.assertEqual(result['unknown_checks'], 0)

    def test_salesforce_component_does_not_cover_other_destinations(self):
        inventory = self.inventory()
        inventory['systems'] = inventory['systems'][:1]
        inventory['evidence'] = inventory['evidence'][:4]
        result = evaluate(inventory)
        self.assertEqual(result['unknown_checks'], 4)
        self.assertEqual(result['decision'], 'not_assessed')
        self.assertEqual({c['category'] for c in result['checks'] if c['status'] == 'unknown'},
                         {'integrations', 'logs', 'backups', 'exports'})

    def test_restore_sync_and_retention_are_required(self):
        inventory = self.inventory()
        inventory['evidence'] = [item for item in inventory['evidence']
                                 if item['probe_id'] not in ('restore_no_reintroduction', 'sync_no_reintroduction', 'retention_approval')]
        self.assertEqual(evaluate(inventory)['unknown_checks'], 7)

    def test_simulation_and_failures_remain_unverified(self):
        inventory = self.inventory('simulation')
        result = evaluate(inventory)
        self.assertEqual(result['reported_observations'], 0)
        self.assertEqual({check['status'] for check in result['checks']}, {'simulated_observed'})
        inventory['mode'] = 'actual'
        inventory['evidence'][0]['result'] = 'failed'
        self.assertEqual(evaluate(inventory)['reported_failures'], 1)

    def test_rejects_attestations_raw_data_unknown_probes_and_duplicate_refs(self):
        sensitive = 'FICTIONAL-sensitive-donor@example.invalid'
        cases = [None, {'mode': 'actual', 'systems': [], 'evidence': [], 'raw': sensitive}]
        for mutate in (
            lambda value: value['evidence'][0].update(result=True),
            lambda value: value['evidence'][0].update(evidence_ref=sensitive),
            lambda value: value['evidence'][0].update(probe_id='not_a_probe'),
            lambda value: value['evidence'].append(value['evidence'][0]),
            lambda value: value['systems'][0].update(id={'raw': sensitive}),
        ):
            value = self.inventory()
            mutate(value)
            cases.append(value)
        for value in cases:
            with self.subTest(value=value), self.assertRaises(ValueError) as error:
                evaluate(value)
            self.assertNotIn(sensitive, str(error.exception))

    def test_fictional_failure_seed_produces_every_follow_up(self):
        from pathlib import Path
        value = json.loads((Path(__file__).resolve().parents[1] / 'demo' / 'erasure-failures.json').read_text())
        result = evaluate(value)
        self.assertEqual(result['simulated_failures'], 14)
        self.assertEqual(len(result['follow_ups']), 14)
        self.assertEqual({item['basis'] for item in result['follow_ups']}, {'fictional_failure'})
        self.assertEqual({item['priority'] for item in result['follow_ups']}, {'High'})
        self.assertEqual(result['reported_failures'], 0)
        self.assertEqual(result['decision'], 'not_assessed')
        self.assertNotIn('fictional_reviewer', json.dumps(result))
        self.assertNotIn('fictional_run', json.dumps(result))

    def test_missing_evidence_also_has_prioritized_follow_ups(self):
        result = evaluate({'mode': 'actual', 'systems': [], 'evidence': []})
        self.assertEqual(len(result['follow_ups']), 5)
        self.assertEqual({item['basis'] for item in result['follow_ups']}, {'missing_evidence'})
        self.assertEqual({item['priority'] for item in result['follow_ups']}, {'High'})

    def test_replay_is_deterministic(self):
        value = self.inventory()
        self.assertEqual(evaluate(value), evaluate(json.loads(json.dumps(value))))


if __name__ == '__main__':
    unittest.main()
