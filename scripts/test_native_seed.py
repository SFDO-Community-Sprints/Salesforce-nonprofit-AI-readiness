"""The native fixture must remain identical to the source Salesforce demo trees."""
import json
import unittest
from demo import ROOT

class NativeSeedTests(unittest.TestCase):
    def test_seed_fixture_matches_original_trees(self):
        expected = []
        for name in ('poor', 'improving', 'pilot', 'blocked', 'unknown'):
            row = json.loads((ROOT / 'demo' / name / 'salesforce-tree.json').read_text())['records'][0]
            expected.append({'name': row['Name'], 'contacts': [
                {'lastName': item['LastName'], 'email': item.get('Email')}
                for item in row.get('Contacts', {}).get('records', [])]})
        actual = json.loads((ROOT / 'force-app/main/default/staticresources/ReadinessSeedData.resource').read_text())
        self.assertEqual(actual, expected)
