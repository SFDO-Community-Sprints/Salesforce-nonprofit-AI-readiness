#!/usr/bin/env python3
"""Provision one API-only MCP identity in the explicitly saved disposable scratch."""
import argparse
import json
from pathlib import Path
import sys
import tempfile

from mcp_connection import MCP_STATE, PROFILE, PERMISSION_SET, load_connection, verify_connection, authenticated_identity
from scratch_demo import STATE, sf, query, verify


def setup(alias, path=MCP_STATE, scratch_path=STATE):
    if path.exists():
        binding = load_connection(path, scratch_path)
        if binding['alias'] != alias:
            raise RuntimeError('Existing MCP binding uses a different alias; refusing replacement')
        return binding
    scratch = json.loads(scratch_path.read_text())
    verify(scratch)
    if alias == scratch['alias'] or not alias or len(alias) > 80 or any(not (c.isascii() and (c.isalnum() or c in '_-')) for c in alias):
        raise RuntimeError('Choose a separate simple MCP alias')
    existing = any(row.get('alias') == alias for row in sf('alias', 'list'))
    if existing:
        identity = authenticated_identity(alias)
        binding = {'alias': alias, 'org_id': identity.get('organization_id'), 'user_id': identity.get('user_id')}
    else:
        definition = {'profileName': PROFILE, 'permsets': [PERMISSION_SET],
                      'LastName': 'SYNTHETIC MCP Integration', 'Email': 'readiness-mcp@example.invalid'}
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as handle:
                json.dump(definition, handle)
                temporary = Path(handle.name)
            created = sf('org', 'create', 'user', '--target-org', scratch['alias'],
                         '--set-alias', alias, '--definition-file', str(temporary))
        finally:
            if temporary:
                temporary.unlink(missing_ok=True)
        # CLI responses/auth stay private; only the expected identity is persisted.
        username = created.get('username')
        if not isinstance(username, str):
            raise RuntimeError('Scratch MCP user creation returned no identity; inspect locally')
        escaped = username.replace('\\', '\\\\').replace("'", "\\'")
        users = query(scratch['alias'], "SELECT Id FROM User WHERE Username='" + escaped + "'")
        if len(users) != 1:
            raise RuntimeError('Scratch MCP user identity unavailable')
        binding = {'alias': alias, 'org_id': scratch['org_id'], 'user_id': users[0]['Id']}
    verify_connection(binding, scratch)
    path.parent.mkdir(exist_ok=True)
    # Exclusive creation prevents replacing a binding created by another process.
    with path.open('x') as handle:
        json.dump(binding, handle, indent=2)
        handle.write('\n')
    path.chmod(0o600)
    return binding


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--alias', required=True, help='New dedicated local credential alias')
    args = parser.parse_args()
    try:
        setup(args.alias)
    except Exception:
        print('Dedicated MCP setup failed; no fallback credential was selected. Inspect local setup privately.', file=sys.stderr)
        sys.exit(1)
    print('Dedicated API-only MCP scratch identity verified; binding saved under .local/.')
