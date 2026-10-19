import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from staff_readiness import KEY, ROOT, evaluate, template


class StaffReadinessTests(unittest.TestCase):
    def passed_review(self):
        snapshot = template()
        for i, review in enumerate(snapshot['reviews']):
            review.update(answer='yes', reviewer_confirmed=True, evidence_ref=f'FICTIONAL-EVIDENCE-{i+1}')
            review['actions'] = dict.fromkeys(review['actions'], 'yes')
        return snapshot

    def test_complete_observations_replay_without_pilot_certification(self):
        snapshot = self.passed_review()
        first = evaluate(snapshot)
        self.assertEqual(first, evaluate(copy.deepcopy(snapshot)))
        self.assertEqual(first['staff']['score'], '100.0')
        self.assertEqual(first['staff']['coverage'], '100.0')
        self.assertEqual(first['decision'], 'staff_evidence_complete')
        self.assertNotIn('FICTIONAL-EVIDENCE', json.dumps(first))
        self.assertNotIn('ready_for_bounded_pilot', json.dumps(first))

    def test_unanswered_unconfirmed_and_missing_evidence_stay_unknown(self):
        self.assertEqual(evaluate(template())['staff']['coverage'], '0.0')
        snapshot = self.passed_review()
        snapshot['reviews'][0]['evidence_ref'] = None
        snapshot['reviews'][1]['reviewer_confirmed'] = False
        del snapshot['reviews'][2]['actions']['report_issue']
        result = evaluate(snapshot)
        for qid in ('scope', 'sensitive_data', 'untrusted_content'):
            self.assertEqual(result['staff']['checks'][qid], 'unknown')
        self.assertEqual(result['decision'], 'staff_readiness_not_established')

    def test_partial_and_failed_observed_actions_fail(self):
        snapshot = self.passed_review()
        snapshot['reviews'][0]['answer'] = 'partly'
        snapshot['reviews'][4]['actions']['handle_conflict'] = 'no'
        result = evaluate(snapshot)
        self.assertEqual(result['staff']['checks']['scope'], 'fail')
        self.assertEqual(result['staff']['checks']['quality'], 'fail')
        self.assertEqual(result['critical_failures'], [])

    def test_critical_failures_need_confirmed_evidence(self):
        snapshot = self.passed_review()
        snapshot['reviews'][1]['critical_failures'] = ['sensitive_disclosure']
        result = evaluate(snapshot)
        self.assertEqual(result['decision'], 'blocked_by_observed_critical_failure')
        self.assertEqual(result['critical_failures'], ['sensitive_data:sensitive_disclosure'])
        snapshot['reviews'][1]['evidence_ref'] = None
        result = evaluate(snapshot)
        self.assertEqual(result['critical_failures'], [])
        self.assertEqual(result['staff']['checks']['sensitive_data'], 'unknown')

    def test_unapproved_input_and_personal_prose_rejected_without_echo(self):
        for field, value in [('evidence_ref', 'donor@example.invalid'),
                             ('reviewer_confirmed', 'yes'),
                             ('answer', {'private': 'sentinel'}),
                             ('critical_failures', ['invented_marker']),
                             ('actions', {'export_all': 'yes'})]:
            snapshot = self.passed_review()
            snapshot['reviews'][0][field] = value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, '^Invalid staff review evidence$'):
                evaluate(snapshot)
        snapshot = self.passed_review()
        snapshot['reviews'].append(snapshot['reviews'][0])
        with self.assertRaises(ValueError):
            evaluate(snapshot)

    def test_simulation_fixtures_show_seven_failures_and_ready_comparison(self):
        failures = evaluate(json.loads((ROOT/'demo/staff-failures.json').read_text()))
        ready = evaluate(json.loads((ROOT/'demo/staff-ready.json').read_text()))
        self.assertEqual(failures['evidence_mode'], 'synthetic_simulation')
        self.assertEqual(failures['decision'], 'blocked_by_simulated_critical_failure')
        self.assertEqual(failures['staff']['score'], '0.0')
        self.assertEqual(len(failures['follow_up']), 7)
        self.assertTrue(all(item['priority'] == 'Critical' for item in failures['follow_up']))
        self.assertEqual(ready['staff']['score'], '100.0')
        self.assertEqual(ready['decision'], 'staff_evidence_complete_simulation')
        self.assertEqual(ready['follow_up'], [])

    def test_follow_up_priorities_distinguish_observed_gaps_and_unknowns(self):
        snapshot = self.passed_review()
        snapshot['reviews'][0]['answer'] = 'partly'
        snapshot['reviews'][1]['critical_failures'] = ['sensitive_disclosure']
        snapshot['reviews'][4]['evidence_ref'] = None
        follow_up = evaluate(snapshot)['follow_up']
        self.assertEqual([item['priority'] for item in follow_up], ['Critical', 'High', 'Medium'])
        self.assertEqual([item['question_id'] for item in follow_up], ['sensitive_data', 'scope', 'quality'])
        legacy = self.passed_review()
        legacy.pop('mode')
        self.assertEqual(evaluate(legacy)['evidence_mode'], 'reviewer_confirmed_observations')

    def test_cli_template_and_observed_fixture_end_to_end(self):
        command = [sys.executable, str(ROOT/'scripts/staff_readiness.py')]
        output = subprocess.run(command+['template'], capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(output.stdout), template())
        with tempfile.TemporaryDirectory() as directory:
            snapshot = Path(directory)/'review.json'
            snapshot.write_text(json.dumps(self.passed_review()))
            output = subprocess.run(command+['evaluate',str(snapshot)], capture_output=True, text=True, check=True)
            self.assertEqual(json.loads(output.stdout)['staff']['score'],'100.0')
            snapshot.write_text('{private-sentinel@example.invalid')
            denied = subprocess.run(command+['evaluate',str(snapshot)],capture_output=True,text=True)
            self.assertEqual(denied.returncode,1)
            self.assertEqual(denied.stdout,'')
            self.assertNotIn('private-sentinel',denied.stderr)


if __name__ == '__main__':
    unittest.main()
