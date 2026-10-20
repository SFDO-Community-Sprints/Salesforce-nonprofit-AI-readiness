"""Dedicated credential binding fails closed on identity or permission drift."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import mcp_connection as connection
import setup_mcp_connection as provision

ORG = '00D000000000001AAA'
USER = '005000000000001AAA'
PROFILE = '00e000000000001AAA'
ROLE = '0PS000000000001AAA'
BASE = '0PS000000000002AAA'
CLASS = '01p000000000001AAA'
CUSTOM = '0CP000000000001AAA'
BINDING = {'alias': 'dedicated-mcp', 'org_id': ORG, 'user_id': USER}
SCRATCH = {'alias': 'scratch-admin', 'org_id': ORG, 'hub': 'devhub'}
PERMISSIONS = sorted(connection.PROFILE_PERMISSIONS | connection.API_PERMISSIONS | {'PermissionsModifyAllData', 'PermissionsCreateTask'})


def permission_row(identifier, profile, enabled):
    return {'Id': identifier, 'IsOwnedByProfile': profile,
            **dict.fromkeys(PERMISSIONS, False), **dict.fromkeys(enabled, True)}


class ConnectionTests(unittest.TestCase):
    def setUp(self):
        self.credential = {'id': ORG, 'username': 'synthetic@example.invalid'}
        self.user = {'Id': USER, 'IsActive': True, 'ProfileId': PROFILE,
                     'Profile': {'Name': connection.PROFILE}}
        self.assignments = [{'PermissionSetId': ROLE, 'PermissionSet': {'Name': connection.PERMISSION_SET, 'IsOwnedByProfile': False, 'ProfileId': None}, 'PermissionSetGroupId': None}]
        self.roles = [permission_row(ROLE, False, connection.API_PERMISSIONS),
                      permission_row(BASE, True, connection.PROFILE_PERMISSIONS)]
        self.objects = []
        self.fields = []
        self.entities = [{'ParentId': ROLE, 'SetupEntityType': 'ApexClass', 'SetupEntityId': CLASS},
                         {'ParentId': ROLE, 'SetupEntityType': 'CustomPermission', 'SetupEntityId': CUSTOM}]
        self.identity = patch.object(connection, 'authenticated_identity', return_value={'user_id': USER, 'organization_id': ORG}).start()
        self.sf = patch.object(connection, 'sf', side_effect=self.command).start()
        self.query = patch.object(connection, 'query', side_effect=self.read).start()
        self.verify = patch.object(connection, 'verify').start()
        self.addCleanup(patch.stopall)

    def command(self, *arguments):
        if arguments[:2] == ('org', 'display'):
            self.assertEqual(arguments[-1], BINDING['alias'])
            return self.credential
        return {'fields': [{'name': name, 'type': 'boolean'} for name in PERMISSIONS]}

    def read(self, alias, soql):
        self.assertEqual(alias, SCRATCH['alias'], 'Control-plane inspection must use saved scratch provenance')
        if 'FROM User WHERE' in soql:
            return [self.user]
        if 'FROM PermissionSetAssignment' in soql:
            return self.assignments
        if 'FROM PermissionSet WHERE' in soql:
            return self.roles
        if 'FROM ObjectPermissions' in soql:
            return self.objects
        if 'FROM FieldPermissions' in soql:
            return self.fields
        if 'FROM ApexClass' in soql:
            return [{'Id': CLASS}]
        if 'FROM CustomPermission' in soql:
            return [{'Id': CUSTOM}]
        if 'FROM SetupEntityAccess' in soql:
            return self.entities
        self.fail('Unexpected control-plane query')

    def test_verified_dedicated_binding_returned(self):
        self.assertEqual(connection.verify_connection(BINDING, SCRATCH), BINDING)
        self.verify.assert_called_once_with(SCRATCH)

    def test_missing_file_has_no_admin_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(RuntimeError, 'Dedicated MCP connection unavailable'):
                connection.load_connection(Path(directory)/'missing', Path(directory)/'scratch')
        self.sf.assert_not_called()

    def test_admin_alias_or_wrong_org_rejected_before_inspection(self):
        for update in ({'alias': SCRATCH['alias']}, {'org_id': '00D000000000002AAA'}, {'user_id': "unsafe'"}):
            with self.subTest(update=update), self.assertRaises(RuntimeError):
                connection.verify_connection({**BINDING, **update}, SCRATCH)
        self.sf.assert_not_called()

    def test_actual_authenticated_identity_cannot_be_replaced_by_local_alias(self):
        self.identity.return_value = {'user_id': '005000000000002AAA', 'organization_id': ORG}
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
        self.sf.assert_not_called()

    def test_credential_and_user_identity_must_match(self):
        for key, value in [('id', '00D000000000002AAA'), ('username', None)]:
            with self.subTest(key=key):
                old = self.credential[key]; self.credential[key] = value
                with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
                self.credential[key] = old
        self.user['Id'] = '005000000000002AAA'
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_profile_and_extra_assignments_rejected(self):
        self.user['Profile']['Name'] = 'System Administrator'
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
        self.user['Profile']['Name'] = connection.PROFILE
        self.assignments.append(copy.deepcopy(self.assignments[0]))
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_implicit_matching_profile_assignment_is_not_an_extra_role(self):
        self.assignments.append({'PermissionSetId': BASE, 'PermissionSet': {'Name': 'implicit', 'IsOwnedByProfile': True, 'ProfileId': PROFILE}, 'PermissionSetGroupId': None})
        self.assertEqual(connection.verify_connection(BINDING, SCRATCH), BINDING)
        self.assignments[-1]['PermissionSet']['ProfileId'] = '00e000000000002AAA'
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_group_and_inactive_user_rejected(self):
        self.assignments[0]['PermissionSetGroupId'] = '0PG000000000001AAA'
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
        self.assignments[0]['PermissionSetGroupId'] = None
        self.user['IsActive'] = False
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_elevated_effective_user_permissions_rejected(self):
        for role in self.roles:
            for name in ('PermissionsModifyAllData', 'PermissionsCreateTask'):
                role[name] = True
                with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
                role[name] = False
        self.roles[0]['PermissionsApiUserOnly'] = False
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_raw_object_field_and_extra_class_grants_rejected(self):
        self.objects.append({'ParentId': ROLE, 'SobjectType': 'Contact', 'PermissionsRead': True})
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
        self.objects.clear(); self.fields.append({'Id': 'unexpected'})
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)
        self.fields.clear(); self.entities.append({'ParentId': ROLE, 'SetupEntityType': 'ApexClass', 'SetupEntityId': '01p000000000002AAA'})
        with self.assertRaises(RuntimeError): connection.verify_connection(BINDING, SCRATCH)

    def test_invalid_connection_files_are_sanitized(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'mcp.json'; path.write_text('sensitive-invalid-json')
            with self.assertRaisesRegex(RuntimeError, '^Dedicated MCP connection unavailable; provision and verify .local/mcp.json$'):
                connection.load_connection(path, path)


class ProvisionTests(unittest.TestCase):
    def test_existing_binding_is_verified_without_reprovisioning(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'mcp.json'; path.write_text(json.dumps(BINDING))
            with patch.object(provision, 'load_connection', return_value=BINDING) as load, patch.object(provision, 'sf') as command:
                self.assertEqual(provision.setup(BINDING['alias'], path, Path(directory)/'scratch'), BINDING)
                load.assert_called_once(); command.assert_not_called()


    def test_existing_alias_recovery_requires_full_boundary_verification(self):
        for accepted in (True, False):
            with self.subTest(accepted=accepted), tempfile.TemporaryDirectory() as directory:
                path = Path(directory)/'mcp.json'
                scratch = Path(directory)/'scratch.json'; scratch.write_text(json.dumps(SCRATCH))
                with patch.object(provision, 'verify'), patch.object(provision, 'sf', return_value=[{'alias': BINDING['alias']}]) as command, patch.object(provision, 'authenticated_identity', return_value={'organization_id': ORG, 'user_id': USER}), patch.object(provision, 'verify_connection', side_effect=None if accepted else RuntimeError('denied')) as validate:
                    if accepted:
                        self.assertEqual(provision.setup(BINDING['alias'], path, scratch), BINDING)
                        self.assertEqual(json.loads(path.read_text()), BINDING)
                    else:
                        with self.assertRaises(RuntimeError): provision.setup(BINDING['alias'], path, scratch)
                        self.assertFalse(path.exists())
                    validate.assert_called_once_with(BINDING, SCRATCH)
                    command.assert_called_once_with('alias', 'list')

    def test_new_user_definition_is_narrow_and_binding_has_no_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'mcp.json'
            scratch = Path(directory)/'scratch.json'; scratch.write_text(json.dumps(SCRATCH))
            def command(*args):
                if args[:2] == ('alias', 'list'): return []
                self.assertEqual(args[:3], ('org', 'create', 'user'))
                definition = json.loads(Path(args[-1]).read_text())
                self.assertEqual(definition['profileName'], connection.PROFILE)
                self.assertEqual(definition['permsets'], [connection.PERMISSION_SET])
                self.assertNotIn('generatePassword', definition)
                return {'username': 'synthetic@example.invalid', 'password': 'MUST_NOT_PERSIST'}
            with patch.object(provision, 'verify'), patch.object(provision, 'sf', side_effect=command), patch.object(provision, 'query', return_value=[{'Id': USER}]), patch.object(provision, 'verify_connection'):
                self.assertEqual(provision.setup(BINDING['alias'], path, scratch), BINDING)
                self.assertEqual(json.loads(path.read_text()), BINDING)
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_failed_verification_never_saves_binding(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'mcp.json'
            scratch = Path(directory)/'scratch.json'; scratch.write_text(json.dumps(SCRATCH))
            with patch.object(provision, 'verify'), patch.object(provision, 'sf', side_effect=[[], {'username': 'synthetic@example.invalid'}]), patch.object(provision, 'query', return_value=[{'Id': USER}]), patch.object(provision, 'verify_connection', side_effect=RuntimeError('denied')):
                with self.assertRaises(RuntimeError): provision.setup(BINDING['alias'], path, scratch)
                self.assertFalse(path.exists())


if __name__ == '__main__':
    unittest.main()
