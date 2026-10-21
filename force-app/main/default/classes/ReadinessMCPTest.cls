@IsTest
private with sharing class ReadinessMCPTest {
    @TestSetup static void users() {
        Id profileId = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'mcpread','mcpdeny'}) {
            users.add(new User(ProfileId=profileId,Username=alias+'-'+UserInfo.getOrganizationId()+'@example.invalid',
                Email=alias+'@example.invalid',LastName='SYNTHETIC MCP user',Alias=alias,
                TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US'));
        }
        insert users;
        insert new PermissionSetAssignment(AssigneeId=users[0].Id,
            PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_MCP' LIMIT 1].Id);
    }
    private static Map<String,Object> assess(String scenario) {
        ReadinessMCP.Request request = new ReadinessMCP.Request();
        request.scenario=scenario;
        String output=ReadinessMCP.assess(new List<ReadinessMCP.Request>{request})[0].output;
        System.assert(!output.contains('SENTINEL'));
        System.assert(!output.contains('@example.invalid'));
        System.assert(!output.contains('SELECT'));
        return (Map<String,Object>)JSON.deserializeUntyped(output);
    }
    @IsTest static void facadeReturnsAggregatesWithoutRawCrmOrStaffAccess() {
        User reader = [SELECT Id FROM User WHERE Alias='mcpread' LIMIT 1];
        System.runAs(reader) {
            System.assert(FeatureManagement.checkPermission('Readiness_Run_MCP_Assessment'));
            System.assert(!Schema.sObjectType.Contact.isAccessible());
            System.assert(!Schema.sObjectType.Account.isAccessible());
            System.assert(!Schema.sObjectType.Contact.fields.Email.isAccessible());
            System.assert(!Schema.sObjectType.AI_Readiness_Staff_Review__c.isAccessible());
            System.assert(!FeatureManagement.checkPermission('Readiness_Read_Staff_Outcomes'));
            System.assert(!FeatureManagement.checkPermission('Readiness_Review_Staff'));
            System.assert(!FeatureManagement.checkPermission('Readiness_Create_Follow_Up'));
            Account account = new Account(Name='SYNTHETIC AI Readiness pilot',OwnerId=reader.Id);
            insert account;
            List<Contact> contacts = new List<Contact>();
            for (Integer i=0;i<10;i++) contacts.add(new Contact(AccountId=account.Id,OwnerId=reader.Id,
                LastName='SENTINEL MCP name',Email='SENTINEL-'+i+'@example.invalid',Description='SENTINEL sensitive note'));
            // Fictional system-mode fixture writes do not grant runtime CRUD/FLS.
            insert contacts;
            Boolean rawDenied=false;
            try {
                List<Contact> raw=[SELECT Email FROM Contact WITH USER_MODE LIMIT 1];
            } catch (QueryException ignored) {
                rawDenied=true;
            }
            System.assert(rawDenied,'General API/user-mode reads must remain denied');
            Map<String,Object> result=assess('organization');
            System.assert(!result.containsKey('error'));
            System.assertEquals('sharing_scoped_organization_records',result.get('scope'));
            System.assert(((String)result.get('coverage_note')).contains('restriction rules are not validated'));
            System.assert(((String)result.get('coverage_note')).contains('CRUD/FLS'));
            Integer visible=[SELECT COUNT() FROM Contact WITH SYSTEM_MODE];
            System.assertEquals(visible,((Map<String,Object>)result.get('metrics')).get('contacts'));
            System.assertEquals(100,((Map<String,Object>)result.get('data')).get('score'));
            System.assertEquals('readiness_not_established',result.get('decision'));
            System.assert(!result.containsKey('staff_review'));
            System.assert(!result.containsKey('staff_summary'));
            System.assertEquals('assessment_unavailable',((Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.assessScenario('organization'))).get('error'));
            System.assertEquals('task_creation_unavailable',((Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks())).get('error'));
            System.assertEquals('review_not_permitted',((Map<String,Object>)JSON.deserializeUntyped(
                ReadinessStaffReview.saveReview('{}'))).get('error'));
            System.assertEquals(0,[SELECT COUNT() FROM Task WITH SYSTEM_MODE]);
        }
    }
    @IsTest static void smallCohortAndInvalidScenariosStayFailClosed() {
        User reader = [SELECT Id FROM User WHERE Alias='mcpread' LIMIT 1];
        System.runAs(reader) {
            Account account = new Account(Name='SYNTHETIC AI Readiness poor',OwnerId=reader.Id);
            insert account;
            insert new Contact(AccountId=account.Id,OwnerId=reader.Id,LastName='SENTINEL',Email='SENTINEL@example.invalid');
            Map<String,Object> result=assess('poor');
            System.assertEquals('sharing_scoped_fixed_synthetic_demo_cohort',result.get('scope'));
            System.assertEquals(null,result.get('metrics'));
            System.assertEquals(null,((Map<String,Object>)result.get('data')).get('score'));
            System.assertEquals(true,((Map<String,Object>)result.get('privacy')).get('suppressed'));
            for (String scenario : new List<String>{null,'organization WHERE Email != null','export_records'}) {
                Integer before=Limits.getQueries();
                System.assertEquals('invalid_scenario',assess(scenario).get('error'));
                System.assertEquals(before,Limits.getQueries());
            }
        }
    }
    @IsTest static void facadeOmitsStaffEvenWhenCallerSeparatelyHasOutcomeAccess() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permission : [SELECT Id FROM PermissionSet
                    WHERE Name IN ('Readiness_MCP','Readiness_Staff_Reader')]) {
                assignments.add(new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=permission.Id));
            }
            insert assignments;
        }
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert new AI_Readiness_Staff_Review__c(Version__c='staff-readiness-v1',
                Snapshot__c='{"version":"staff-readiness-v1","mode":"actual","reviews":[]}');
            Map<String,Object> staff=(Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.getLatestReview());
            System.assert(staff.containsKey('staff'),'Test precondition: own outcomes really are available');
            System.assert(FeatureManagement.checkPermission('Readiness_Run_MCP_Assessment'));
            Map<String,Object> result=assess('organization');
            System.assert(!result.containsKey('error'),'Combined-role fixture must reach the fixed aggregate collector');
            System.assert(!result.containsKey('staff_review'));
            System.assert(!result.containsKey('staff_summary'));
            System.assertEquals('unknown; not exercised',result.get('technical_and_staff'));
        }
    }
    @IsTest static void missingPermissionCannotCallSharedCollector() {
        User denied = [SELECT Id FROM User WHERE Alias='mcpdeny' LIMIT 1];
        System.runAs(denied) {
            Integer before=Limits.getQueries();
            System.assertEquals('assessment_unavailable',assess('organization').get('error'));
            System.assertEquals('assessment_unavailable',((Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.assessMcpScenario('organization'))).get('error'));
            System.assertEquals(before,Limits.getQueries());
        }
        System.assertEquals(0,ReadinessMCP.assess(null).size());
    }
}
