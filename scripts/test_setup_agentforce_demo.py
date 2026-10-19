import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import setup_agentforce_demo as setup


class SetupAgentforceTests(unittest.TestCase):
    def setUp(self):
        patch('sys.stdout', new=io.StringIO()).start()
        self.addCleanup(patch.stopall)
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.state_path = Path(self.directory.name)/'agentforce.json'
        self.state = {'alias':setup.ALIAS,'hub':'fictional-hub','org_id':'00D000000000001'}
        self.calls=[]
        for name in ('sf','verify','seed','seed_failures','deploy','command'):
            mocked=patch.object(setup,name,side_effect=self.record(name)).start()
            self.addCleanup(patch.stopall)
            setattr(self,name,mocked)

    def record(self,name):
        def result(*args):
            self.calls.append((name,args))
            if name=='sf':
                return [] if args[:2]==('alias','list') else {'orgId':self.state['org_id']}
            if name=='command':
                return {'success':True}
        return result

    def save_state(self):
        self.state_path.write_text(json.dumps(self.state))

    def test_fresh_setup_call_order_and_scoped_commands(self):
        setup.setup('fictional-hub',self.state_path)
        self.assertEqual([name for name,args in self.calls],
            ['sf','sf','verify','seed','seed_failures','deploy','command','command','command'])
        created=self.sf.call_args_list[1].args
        self.assertNotIn('--set-default',created)
        self.assertIn('--duration-days',created)
        self.assertEqual(json.loads(self.state_path.read_text())['alias'],setup.ALIAS)
        for call in self.command.call_args_list:
            self.assertIn('--api-version',call.args)
            self.assertIn('67.0',call.args)
            self.assertIn(setup.ALIAS,call.args)
        self.assertIn('--skip-retrieve',self.command.call_args_list[1].args)

    def test_existing_state_reused_without_overwrite_or_creation(self):
        self.save_state()
        before=self.state_path.read_bytes()
        setup.setup(state_path=self.state_path)
        self.sf.assert_not_called()
        self.assertEqual(before,self.state_path.read_bytes())

    def test_wrong_target_denied_before_seed_deploy_publish(self):
        self.save_state()
        self.verify.side_effect=RuntimeError('Wrong org')
        with self.assertRaises(RuntimeError):
            setup.setup(state_path=self.state_path)
        self.seed.assert_not_called()
        self.deploy.assert_not_called()
        self.command.assert_not_called()

    def test_existing_alias_without_state_is_not_adopted(self):
        self.sf.return_value=[{'alias':setup.ALIAS}]
        self.sf.side_effect=None
        with self.assertRaises(RuntimeError):
            setup.setup('fictional-hub',self.state_path)
        self.assertEqual(self.sf.call_count,1)
        self.assertFalse(self.state_path.exists())
        self.seed.assert_not_called()

    def test_invalid_identity_and_mismatched_hub_fail_closed(self):
        self.save_state()
        with self.assertRaises(RuntimeError):
            setup.setup('other-hub',self.state_path)
        self.state['org_id']='fictional-sensitive@example.invalid'
        self.save_state()
        with self.assertRaises(RuntimeError):
            setup.setup(state_path=self.state_path)
        self.verify.assert_not_called()
        self.seed.assert_not_called()
        for value in (None,False,{},'success',{'success':'true'},{'success':1}):
            with self.subTest(value=value),self.assertRaises(RuntimeError):
                setup.require_success(value)

    def test_validation_failure_prevents_publish_and_activation(self):
        self.save_state()
        self.command.side_effect=lambda *args: {'success':False}
        with self.assertRaises(RuntimeError):
            setup.setup(state_path=self.state_path)
        self.assertEqual(self.command.call_count,1)
        self.assertEqual(self.command.call_args.args[:3],('agent','validate','authoring-bundle'))

    def test_publish_failure_prevents_activation(self):
        self.save_state()
        self.command.side_effect=[{'success':True},{'success':False}]
        with self.assertRaises(RuntimeError):
            setup.setup(state_path=self.state_path)
        self.assertEqual(self.command.call_count,2)


if __name__=='__main__':
    unittest.main()
