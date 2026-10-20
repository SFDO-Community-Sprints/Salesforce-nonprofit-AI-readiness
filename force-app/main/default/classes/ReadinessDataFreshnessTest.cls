@IsTest
private class ReadinessDataFreshnessTest {
    private static Map<String,Object> result(Integer records,Integer recent) {
        return ReadinessDataFreshness.evaluate('approved-v1',90,80,5,System.now(),records,recent);
    }
    @IsTest static void thresholdsAndSuppression() {
        Map<String,Object> measured = result(5,4);
        System.assertEquals('pass',((Map<String,String>)((Map<String,Object>)measured.get('freshness')).get('checks')).get('freshness'));
        System.assertEquals('fail',((Map<String,String>)((Map<String,Object>)result(5,3).get('freshness')).get('checks')).get('freshness'));
        System.assertEquals('cohort_withheld',result(4,4).get('reason'));
        System.assertEquals(null,result(4,4).get('metrics'));
        System.assertEquals('missing_evidence',result(null,null).get('reason'));
        System.assertEquals('readiness_not_established',measured.get('decision'));
    }
    @IsTest static void validatesEvidenceAndPolicy() {
        System.assert(ReadinessDataFreshness.assess(null,90,80,5).contains('invalid_freshness_policy'));
        System.assert(ReadinessDataFreshness.assess('invalid version',90,80,5).contains('invalid_freshness_policy'));
        System.assert(ReadinessDataFreshness.assess('v1',0,80,5).contains('invalid_freshness_policy'));
        System.assert(ReadinessDataFreshness.assess('v1',90,101,5).contains('invalid_freshness_policy'));
        System.assert(ReadinessDataFreshness.assess('v1',90,80,4).contains('invalid_freshness_policy'));
        try {
            result(5,6);
            System.assert(false,'Inconsistent counts must be rejected');
        } catch (IllegalArgumentException expected) {
            System.assertEquals('Invalid freshness evidence',expected.getMessage());
        }
    }
    @IsTest static void utcCalendarAndDateLimits() {
        Datetime instant = Datetime.newInstanceGmt(2026,10,20,0,15,0);
        System.assertEquals(Datetime.newInstanceGmt(2026,10,20,0,0,0),
            ReadinessDataFreshness.utcDay(instant));
        System.assert(ReadinessDataFreshness.assess('v1',2147483647,80,5)
            .contains('invalid_freshness_policy'));
        Datetime firstWindow = Datetime.newInstanceGmt(1,1,2,0,0,0);
        System.assertEquals('missing_evidence',ReadinessDataFreshness.evaluate(
            'v1',1,80,5,firstWindow,null,null).get('reason'));
        try {
            ReadinessDataFreshness.evaluate('v1',2,80,5,firstWindow,null,null);
            System.assert(false,'A window before year one must be rejected');
        } catch (IllegalArgumentException expected) {
            System.assertEquals('Invalid freshness evidence',expected.getMessage());
        }
    }
    @IsTest static void liveReadIsAggregateOnly() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i=0;i<5;i++) contacts.add(new Contact(LastName='Private freshness '+i));
        insert contacts;
        String output = ReadinessDataFreshness.assess('approved-v1',90,80,5);
        Map<String,Object> assessment = (Map<String,Object>)JSON.deserializeUntyped(output);
        System.assertEquals('measured',assessment.get('reason'));
        System.assertEquals(0,((Map<String,Object>)assessment.get('metrics')).get('recent_records'));
        System.assert(!output.contains('Private freshness'));
        System.assertEquals(5,[SELECT COUNT() FROM Contact]);
    }
    private static User minimumAccessUser(String suffix) {
        return new User(ProfileId=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id,
            Username='freshness-'+suffix+'-'+UserInfo.getOrganizationId()+'@example.invalid',
            Email='freshness@example.invalid',LastName='SYNTHETIC freshness',Alias='freshusr',
            TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
    }
    @IsTest static void leastPrivilegeAssessorReadsActivityAggregates() {
        User assessor = minimumAccessUser('assessor');
        insert assessor;
        insert new PermissionSetAssignment(AssigneeId=assessor.Id,
            PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Assessor' LIMIT 1].Id);
        System.runAs(assessor) {
            List<Contact> contacts = new List<Contact>();
            for (Integer i=0;i<5;i++) contacts.add(new Contact(OwnerId=assessor.Id,
                LastName='PRIVATE_FRESHNESS_SENTINEL'));
            // System-mode fixture creation does not grant the read-only assessor writes.
            insert contacts;
            System.assertEquals(true,Contact.SObjectType.getDescribe().isAccessible());
            System.assertEquals(true,Contact.LastActivityDate.getDescribe().isAccessible());
            System.assertEquals(false,Contact.SObjectType.getDescribe().isCreateable());
            String output = ReadinessDataFreshness.assess('approved-v1',90,80,5);
            Map<String,Object> assessment = (Map<String,Object>)JSON.deserializeUntyped(output);
            System.assertEquals('measured',assessment.get('reason'));
            System.assertEquals(5,((Map<String,Object>)assessment.get('metrics')).get('records'));
            System.assertEquals(0,((Map<String,Object>)assessment.get('metrics')).get('recent_records'));
            System.assert(!output.contains('PRIVATE_FRESHNESS_SENTINEL'));
            System.assert(!output.contains('SELECT'));
        }
    }
    @IsTest static void noContactAccessReturnsUnknownEvidence() {
        User restricted = minimumAccessUser('denied');
        insert restricted;
        System.runAs(restricted) {
            System.assertEquals(false,Contact.SObjectType.getDescribe().isAccessible());
            String output = ReadinessDataFreshness.assess('approved-v1',90,80,5);
            Map<String,Object> assessment = (Map<String,Object>)JSON.deserializeUntyped(output);
            System.assertEquals('missing_evidence',assessment.get('reason'));
            System.assertEquals(null,assessment.get('metrics'));
            Map<String,Object> summary = (Map<String,Object>)assessment.get('freshness');
            System.assertEquals('unknown',((Map<String,Object>)summary.get('checks')).get('freshness'));
            System.assertEquals('0.0',summary.get('coverage'));
            System.assert(!output.contains('SELECT'));
        }
    }

}
