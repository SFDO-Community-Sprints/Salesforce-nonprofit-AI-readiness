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

    def test_standalone_script_has_exact_fixture_and_no_deployed_dependencies(self):
        source = (ROOT / 'scripts/apex/seed-demo.apex').read_text()
        embedded = source.split("String fixtureJson = '", 1)[1].split("';", 1)[0]
        expected = json.loads((ROOT / 'force-app/main/default/staticresources/ReadinessSeedData.resource').read_text())
        self.assertEqual(json.loads(embedded), expected)
        for name in ('seed-demo.apex', 'seed-failures.apex'):
            text = (ROOT / 'scripts/apex' / name).read_text()
            self.assertNotIn('ReadinessDemoSeed.', text)
            self.assertNotIn('FROM StaticResource', text)
            self.assertIn("String expectedHost = 'data-connect-7516-dev-ed.scratch.my.salesforce.com'", text)
            self.assertIn('IsSandbox', text)

    def test_seed_contains_raw_inputs_never_assessment_results(self):
        source = (ROOT / 'scripts/apex/seed-demo.apex').read_text()
        embedded = source.split("String practiceInputsJson = '", 1)[1].split("';", 1)[0]
        inputs = json.loads(embedded)
        self.assertEqual(set(inputs), {'poor','improving','pilot','blocked','unknown'})
        for snapshot in inputs.values():
            self.assertEqual(set(snapshot), {'version','mode','reviews'})
            self.assertEqual(len(snapshot['reviews']), 7)
            self.assertNotIn('score', json.dumps(snapshot))
            self.assertNotIn('assessment', snapshot)
        self.assertIn("Version__c='seeded-practice-staff-v1'", source)
        self.assertIn('if (!presets.isEmpty()) delete presets', source)

    def test_post_deploy_grants_only_complete_demo_roles(self):
        source = (ROOT / 'scripts/apex/post-deploy.apex').read_text()
        self.assertIn("{'Readiness_Assessor','Readiness_Staff_Reviewer','Readiness_Evidence_Reviewer'}", source)
        self.assertIn('assigned.contains(role.Id)', source)
        self.assertNotIn("'Readiness_MCP'", source)
