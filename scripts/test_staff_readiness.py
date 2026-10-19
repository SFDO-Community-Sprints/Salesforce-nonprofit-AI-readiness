import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from staff_readiness import KEY, ROOT, evaluate, evaluate_with_freshness, template


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

    def test_explicit_freshness_boundary_missing_dates_and_no_mutation(self):
        snapshot = self.passed_review()
        original = copy.deepcopy(snapshot)
        policy = {'as_of': '2026-10-19', 'max_age_days': 30,
                  'observed_on': {'scope': '2026-09-19', 'sensitive_data': '2026-09-18'}}
        result = evaluate_with_freshness(snapshot, policy)
        self.assertEqual(result, evaluate_with_freshness(snapshot, policy))
        self.assertEqual(result, evaluate({**snapshot, 'freshness_policy': policy}))
        self.assertEqual(snapshot, original)
        self.assertEqual(result['staff']['checks']['scope'], 'pass')
        self.assertEqual(result['staff']['checks']['sensitive_data'], 'unknown')
        self.assertEqual(result['staff']['checks']['quality'], 'unknown')
        self.assertEqual(result['freshness']['checks']['sensitive_data'], 'expired')
        self.assertEqual(result['freshness']['checks']['quality'], 'missing')
        self.assertNotIn('FICTIONAL-EVIDENCE', json.dumps(result))
        self.assertEqual(evaluate(snapshot)['staff']['score'], '100.0')

    def test_expiry_preserves_critical_gates_but_cannot_confirm_evidence(self):
        snapshot = self.passed_review()
        snapshot['reviews'][0]['critical_failures'] = ['unapproved_decision']
        snapshot['reviews'][1]['critical_failures'] = ['sensitive_disclosure']
        snapshot['reviews'][1]['reviewer_confirmed'] = False
        snapshot['reviews'][2]['answer'] = 'no'
        policy = {'as_of': '2026-10-19', 'max_age_days': 0, 'observed_on': {}}
        result = evaluate_with_freshness(snapshot, policy)
        self.assertEqual(result['critical_failures'], ['scope:unapproved_decision'])
        self.assertEqual(result['decision'], 'blocked_by_observed_critical_failure')
        self.assertEqual(result['staff']['checks']['scope'], 'fail')
        self.assertEqual(result['staff']['checks']['sensitive_data'], 'unknown')
        self.assertEqual(result['staff']['checks']['untrusted_content'], 'unknown')
        snapshot['mode'] = 'simulation'
        self.assertEqual(evaluate_with_freshness(snapshot, policy)['decision'],
                         'blocked_by_simulated_critical_failure')

    def test_freshness_policy_rejects_ambiguous_or_future_dates_and_defaults(self):
        policy = {'as_of': '2026-10-19', 'max_age_days': 30, 'observed_on': {}}
        invalid = [None, {}, {**policy, 'max_age_days': True}, {**policy, 'max_age_days': -1}, {**policy, 'max_age_days': 2147483648},
                   {**policy, 'as_of': '20261019'}, {**policy, 'as_of': '2026-02-30'},
                   {**policy, 'observed_on': {'scope': '2026-10-20'}},
                   {**policy, 'observed_on': {'scope': None}},
                   {**policy, 'observed_on': {'private-sentinel': '2026-10-19'}},
                   {**policy, 'extra': True}]
        for value in invalid:
            with self.subTest(policy=value), self.assertRaises(ValueError):
                evaluate_with_freshness(self.passed_review(), value)

    def test_cli_template_and_observed_fixture_end_to_end(self):
        command = [sys.executable, str(ROOT/'scripts/staff_readiness.py')]
        output = subprocess.run(command+['template'], capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(output.stdout), template())
        with tempfile.TemporaryDirectory() as directory:
            snapshot = Path(directory)/'review.json'
            snapshot.write_text(json.dumps(self.passed_review()))
            output = subprocess.run(command+['evaluate',str(snapshot)], capture_output=True, text=True, check=True)
            self.assertEqual(json.loads(output.stdout)['staff']['score'],'100.0')
            policy = Path(directory)/'policy.json'
            policy.write_text(json.dumps({'as_of': '2026-10-19', 'max_age_days': 30, 'observed_on': {}}))
            output = subprocess.run(command+['evaluate', str(snapshot), '--freshness-policy', str(policy)],
                                    capture_output=True, text=True, check=True)
            self.assertEqual(json.loads(output.stdout)['staff']['coverage'], '0.0')
            policy.write_text('{private-policy-sentinel')
            denied = subprocess.run(command+['evaluate', str(snapshot), '--freshness-policy', str(policy)],
                                    capture_output=True, text=True)
            self.assertEqual(denied.returncode, 1)
            self.assertEqual(denied.stdout, '')
            self.assertNotIn('private-policy-sentinel', denied.stderr)
            snapshot.write_text('{private-sentinel@example.invalid')
            denied = subprocess.run(command+['evaluate',str(snapshot)],capture_output=True,text=True)
            self.assertEqual(denied.returncode,1)
            self.assertEqual(denied.stdout,'')
            self.assertNotIn('private-sentinel',denied.stderr)


if __name__ == '__main__':
    unittest.main()
