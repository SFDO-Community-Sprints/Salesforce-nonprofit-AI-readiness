@IsTest private class ReadinessScopedChecksTest {
    private static Map<String,Object> scope() { return new Map<String,Object>{'groundingFields'=>new List<Object>{'Contact.Email','Contact.AccountId'},'policyApproved'=>true,'policyReference'=>'Approved test policy','minimumCompleteness'=>80,'freshDays'=>365}; }
    private static Map<String,Object> row(List<Object> rows,String id) { for(Object value:rows) if(((Map<String,Object>)value).get('id')=='scope_'+id) return (Map<String,Object>)value;return null; }
    @TestSetup static void setupReader() {
        User reader=new User(Alias='scopeusr',Email='scope@example.invalid',EmailEncodingKey='UTF-8',LastName='Scope Reader',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='GMT',ProfileId=UserInfo.getProfileId(),Username='scope'+System.now().getTime()+'@example.invalid');
        insert reader;
        insert new PermissionSetAssignment(AssigneeId=reader.Id,PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Security_Reader'].Id);
    }
    @IsTest static void inspectsVisibleIdentityAndNeverClaimsRuntime() {
        List<Contact> cohort=new List<Contact>();for(Integer i=0;i<6;i++) cohort.add(new Contact(LastName='Private'));insert cohort;
        User reader=[SELECT Id FROM User WHERE Alias='scopeusr'];
        System.runAs(reader) {
            Map<String,Object> config=scope();config.put('integrationUserId',reader.Id);
            List<Object> rows=ReadinessScopedChecks.collect(config);
            System.assertEquals('pass',row(rows,'identity_active').get('status'));
            System.assertEquals('unknown',row(rows,'runtime').get('status'));
            System.assertNotEquals(null,row(rows,'global_broad'));
            System.assert(String.valueOf(row(rows,'sharing_Contact').get('actual')).startsWith('Internal:'));
            System.assertNotEquals('Guest metadata incomplete or unavailable',row(rows,'guest_Contact').get('actual'));
            config.put('integrationUserId','invalid');
            System.assertEquals('unknown',row(ReadinessScopedChecks.collect(config),'identity_visibility').get('status'));
        }
    }
    @IsTest static void usesCalculatedGroupNotComponentUnion() {
        User reader=[SELECT Id FROM User WHERE Alias='scopeusr'];
        PermissionSet member=new PermissionSet(Name='ScopedGroupMember',Label='Scoped group member'); insert member;
        PermissionSetGroup groupRow=new PermissionSetGroup(DeveloperName='ScopedTestGroup',MasterLabel='Scoped test group'); insert groupRow;
        insert new PermissionSetGroupComponent(PermissionSetGroupId=groupRow.Id,PermissionSetId=member.Id);
        Test.calculatePermissionSetGroup(groupRow.Id);
        insert new PermissionSetAssignment(AssigneeId=reader.Id,PermissionSetGroupId=groupRow.Id);
        System.runAs(reader) {
            Map<String,Object> config=scope();config.put('integrationUserId',reader.Id);
            List<Object> rows=ReadinessScopedChecks.collect(config);
            System.assertEquals('pass',row(rows,'identity_active').get('status'));
            System.assertEquals(null,row(rows,'identity_visibility'),'Setup collector must execute for groups');
            System.assertNotEquals(null,row(rows,'global_broad'),'Calculated aggregate must be used');
        }
    }
    @IsTest static void rejectsUnsafeScopeAndPolicies() {
        Map<String,Object> config=scope();config.put('groundingFields',new List<Object>{'Contact.Email WHERE Name!=null'});
        System.assertEquals('unknown',row(ReadinessScopedChecks.collect(config),'invalid').get('status'));
        config=scope();config.put('minimumCompleteness',101);
        System.assertNotEquals(null,row(ReadinessScopedChecks.collect(config),'invalid'));
        config=scope();config.put('freshDays',0);
        System.assertNotEquals(null,row(ReadinessScopedChecks.collect(config),'invalid'));
    }
    @IsTest static void aggregatesWithoutLeakingOrWriting() {
        List<Contact> contacts=new List<Contact>();
        for(Integer i=0;i<6;i++) contacts.add(new Contact(LastName='Secret sentinel '+i,Email=i<3?'secret@example.invalid':null));
        insert contacts;
        Test.startTest(); Integer before=Limits.getDmlStatements();
        List<Object> result=ReadinessScopedChecks.collect(scope());
        System.assertEquals(before,Limits.getDmlStatements());
        System.assertEquals(0,Limits.getCallouts());
        System.assertEquals('fail',row(result,'complete_Contact_Email').get('status'));
        System.assertEquals('fail',row(result,'duplicates_Contact').get('status'));
        System.assertEquals('pass',row(result,'fresh_Contact').get('status'));
        System.assertEquals('unknown',row(result,'identity').get('status'));
        System.assert(!JSON.serialize(result).contains('secret@example.invalid'));
        System.assert(!JSON.serialize(result).contains('Secret sentinel'));
        Test.stopTest();
    }
    @IsTest static void policyCannotBeBypassedAndSmallValuesSuppressed() {
        List<Contact> contacts=new List<Contact>();for(Integer i=0;i<6;i++) contacts.add(new Contact(LastName='Private',LeadSource='Other',Email=i==0?null:'test'+i+'@example.invalid'));insert contacts;
        Map<String,Object> config=scope();config.put('groundingFields',new List<Object>{'Contact.Email','Contact.AccountId','Contact.LeadSource'});config.put('policyApproved',false);
        List<Object> rows=ReadinessScopedChecks.collect(config);
        System.assertEquals('unknown',row(rows,'complete_Contact_Email').get('status'));
        System.assertEquals('unknown',row(rows,'fresh_Contact').get('status'));
        System.assert(!String.valueOf(row(rows,'complete_Contact_Email').get('actual')).contains('%'));
        config.put('policyApproved',true);config.put('policyReference',' ');
        System.assertEquals('unknown',row(ReadinessScopedChecks.collect(config),'fresh_Contact').get('status'));
        config.put('freshDays',3651);System.assertNotEquals(null,row(ReadinessScopedChecks.collect(config),'invalid'));
        System.assertEquals('unknown',row(rows,'sharing_Contact').get('status'));
        System.assertEquals('unknown',row(rows,'guest_Contact').get('status'));
        System.assertEquals('unknown',row(rows,'similar_Contact').get('status'));
        System.assertEquals('unknown',row(rows,'other_Contact_LeadSource').get('status'));
        System.assert(String.valueOf(row(rows,'other_Contact_LeadSource').get('actual')).contains('6'));
    }
    @IsTest static void smallCohortAndMissingPolicyNeverPass() {
        insert new Contact(LastName='Private');
        System.assertEquals('unknown',row(ReadinessScopedChecks.collect(scope()),'cohort_Contact').get('status'));
        List<Contact> more=new List<Contact>();for(Integer i=0;i<5;i++) more.add(new Contact(LastName='Private',Email='one@example.invalid'));insert more;
        Map<String,Object> config=scope();config.remove('minimumCompleteness');config.remove('freshDays');
        List<Object> rows=ReadinessScopedChecks.collect(config);
        System.assertEquals('unknown',row(rows,'complete_Contact_Email').get('status'));
        System.assertEquals('unknown',row(rows,'fresh_Contact').get('status'));
    }
}
