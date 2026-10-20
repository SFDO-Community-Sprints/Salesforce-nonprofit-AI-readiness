@IsTest
private class ReadinessRuntimeProbeTest {
    @TestSetup static void users() {
        Id profile = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'rtassess','rtdenied','rtmcp'}) {
            users.add(new User(ProfileId=profile,Username=alias+'-'+UserInfo.getOrganizationId()+'@example.invalid',
                Email=alias+'@example.invalid',LastName='SYNTHETIC runtime probe',Alias=alias,
                TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US'));
        }
        insert users;
        Map<String,Id> roles = new Map<String,Id>();
        for (PermissionSet role : [SELECT Id,Name FROM PermissionSet WHERE Name IN ('Readiness_Assessor','Readiness_MCP')]) roles.put(role.Name,role.Id);
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=roles.get('Readiness_Assessor')),
            new PermissionSetAssignment(AssigneeId=users[2].Id,PermissionSetId=roles.get('Readiness_MCP'))
        };
    }
    private static Map<String,String> statuses() {
        Integer before = Limits.getDmlStatements();
        String raw = ReadinessRuntimeProbe.inspect();
        System.assertEquals(before+5,Limits.getDmlStatements(),'Only five sanitized operation events may be persisted');
        System.assert(!raw.contains('@example.invalid'));
        System.assert(!raw.contains(UserInfo.getUserId()));
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(raw);
        System.assertEquals('executed_salesforce_calls',result.get('source'));
        System.assertEquals(false,result.get('readiness_established'));
        System.assertEquals(true,((Map<String,Object>)result.get('monitoring')).get('recorded'));
        System.assertEquals(5,((List<Object>)result.get('gaps')).size());
        Map<String,String> statuses = new Map<String,String>();
        for (Object item : (List<Object>)result.get('checks')) {
            Map<String,Object> check = (Map<String,Object>)item;
            statuses.put((String)check.get('id'),(String)check.get('status'));
        }
        return statuses;
    }
    @IsTest static void assessorExercisesNativeReadAndDeniedActions() {
        User actor = [SELECT Id FROM User WHERE Alias='rtassess' LIMIT 1];
        System.runAs(actor) {
            Map<String,String> checks = statuses();
            System.assertEquals('pass',checks.get('native_assessment'));
            System.assertEquals('pass',checks.get('contact_read'));
            System.assertEquals('unknown',checks.get('raw_email_read_boundary'));
            System.assertEquals('pass',checks.get('unapproved_task_action'));
            System.assertEquals('pass',checks.get('mcp_boundary'));
        }
    }
    @IsTest static void restrictedIdentityActuallyDeniesRawAndNativeRead() {
        User actor = [SELECT Id FROM User WHERE Alias='rtdenied' LIMIT 1];
        System.runAs(actor) {
            Map<String,String> checks = statuses();
            System.assertEquals('fail',checks.get('native_assessment'));
            System.assertEquals('pass',checks.get('raw_email_read_boundary'));
            System.assertEquals('pass',checks.get('unapproved_task_action'));
            System.assertEquals('pass',checks.get('mcp_boundary'));
        }
    }
    @IsTest static void mcpIdentityExercisesAggregateFacadeWithoutRawAccess() {
        User actor = [SELECT Id FROM User WHERE Alias='rtmcp' LIMIT 1];
        System.runAs(actor) {
            Account cohort = new Account(Name='SYNTHETIC runtime cohort');
            insert cohort;
            List<Contact> contacts = new List<Contact>();
            for (Integer i=0;i<10;i++) contacts.add(new Contact(AccountId=cohort.Id,LastName='SENTINEL runtime',Email='sentinel-'+i+'@example.invalid'));
            insert contacts;
            Map<String,String> checks = statuses();
            System.assertEquals('pass',checks.get('mcp_boundary'));
            System.assertEquals('pass',checks.get('raw_email_read_boundary'));
            System.assertEquals('fail',checks.get('native_assessment'));
        }
    }
}
