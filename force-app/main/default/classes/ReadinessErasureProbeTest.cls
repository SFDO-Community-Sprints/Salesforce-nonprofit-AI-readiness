@IsTest private class ReadinessErasureProbeTest {
    @TestSetup static void setup() {
        Id minimum = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'eraseyes','eraseno'}) {
            users.add(new User(ProfileId=minimum, Username=alias+'-'+UserInfo.getOrganizationId()+'@example.invalid',
                Alias=alias, LastName=alias, Email=alias+'@example.invalid', EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='Europe/London'));
        }
        insert users;
        insert new PermissionSetAssignment(AssigneeId=users[0].Id,
            PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Erasure_Tester' LIMIT 1].Id);
    }
    private static User actor(String alias) { return [SELECT Id FROM User WHERE Alias=:alias LIMIT 1]; }
    @IsTest static void deniedBeforeWrites() {
        System.runAs(actor('eraseno')) {
            try { ReadinessErasureProbe.run(URL.getOrgDomainUrl().getHost(),true); System.assert(false); }
            catch (ReadinessErasureProbe.ProbeException expected) {}
        }
        System.assertEquals(0,[SELECT COUNT() FROM Contact ALL ROWS]);
    }
    @IsTest static void targetAndConfirmationRequired() {
        String host='fixture.scratch.my.salesforce.com';
        ReadinessErasureProbe.verifyTarget(host,host,true,true);
        for (Integer check=0;check<5;check++) {
            Boolean denied=false;
            try {
                ReadinessErasureProbe.verifyTarget(check==0 ? null : host,
                    check==1 ? 'other.scratch.my.salesforce.com' : check==2 ? 'production.my.salesforce.com' : host,
                    check!=3,check!=4);
            } catch (ReadinessErasureProbe.ProbeException expected) { denied=true; }
            System.assert(denied,'Wrong target or unconfirmed operation must fail.');
        }
        System.runAs(actor('eraseyes')) {
            try { ReadinessErasureProbe.run('wrong.scratch.my.salesforce.com',true); System.assert(false); }
            catch (ReadinessErasureProbe.ProbeException expected) {}
        }
        System.assertEquals(0,[SELECT COUNT() FROM Contact ALL ROWS]);
    }
    @IsTest static void measuresRealDeletionWithoutClaimingErasure() {
        System.runAs(actor('eraseyes')) {
            Map<String,Object> result=ReadinessErasureProbe.measure();
            System.assertEquals('observed',result.get('status'));
            System.assertEquals('pass',result.get('sourceActiveAbsent'));
            System.assertEquals('pass',result.get('aggregateExclusion'));
            System.assertEquals('fail',result.get('recycleBinErased'));
            System.assertEquals(true,result.get('recycleBinRecoverable'));
            System.assertEquals('soft_deleted',result.get('cleanup'));
            System.assertEquals(5,((List<Object>)result.get('external')).size());
            for (Object item : (List<Object>)result.get('external')) {
                Map<String,Object> destination=(Map<String,Object>)item;
                System.assertEquals('unknown',destination.get('status'));
                System.assertNotEquals(null,destination.get('required_binding'));
            }
            System.assertEquals(false,Schema.sObjectType.Contact.fields.Email.isAccessible());
            System.assertEquals(true,Schema.sObjectType.Contact.isUpdateable(),'Salesforce requires edit permission for Contact delete; probe never updates existing records.');
        }
        System.assertEquals(0,[SELECT COUNT() FROM Contact]);
        List<Contact> retained=[SELECT LastName, IsDeleted FROM Contact ALL ROWS];
        System.assertEquals(1,retained.size());
        System.assert(retained[0].IsDeleted);
        System.assert(retained[0].LastName.startsWith('SYNTHETIC Readiness erasure '));
    }
    @IsTest static void failureAfterInsertStillDeletesOnlyCanary() {
        insert new Contact(LastName='Existing unrelated record');
        System.runAs(actor('eraseyes')) {
            ReadinessErasureProbe.failAfterInsert=true;
            Map<String,Object> result=ReadinessErasureProbe.measure();
            System.assertEquals('failed',result.get('status'));
            System.assertEquals('soft_deleted',result.get('cleanup'));
            System.assertEquals('unknown',result.get('sourceActiveAbsent'));
            System.assertEquals('unknown',result.get('recycleBinErased'));
            ReadinessErasureProbe.failAfterInsert=false;
        }
        System.assertEquals(1,[SELECT COUNT() FROM Contact]);
        System.assertEquals('Existing unrelated record',[SELECT LastName FROM Contact LIMIT 1].LastName);
        System.assertEquals(2,[SELECT COUNT() FROM Contact ALL ROWS]);
    }
}
