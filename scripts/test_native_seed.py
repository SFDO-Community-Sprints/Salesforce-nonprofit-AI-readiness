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

    def test_all_demo_categories_seeded_as_simulation_only(self):
        source = (ROOT / 'scripts/apex/seed-demo.apex').read_text()
        embedded = source.split("String demoJson = '", 1)[1].split("';", 1)[0]
        scenarios = json.loads(embedded)
        self.assertEqual([item['scenario'] for item in scenarios], ['poor','improving','pilot','blocked','unknown'])
        for item in scenarios:
            self.assertEqual(item['mode'], 'simulation')
            self.assertEqual(item['assessment'], json.loads((ROOT / 'demo' / item['scenario'] / 'expected.json').read_text()))
            self.assertEqual(len(item['assessment']['staff']['checks']), 7)
            self.assertEqual(len(item['assessment']['technical']['checks']), 5)
            self.assertEqual(item['erasure']['mode'], 'simulation')
            self.assertFalse(item['erasure']['independently_verified'])
        self.assertIn("Version__c='demo-scenarios-v1'", source)
        self.assertNotIn("mode':'actual", embedded)

    def test_post_deploy_grants_only_complete_demo_roles(self):
        source = (ROOT / 'scripts/apex/post-deploy.apex').read_text()
        self.assertIn("{'Readiness_Assessor','Readiness_Staff_Reviewer','Readiness_Evidence_Reviewer'}", source)
        self.assertIn('assigned.contains(role.Id)', source)
        self.assertNotIn("'Readiness_MCP'", source)
