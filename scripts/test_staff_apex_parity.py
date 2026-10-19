"""Keep Salesforce's fixed parity corpus and answer key aligned with Python."""
import copy
import json
from pathlib import Path
import unittest

from staff_readiness import KEY, evaluate, template

ROOT = Path(__file__).resolve().parents[1]
RESOURCE = ROOT / 'metadata/main/default/staticresources/StaffReadinessParity.resource'


def parity_cases():
    ready = template()
    for review in ready['reviews']:
        review.update(answer='yes', reviewer_confirmed=True, evidence_ref='private_parity_ref')
        review['actions'] = dict.fromkeys(review['actions'], 'yes')
    cases = [('all_pass', ready), ('all_unknown', {**template(), 'reviews': []})]
    failed = copy.deepcopy(ready)
    for review in failed['reviews']:
        review['answer'] = 'no'
    cases.append(('all_fail', failed))
    one = copy.deepcopy(ready)
    one['reviews'] = one['reviews'][:1]
    cases.append(('one_of_seven', one))
    for index, question in enumerate(KEY['questions']):
        for variant in ('failed', 'missing_action', 'missing_ref', 'unconfirmed'):
            value = copy.deepcopy(ready)
            review = value['reviews'][index]
            if variant == 'failed':
                review['answer'] = 'no'
            elif variant == 'missing_action':
                review['actions'].pop(next(iter(review['actions'])))
            elif variant == 'missing_ref':
                review['evidence_ref'] = None
            else:
                review['reviewer_confirmed'] = False
            cases.append((question['id'] + '_' + variant, value))
        for failure in question['critical_failures']:
            value = copy.deepcopy(ready)
            value['reviews'][index]['critical_failures'] = [failure['id']]
            cases.append((question['id'] + '_' + failure['id'], value))
    for variant, observed in [('boundary', {'scope': '2026-09-19', 'sensitive_data': '2026-09-18'}),
                              ('missing', {})]:
        value = copy.deepcopy(ready)
        value['freshness_policy'] = {'as_of': '2026-10-19', 'max_age_days': 30, 'observed_on': observed}
        cases.append(('freshness_' + variant, value))
    value = copy.deepcopy(ready)
    value['reviews'][0]['critical_failures'] = ['unapproved_decision']
    value['freshness_policy'] = {'as_of': '2026-10-19', 'max_age_days': 0, 'observed_on': {}}
    cases.append(('freshness_preserves_critical', value))
    result = []
    for name, value in cases:
        expected = evaluate(value)
        result.append({'name': name, 'snapshot': value,
                       'expected': {key: expected[key] for key in ('staff', 'critical_failures', 'decision', 'follow_up')}})
    return result


class StaffApexParityTests(unittest.TestCase):
    def test_answer_key_and_fixed_cross_runtime_corpus(self):
        self.assertEqual(json.loads((ROOT / 'metadata/main/default/staticresources/StaffReadinessAnswerKey.resource').read_text()), KEY)
        self.assertEqual(json.loads(RESOURCE.read_text()), parity_cases())
        boundary = next(case for case in parity_cases() if case['name'] == 'one_of_seven')
        self.assertEqual(boundary['expected']['staff']['score'], '14.3')


if __name__ == '__main__':
    unittest.main()
