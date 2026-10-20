"""Pin each specialist role to its exact intended grants; profiles remain additive."""
import unittest
from xml.etree import ElementTree as ET
from demo import ROOT

NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def role(name, agent=False):
    return ET.parse(ROOT / ('agentforce' if agent else 'force-app') / 'main/default/permissionsets' /
                    (name + '.permissionset-meta.xml')).getroot()


def names(root, group, field):
    return {node.find('m:' + field, NS).text for node in root.findall('m:' + group, NS)}


class PermissionScopeTests(unittest.TestCase):
    def test_mcp_is_only_fixed_action_and_api_transport(self):
        root = role('Readiness_MCP')
        self.assertEqual(names(root, 'classAccesses', 'apexClass'), {'ReadinessMCP'})
        self.assertEqual(names(root, 'customPermissions', 'name'), {'Readiness_Run_MCP_Assessment'})
        self.assertEqual(names(root, 'userPermissions', 'name'), {'ApiEnabled', 'ApiUserOnly'})
        for group in ('objectPermissions', 'fieldPermissions', 'applicationVisibilities', 'tabSettings', 'agentAccesses'):
            self.assertEqual(root.findall('m:' + group, NS), [], group)

    def test_assessor_has_no_staff_api_or_write_privileges(self):
        root = role('Readiness_Assessor')
        self.assertEqual(names(root, 'classAccesses', 'apexClass'), {'NonprofitAIReadiness', 'ReadinessDataFreshness', 'ReadinessOrgChecks'})
        self.assertEqual(names(root, 'objectPermissions', 'object'), {'Account', 'Contact'})
        self.assertEqual(names(root, 'fieldPermissions', 'field'), {'Contact.Email', 'Contact.AccountId'})
        for grant in root.findall('m:objectPermissions', NS):
            for key in ('allowCreate', 'allowEdit', 'allowDelete', 'viewAllRecords', 'modifyAllRecords'):
                self.assertEqual(grant.find('m:' + key, NS).text, 'false', key)
        for grant in root.findall('m:fieldPermissions', NS):
            self.assertEqual(grant.find('m:editable', NS).text, 'false')
        for group in ('userPermissions', 'customPermissions', 'agentAccesses'):
            self.assertEqual(root.findall('m:' + group, NS), [])

    def test_evidence_reviewer_has_only_evaluator_access(self):
        root = role('Readiness_Evidence_Reviewer')
        self.assertEqual(names(root, 'classAccesses', 'apexClass'), {'ReadinessEvidence'})
        self.assertEqual(names(root, 'customPermissions', 'name'), {'Readiness_Review_Evidence'})
        for group in ('objectPermissions', 'fieldPermissions', 'userPermissions', 'agentAccesses', 'applicationVisibilities'):
            self.assertEqual(root.findall('m:' + group, NS), [], group)

    def test_staff_summary_reader_has_no_raw_evidence_or_write_access(self):
        root = role('Readiness_Staff_Reader')
        self.assertEqual(names(root, 'classAccesses', 'apexClass'), {'ReadinessStaffReview'})
        self.assertEqual(names(root, 'customPermissions', 'name'), {'Readiness_Read_Staff_Outcomes'})
        for group in ('objectPermissions', 'fieldPermissions', 'userPermissions', 'agentAccesses', 'applicationVisibilities'):
            self.assertEqual(root.findall('m:' + group, NS), [], group)

    def test_reviewer_is_only_own_review_creation_and_reading(self):
        root = role('Readiness_Staff_Reviewer')
        self.assertEqual(names(root, 'classAccesses', 'apexClass'), {'ReadinessStaffReview'})
        self.assertEqual(names(root, 'customPermissions', 'name'), {'Readiness_Review_Staff'})
        self.assertEqual(names(root, 'objectPermissions', 'object'), {'AI_Readiness_Staff_Review__c'})
        self.assertEqual(names(root, 'fieldPermissions', 'field'),
                         {'AI_Readiness_Staff_Review__c.Snapshot__c', 'AI_Readiness_Staff_Review__c.Version__c'})
        grant = root.find('m:objectPermissions', NS)
        for key in ('allowCreate', 'allowRead'):
            self.assertEqual(grant.find('m:' + key, NS).text, 'true')
        for key in ('allowEdit', 'allowDelete', 'viewAllRecords', 'modifyAllRecords'):
            self.assertEqual(grant.find('m:' + key, NS).text, 'false')
        self.assertEqual(root.findall('m:userPermissions', NS), [])

    def test_followup_and_agent_access_do_not_bundle_other_roles(self):
        root = role('Readiness_Follow_Up')
        self.assertEqual(names(root, 'customPermissions', 'name'), {'Readiness_Create_Follow_Up'})
        self.assertEqual(names(root, 'userPermissions', 'name'), {'ActivitiesAccess', 'CreateTask', 'EditTask'})
        self.assertEqual(names(root, 'fieldPermissions', 'field'), {'Task.Description'})
        for group in ('objectPermissions', 'classAccesses', 'agentAccesses'):
            self.assertEqual(root.findall('m:' + group, NS), [])
        root = role('Readiness_Employee_Agent_Access', agent=True)
        self.assertEqual(names(root, 'agentAccesses', 'agentName'), {'Nonprofit_Readiness'})
        for group in ('objectPermissions', 'fieldPermissions', 'classAccesses', 'userPermissions', 'customPermissions'):
            self.assertEqual(root.findall('m:' + group, NS), [])
