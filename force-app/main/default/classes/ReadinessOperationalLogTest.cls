@IsTest
private class ReadinessOperationalLogTest {
    @TestSetup static void users() {
        Id profile = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'logone','logtwo'}) {
            users.add(new User(ProfileId=profile,Username=alias+'-'+UserInfo.getOrganizationId()+'@example.invalid',
                Email=alias+'@example.invalid',LastName='SYNTHETIC log reader',Alias=alias,
                TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US'));
        }
        insert users;
        Id role = [SELECT Id FROM PermissionSet WHERE Name='Readiness_Operations_Reader' LIMIT 1].Id;
        insert new List<PermissionSetAssignment>{new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=role),
            new PermissionSetAssignment(AssigneeId=users[1].Id,PermissionSetId=role)};
    }
    @IsTest static void rejectsPayloadsBeforeDml() {
        Integer before = Limits.getDmlStatements();
        System.assertEquals(false,ReadinessOperationalLog.recordEvent('https://example.invalid/token','inspection','pass'));
        System.assertEquals(false,ReadinessOperationalLog.recordEvent('runtime_probe',UserInfo.getUserId(),'pass'));
        System.assertEquals(false,ReadinessOperationalLog.recordEvent('runtime_probe','inspection','secret@example.invalid'));
        System.assertEquals(false,ReadinessOperationalLog.recordEvent(null,null,null));
        System.assertEquals(before,Limits.getDmlStatements());
        System.assertEquals(0,[SELECT COUNT() FROM Readiness_Operation__c]);
    }
    @IsTest static void readerSeesOnlyOwnSanitizedEventsWithoutCrmPermissions() {
        User one = [SELECT Id FROM User WHERE Alias='logone' LIMIT 1];
        User two = [SELECT Id FROM User WHERE Alias='logtwo' LIMIT 1];
        System.runAs(one) {
            System.assert(!Schema.sObjectType.Contact.isAccessible());
            System.assert(!Schema.sObjectType.Readiness_Operation__c.isCreateable());
            System.assert(!Schema.sObjectType.Readiness_Operation__c.isUpdateable());
            System.assert(ReadinessOperationalLog.recordEvent('runtime_probe','inspection','pass'));
            List<Readiness_Operation__c> events = [SELECT Source__c,Check__c,Outcome__c FROM Readiness_Operation__c WITH USER_MODE];
            System.assertEquals(1,events.size());
            System.assertEquals('runtime_probe',events[0].Source__c);
            System.assertEquals('inspection',events[0].Check__c);
            System.assertEquals('pass',events[0].Outcome__c);
        }
        System.runAs(two) {
            System.assertEquals(0,[SELECT COUNT() FROM Readiness_Operation__c WITH USER_MODE]);
            System.assert(ReadinessOperationalLog.recordEvent('control','runtime_execution','stopped'));
            System.assertEquals(1,[SELECT COUNT() FROM Readiness_Operation__c WITH USER_MODE]);
        }
        System.assertEquals(2,[SELECT COUNT() FROM Readiness_Operation__c]);
        System.assertEquals(0,[SELECT COUNT() FROM Contact]);
    }
}
