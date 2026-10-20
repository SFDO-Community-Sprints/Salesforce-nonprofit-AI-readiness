"""Verify a separate API-only scratch identity before any MCP collection."""
import json
import re
import subprocess

from scratch_demo import ROOT, STATE, query, sf, verify

MCP_STATE = ROOT / '.local' / 'mcp.json'
PROFILE = 'Minimum Access - API Only Integrations'
PERMISSION_SET = 'Readiness_MCP'
API_PERMISSIONS = {'PermissionsApiEnabled', 'PermissionsApiUserOnly'}
PROFILE_PERMISSIONS = API_PERMISSIONS | {'PermissionsChatterInternalUser'}
ID = re.compile(r'[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?')


def require(condition):
    if not condition:
        raise RuntimeError('Dedicated MCP connection unavailable or permission boundary changed')


def authenticated_identity(alias):
    try:
        process = subprocess.run(['sf', 'api', 'request', 'rest', '/services/oauth2/userinfo',
                                  '--target-org', alias], cwd=ROOT, capture_output=True,
                                 text=True, timeout=120)
        require(process.returncode == 0)
        identity = json.loads(process.stdout)
        require(type(identity) is dict)
        return identity
    except Exception:
        raise RuntimeError('Dedicated MCP authenticated identity unavailable') from None


def verify_connection(binding, scratch):
    """Admin credentials verify provenance/configuration; collection uses only binding alias."""
    require(type(binding) is dict and set(binding) == {'alias', 'org_id', 'user_id'})
    require(all(type(binding[key]) is str and ID.fullmatch(binding[key]) for key in ('org_id', 'user_id')))
    require(type(binding['alias']) is str and re.fullmatch(r'[A-Za-z0-9_-]{1,80}', binding['alias']))
    require(binding['alias'] != scratch['alias'] and binding['org_id'] == scratch['org_id'])
    verify(scratch)
    identity = authenticated_identity(binding['alias'])
    require(identity.get('user_id') == binding['user_id'] and identity.get('organization_id') == binding['org_id'])
    credential = sf('org', 'display', '--target-org', binding['alias'])
    require(type(credential.get('id')) is str and credential['id'][:15] == binding['org_id'][:15])
    username = credential.get('username')
    require(type(username) is str and len(username) <= 255)
    escaped = username.replace('\\', '\\\\').replace("'", "\\'")
    users = query(scratch['alias'], "SELECT Id,IsActive,ProfileId,Profile.Name FROM User WHERE Username='" + escaped + "'")
    require(len(users) == 1)
    user = users[0]
    require(user['Id'] == binding['user_id'] and user['IsActive'] is True and user['Profile']['Name'] == PROFILE)
    require(ID.fullmatch(user['ProfileId']))
    assignments = query(scratch['alias'], "SELECT PermissionSetId,PermissionSet.Name,PermissionSet.IsOwnedByProfile,PermissionSet.ProfileId,PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId='" + binding['user_id'] + "'")
    require(all(row.get('PermissionSetGroupId') is None for row in assignments))
    inherited = [row for row in assignments if row['PermissionSet']['IsOwnedByProfile'] is True]
    require(len(inherited) <= 1 and all(row['PermissionSet']['ProfileId'] == user['ProfileId'] for row in inherited))
    direct = [row for row in assignments if row['PermissionSet']['IsOwnedByProfile'] is False]
    require(len(direct) == 1 and direct[0]['PermissionSet']['Name'] == PERMISSION_SET)
    permission_id = direct[0]['PermissionSetId']
    require(type(permission_id) is str and ID.fullmatch(permission_id))
    description = sf('sobject', 'describe', '--sobject', 'PermissionSet', '--target-org', scratch['alias'])
    fields = sorted(field['name'] for field in description['fields']
                    if field['name'].startswith('Permissions') and field['type'] == 'boolean')
    require(API_PERMISSIONS <= set(fields))
    sets = query(scratch['alias'], 'SELECT Id,IsOwnedByProfile,' + ','.join(fields)
                 + " FROM PermissionSet WHERE Id='" + permission_id + "' OR ProfileId='" + user['ProfileId'] + "'")
    require(len(sets) == 2)
    profile_ids = []
    for permission in sets:
        enabled = {field for field in fields if permission.get(field) is True}
        require(all(type(permission.get(field)) is bool for field in fields))
        if permission['IsOwnedByProfile'] is True:
            require(enabled == PROFILE_PERMISSIONS)
            profile_ids.append(permission['Id'])
        else:
            require(permission['Id'] == permission_id and enabled == API_PERMISSIONS)
    require(len(profile_ids) == 1 and ID.fullmatch(profile_ids[0]))
    parents = "('" + permission_id + "','" + profile_ids[0] + "')"
    require(not query(scratch['alias'], 'SELECT Id FROM ObjectPermissions WHERE ParentId IN ' + parents))
    require(not query(scratch['alias'], "SELECT Id FROM FieldPermissions WHERE ParentId IN " + parents))
    classes = query(scratch['alias'], "SELECT Id FROM ApexClass WHERE Name='ReadinessMCP' AND NamespacePrefix=null")
    custom = query(scratch['alias'], "SELECT Id FROM CustomPermission WHERE DeveloperName='Readiness_Run_MCP_Assessment' AND NamespacePrefix=null")
    require(len(classes) == 1 and len(custom) == 1)
    expected = {(permission_id, 'ApexClass', classes[0]['Id']),
                (permission_id, 'CustomPermission', custom[0]['Id'])}
    entities = query(scratch['alias'], 'SELECT ParentId,SetupEntityId,SetupEntityType FROM SetupEntityAccess WHERE ParentId IN ' + parents
                     + " AND SetupEntityType != 'TabSet'")
    require({(row['ParentId'], row['SetupEntityType'], row['SetupEntityId']) for row in entities} == expected)
    return dict(binding)


def load_connection(path=MCP_STATE, scratch_path=STATE):
    try:
        return verify_connection(json.loads(path.read_text()), json.loads(scratch_path.read_text()))
    except Exception:
        raise RuntimeError('Dedicated MCP connection unavailable; provision and verify .local/mcp.json') from None
