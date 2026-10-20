@IsTest
private class ReadinessControlTest {
    private static Map<String,Object> parsed(String value) {
        return (Map<String,Object>)JSON.deserializeUntyped(value);
    }
    @TestSetup static void managerIdentity() {
        User manager = new User(Alias='ctrlmgr',LastName='Control tester',Email='control@example.invalid',
            Username='control-'+UserInfo.getOrganizationId()+'-'+Datetime.now().getTime()+'@example.invalid',
            ProfileId=UserInfo.getProfileId(),TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
            LanguageLocaleKey='en_US',EmailEncodingKey='UTF-8');
        insert manager;
        for (PermissionSet role : [SELECT Id FROM PermissionSet WHERE Name IN ('Readiness_Control_Manager','Readiness_MCP','Readiness_Follow_Up','Readiness_Assessor')])
            insert new PermissionSetAssignment(AssigneeId=manager.Id,PermissionSetId=role.Id);
    }
    @IsTest static void disabledByDefaultIsFalseAndManagementRequiresPermission() {
        System.assertEquals(false,ReadinessControl.isDisabled());
        System.assertEquals(false,parsed(ReadinessControl.status()).get('disabled'));
        System.assertEquals('control_management_unavailable',parsed(ReadinessControl.setDisabled(true)).get('error'));
        System.assertEquals(false,ReadinessControl.isDisabled());
    }
    @IsTest static void actualStopBlocksEveryEntryThenRecoveryRestoresAssessment() {
        User manager=[SELECT Id FROM User WHERE Alias='ctrlmgr' LIMIT 1];
        System.runAs(manager) {
        System.assertEquals(null,parsed(NonprofitAIReadiness.assessScenario('organization')).get('error'));
        System.assertEquals(true,parsed(ReadinessControl.setDisabled(true)).get('disabled'));
        System.assertEquals('assessment_stopped',parsed(NonprofitAIReadiness.assessScenario('organization')).get('error'));
        NonprofitAIReadiness.Request request = new NonprofitAIReadiness.Request();
        request.scenario = 'organization';
        System.assertEquals('assessment_stopped',parsed(NonprofitAIReadiness.assess(new List<NonprofitAIReadiness.Request>{request})[0].output).get('error'));
        System.assertEquals('assessment_stopped',parsed(NonprofitAIReadiness.assessMcpScenario('organization')).get('error'));
        System.assertEquals('assessment_stopped',parsed(NonprofitAIReadiness.createFollowUpTasks()).get('error'));
        System.assertEquals('assessment_stopped',parsed(NonprofitAIReadiness.capabilityInventory()).get('error'));
        System.assertEquals(false,parsed(ReadinessControl.setDisabled(false)).get('disabled'));
        System.assertEquals(null,parsed(NonprofitAIReadiness.assessScenario('organization')).get('error'));
        System.assertEquals(1,[SELECT COUNT() FROM Readiness_Control__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()]);
        System.assertEquals('control_management_unavailable',parsed(ReadinessControl.setDisabled(null)).get('error'));
        System.assertEquals(false,ReadinessControl.isDisabled());
        }
    }
    @IsTest static void userScopedSettingCannotOverrideOrgStop() {
        insert new Readiness_Control__c(SetupOwnerId=UserInfo.getOrganizationId(),Disabled__c=true);
        insert new Readiness_Control__c(SetupOwnerId=UserInfo.getUserId(),Disabled__c=false);
        System.assertEquals(true,ReadinessControl.isDisabled());
    }
}
