#!/usr/bin/env python3
"""Show fictional failures and their follow-up actions without changing Salesforce."""
import json
from demo import ROOT, evaluate
from staff_readiness import evaluate as staff_review
from erasure_evidence import evaluate as erasure_review


def main():
    controls = evaluate(json.loads((ROOT/'demo/poor/fixture.json').read_text()))
    staff = staff_review(json.loads((ROOT/'demo/staff-failures.json').read_text()))
    erasure = erasure_review(json.loads((ROOT/'demo/erasure-failures.json').read_text()))
    report = {'mode': 'simulation', 'warning': 'Fictional examples only; no real safeguards or staff tested.',
              'data_and_safeguards': controls, 'staff_exercises': staff, 'erasure_evidence': erasure}
    destination = ROOT/'.local/failure-demo-results.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(report, indent=2)+'\n')
    print('FICTIONAL DEMONSTRATION — failures and follow-up actions')
    for label, result, field in [('Data and safeguards', controls, 'priorities'),
                                  ('Staff exercises', staff, 'follow_up'),
                                  ('Erasure', erasure, 'follow_ups')]:
        print('\n'+label)
        for action in result[field]:
            print(json.dumps(action, ensure_ascii=False))
    print('\nSaved demonstration: '+str(destination))
    return report


if __name__ == '__main__':
    main()
