@IsTest
private class ReadinessOrgChecksTest {
    @IsTest static void inspectsDeployedRoles() {
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgChecks.assess());
        System.assertEquals('org-configuration-v1',result.get('version'));
        System.assertEquals('deployed_readiness_roles_only',result.get('scope'));
        Map<String,Object> accessResult = (Map<String,Object>)result.get('access');
        System.assertEquals(5,((List<Object>)accessResult.get('checks')).size());
        System.assertEquals(3,((List<Object>)((Map<String,Object>)result.get('privacy')).get('checks')).size());
        System.assertEquals(100,accessResult.get('coverage'),'Admin test execution must inspect actual deployed setup metadata.');
        System.assertEquals(100,accessResult.get('score'),'Deployed role grants must satisfy the documented narrow boundaries.');
        System.assertEquals(100,((Map<String,Object>)result.get('privacy')).get('score'));
    }
    @IsTest static void missingRolesFailAndDeniedMetadataIsUnknown() {
        Map<String,ReadinessOrgChecks.Role> absent = new Map<String,ReadinessOrgChecks.Role>();
        Map<String,Object> observed = ReadinessOrgChecks.evaluate(absent,true);
        System.assertEquals(0,((Map<String,Object>)observed.get('access')).get('score'));
        System.assertEquals(100,((Map<String,Object>)observed.get('access')).get('coverage'));
        Map<String,Object> denied = ReadinessOrgChecks.evaluate(absent,false);
        System.assertEquals(null,((Map<String,Object>)denied.get('access')).get('score'));
        System.assertEquals(0,((Map<String,Object>)denied.get('privacy')).get('coverage'));
    }
    @IsTest static void actualUnexpectedGrantFailsReadonlyCheck() {
        PermissionSet p = new PermissionSet(Name='ReadinessCheckFixture',Label='Readiness check fixture',PermissionsExportReport=true,PermissionsRunReports=true);
        insert p;
        p = [SELECT PermissionsExportReport FROM PermissionSet WHERE Id = :p.Id WITH USER_MODE];
        ReadinessOrgChecks.Role role = new ReadinessOrgChecks.Role();
        role.broad = p.PermissionsExportReport;
        Map<String,Object> result = ReadinessOrgChecks.evaluate(new Map<String,ReadinessOrgChecks.Role>{'Readiness_Assessor'=>role},true);
        List<Object> checks = (List<Object>)((Map<String,Object>)result.get('access')).get('checks');
        System.assertEquals('fail',((Map<String,Object>)checks[0]).get('status'));
        role.broad = false;
        role.objects.add(new ObjectPermissions(SobjectType='Contact',PermissionsCreate=true));
        result = ReadinessOrgChecks.evaluate(new Map<String,ReadinessOrgChecks.Role>{'Readiness_Assessor'=>role},true);
        checks = (List<Object>)((Map<String,Object>)result.get('access')).get('checks');
        System.assertEquals('fail',((Map<String,Object>)checks[0]).get('status'),'Unexpected write permission must not pass.');
    }
    @IsTest static void scoreAndCoverageStaySeparate() {
        Map<String,Object> result = ReadinessOrgChecks.summarize(new List<Object>{new Map<String,Object>{'status'=>'pass'},new Map<String,Object>{'status'=>'fail'},new Map<String,Object>{'status'=>'unknown'},new Map<String,Object>{'status'=>'unknown'}});
        System.assertEquals(25,result.get('score'));
        System.assertEquals(50,result.get('coverage'));
    }
}
