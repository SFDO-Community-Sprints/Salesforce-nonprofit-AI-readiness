@IsTest
private class ReadinessStaffReviewTest {
    @TestSetup static void setupUsers() {
        Id profile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce'
            AND PermissionsModifyAllData = false LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'srview','srdeny','srother','sradmin','srread'}) {
            users.add(new User(Alias=alias, LastName='Fictional Reviewer',
                Email=alias+'@example.invalid', Username=alias+'.'+UserInfo.getOrganizationId()+'.'+Datetime.now().getTime()+'@example.invalid',
                TimeZoneSidKey='Europe/Amsterdam', LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US', ProfileId=profile));
        }
        users[3].ProfileId = [SELECT Id FROM Profile WHERE UserLicense.Name='Salesforce' AND PermissionsModifyAllData=true LIMIT 1].Id;
        insert users;
        Id reviewer = [SELECT Id FROM PermissionSet WHERE Name='Readiness_Staff_Reviewer'].Id;
        Id assessor = [SELECT Id FROM PermissionSet WHERE Name='Readiness_Assessor'].Id;
        Id reader = [SELECT Id FROM PermissionSet WHERE Name='Readiness_Staff_Reader'].Id;
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=reviewer),
            new PermissionSetAssignment(AssigneeId=users[1].Id,PermissionSetId=assessor),
            new PermissionSetAssignment(AssigneeId=users[2].Id,PermissionSetId=reviewer),
            new PermissionSetAssignment(AssigneeId=users[4].Id,PermissionSetId=reader)};
    }
    private static User userFor(String alias) {
        return [SELECT Id FROM User WHERE Alias=:alias LIMIT 1];
    }
    private static Map<String,Object> snapshot() {
        Map<String,Object> key = (Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.getQuestions());
        List<Object> reviews = new List<Object>();
        for (Object value : (List<Object>)key.get('questions')) {
            Map<String,Object> question = (Map<String,Object>)value;
            Map<String,Object> actions = new Map<String,Object>();
            for (Object item : (List<Object>)question.get('required_actions')) {
                actions.put((String)((Map<String,Object>)item).get('id'),'yes');
            }
            reviews.add(new Map<String,Object>{'question_id'=>question.get('id'),'answer'=>'yes',
                'reviewer_confirmed'=>true,'evidence_ref'=>'private_artifact_ref_001','actions'=>actions,
                'critical_failures'=>new List<Object>()});
        }
        return new Map<String,Object>{'version'=>key.get('version'),'mode'=>'actual','reviews'=>reviews};
    }
    private static Map<String,Object> first(Map<String,Object> input) {
        return (Map<String,Object>)((List<Object>)input.get('reviews'))[0];
    }
    @IsTest static void actualCompleteAndOwnReadback() {
        System.runAs(userFor('srview')) {
            System.assertEquals('null',ReadinessStaffReview.getLatestReview());
            String output = ReadinessStaffReview.saveReview(JSON.serialize(snapshot()));
            System.assert(!output.contains('private_artifact_ref_001'));
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(output);
            System.assertEquals('staff_evidence_complete',result.get('decision'));
            System.assertEquals(100,((Map<String,Object>)result.get('staff')).get('score'));
            System.assertEquals(100,((Map<String,Object>)result.get('staff')).get('coverage'));
            System.assert(result.containsKey('reviewed_at'));
            Map<String,Object> readback = (Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.getLatestReview());
            System.assertEquals('reviewer_confirmed_exercises_only',readback.get('scope'));
            System.assertEquals(UserInfo.getUserId(),[SELECT CreatedById FROM AI_Readiness_Staff_Review__c LIMIT 1].CreatedById);
        }
        System.runAs(userFor('srother')) {
            System.assertEquals('null',ReadinessStaffReview.getLatestReview());
            System.assertEquals(0,[SELECT COUNT() FROM AI_Readiness_Staff_Review__c WITH USER_MODE]);
        }
    }
    @IsTest static void permissionCannotBeBypassed() {
        System.runAs(userFor('srdeny')) {
            System.assert(ReadinessStaffReview.saveReview(JSON.serialize(snapshot())).contains('review_not_permitted'));
            String latest = ReadinessStaffReview.getLatestReview();
            System.assertEquals('{"error":"review_not_permitted"}',latest, 'Assessment access alone cannot read staff outcomes');
            System.assert(!latest.contains('private_artifact_ref_001'));
        }
        // Administrator profile alone does not grant the explicit reviewer permission.
        System.runAs(userFor('sradmin')) {
            System.assertEquals('{"error":"review_not_permitted"}',ReadinessStaffReview.getLatestReview());
            System.assert(ReadinessStaffReview.saveReview(JSON.serialize(snapshot())).contains('review_not_permitted'));
        }
    }
    @IsTest static void summaryReaderCannotReadRawEvidenceOrOtherOwners() {
        User reader = userFor('srread');
        Map<String,Object> own = snapshot();
        first(own).put('critical_failures',new List<Object>{'unapproved_decision'});
        own.put('freshness_policy',new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),
            'max_age_days'=>0,'observed_on'=>new Map<String,Object>()});
        insert new List<AI_Readiness_Staff_Review__c>{
            new AI_Readiness_Staff_Review__c(OwnerId=reader.Id,Version__c='staff-readiness-v1',Snapshot__c=JSON.serialize(own)),
            new AI_Readiness_Staff_Review__c(OwnerId=userFor('srview').Id,Version__c='staff-readiness-v1',Snapshot__c=JSON.serialize(snapshot()))};
        System.runAs(reader) {
            System.assert(!AI_Readiness_Staff_Review__c.SObjectType.getDescribe().isAccessible());
            System.assert(!AI_Readiness_Staff_Review__c.Snapshot__c.getDescribe().isAccessible());
            System.assert(!AI_Readiness_Staff_Review__c.Snapshot__c.getDescribe().isCreateable());
            Boolean rawDenied = false;
            try {
                List<AI_Readiness_Staff_Review__c> raw = [SELECT Snapshot__c FROM AI_Readiness_Staff_Review__c WITH USER_MODE];
            } catch (QueryException expected) { rawDenied = true; }
            System.assert(rawDenied,'Summary-only access must not permit raw snapshot queries');
            String output = ReadinessStaffReview.getLatestReview();
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(output);
            System.assertEquals('blocked_by_observed_critical_failure',result.get('decision'));
            System.assert(result.containsKey('freshness'),'Summary reads must preserve age-policy enforcement');
            System.assertEquals(Decimal.valueOf('14.3'),((Map<String,Object>)result.get('staff')).get('coverage'));
            System.assert(!output.contains('private_artifact_ref_001'));
            System.assert(!output.contains('Snapshot__c'));
            System.assert(!output.contains('observed_on'));
            System.assertEquals('{"error":"review_not_permitted"}',ReadinessStaffReview.saveReview(JSON.serialize(snapshot())));
        }
        System.runAs(userFor('srother')) {
            System.assertEquals('null',ReadinessStaffReview.getLatestReview(),'Another owner cannot read these summaries');
        }
    }
    @IsTest static void unknownUnconfirmedAndCriticalParity() {
        Map<String,Object> input = snapshot();
        first(input).put('reviewer_confirmed',false);
        Map<String,Object> result = ReadinessStaffReview.evaluate(input);
        Map<String,Object> staff = (Map<String,Object>)result.get('staff');
        System.assertEquals(Decimal.valueOf('85.7'),staff.get('score'));
        System.assertEquals(Decimal.valueOf('85.7'),staff.get('coverage'));
        first(input).put('reviewer_confirmed',true);
        first(input).put('critical_failures',new List<Object>{'unapproved_decision'});
        result = ReadinessStaffReview.evaluate(input);
        System.assertEquals('blocked_by_observed_critical_failure',result.get('decision'));
        System.assertEquals('Critical',((Map<String,Object>)((List<Object>)result.get('follow_up'))[0]).get('priority'));
        System.assertEquals(100,((Map<String,Object>)result.get('staff')).get('coverage'));
        first(input).put('evidence_ref',null);
        result = ReadinessStaffReview.evaluate(input);
        System.assertEquals('staff_readiness_not_established',result.get('decision'));
        System.assertEquals(0,((List<Object>)result.get('critical_failures')).size());
    }
    @IsTest static void missingActionsAndPartialFailParity() {
        Map<String,Object> input = snapshot();
        ((Map<String,Object>)first(input).get('actions')).remove('identify_scope');
        Map<String,Object> result = ReadinessStaffReview.evaluate(input);
        System.assertEquals('unknown',((Map<String,String>)((Map<String,Object>)result.get('staff')).get('checks')).get('scope'));
        first(input).put('answer','partly');
        result = ReadinessStaffReview.evaluate(input);
        System.assertEquals('fail',((Map<String,String>)((Map<String,Object>)result.get('staff')).get('checks')).get('scope'));
        System.assertEquals('High',((Map<String,Object>)((List<Object>)result.get('follow_up'))[0]).get('priority'));
    }
    @IsTest static void pythonParityCorpus() {
        List<Object> cases = (List<Object>)JSON.deserializeUntyped([SELECT Body FROM StaticResource
            WHERE Name='StaffReadinessParity' LIMIT 1].Body.toString());
        for (Object value : cases) {
            Map<String,Object> fixture = (Map<String,Object>)value;
            String label = (String)fixture.get('name');
            Map<String,Object> actual = ReadinessStaffReview.evaluate((Map<String,Object>)fixture.get('snapshot'));
            Map<String,Object> expected = (Map<String,Object>)fixture.get('expected');
            Map<String,Object> actualStaff = (Map<String,Object>)actual.get('staff');
            Map<String,Object> expectedStaff = (Map<String,Object>)expected.get('staff');
            System.assertEquals(Decimal.valueOf((String)expectedStaff.get('score')),actualStaff.get('score'),label);
            System.assertEquals(Decimal.valueOf((String)expectedStaff.get('coverage')),actualStaff.get('coverage'),label);
            System.assertEquals(expectedStaff.get('passed'),actualStaff.get('passed'),label);
            System.assertEquals(expectedStaff.get('applicable'),actualStaff.get('applicable'),label);
            Map<String,Object> expectedChecks = (Map<String,Object>)expectedStaff.get('checks');
            Map<String,String> actualChecks = (Map<String,String>)actualStaff.get('checks');
            for (String qid : expectedChecks.keySet()) System.assertEquals(expectedChecks.get(qid),actualChecks.get(qid),label+qid);
            System.assertEquals(expected.get('decision'),actual.get('decision'),label);
            System.assertEquals(JSON.serialize(expected.get('critical_failures')),JSON.serialize(actual.get('critical_failures')),label);
            List<Object> actualFollow = (List<Object>)actual.get('follow_up');
            List<Object> expectedFollow = (List<Object>)expected.get('follow_up');
            System.assertEquals(expectedFollow.size(),actualFollow.size(),label);
            for (Integer i=0; i<expectedFollow.size(); i++) {
                Map<String,Object> wanted=(Map<String,Object>)expectedFollow[i];
                Map<String,Object> found=(Map<String,Object>)actualFollow[i];
                for (String field : wanted.keySet()) System.assertEquals(wanted.get(field),found.get(field),label+field);
            }
        }
    }
    @IsTest static void nativeFreshnessSaveAndDynamicReadback() {
        System.runAs(userFor('srview')) {
            Map<String,Object> input = snapshot();
            input.put('freshness_policy',new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),
                'max_age_days'=>30,'observed_on'=>new Map<String,Object>{
                    'scope'=>String.valueOf(Date.today().addDays(-30)),
                    'sensitive_data'=>String.valueOf(Date.today().addDays(-31))}});
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.saveReview(JSON.serialize(input)));
            System.assertEquals('staff_readiness_not_established',result.get('decision'));
            Map<String,Object> checks = (Map<String,Object>)((Map<String,Object>)result.get('staff')).get('checks');
            System.assertEquals('pass',checks.get('scope'));
            System.assertEquals('unknown',checks.get('sensitive_data'));
            System.assertEquals('unknown',checks.get('quality'));
            System.assertEquals('saved_review_reassessed_today',((Map<String,Object>)result.get('freshness')).get('scope'));
            System.assert(!JSON.serialize(result).contains('private_artifact_ref'));
            System.assert(!JSON.serialize(result).contains('observed_on'));

            // Retain the old policy date to prove retrieval uses today's date, not the stored assessment date.
            AI_Readiness_Staff_Review__c saved = [SELECT Snapshot__c FROM AI_Readiness_Staff_Review__c LIMIT 1];
            Map<String,Object> policy = (Map<String,Object>)input.get('freshness_policy');
            policy.put('as_of',String.valueOf(Date.today().addDays(-1)));
            policy.put('max_age_days',0);
            policy.put('observed_on',new Map<String,Object>{'scope'=>String.valueOf(Date.today().addDays(-1))});
            saved.Snapshot__c = JSON.serialize(input); update saved;
            result = (Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.getLatestReview());
            checks = (Map<String,Object>)((Map<String,Object>)result.get('staff')).get('checks');
            System.assertEquals('unknown',checks.get('scope'));
            System.assertEquals(String.valueOf(Date.today()),((Map<String,Object>)result.get('freshness')).get('as_of'));
            System.assertEquals(JSON.serialize(input),[SELECT Snapshot__c FROM AI_Readiness_Staff_Review__c LIMIT 1].Snapshot__c);
        }
    }
    @IsTest static void invalidNativeFreshnessFailsClosed() {
        System.runAs(userFor('srview')) {
            List<Map<String,Object>> policies = new List<Map<String,Object>>{
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today().addDays(-1)),'max_age_days'=>30,'observed_on'=>new Map<String,Object>()},
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),'max_age_days'=>-1,'observed_on'=>new Map<String,Object>()},
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),'max_age_days'=>true,'observed_on'=>new Map<String,Object>()},
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),'max_age_days'=>30,'observed_on'=>new Map<String,Object>{'scope'=>String.valueOf(Date.today().addDays(1))}},
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),'max_age_days'=>30,'observed_on'=>new Map<String,Object>{'unknown'=>'2026-01-01'}},
                new Map<String,Object>{'as_of'=>String.valueOf(Date.today()),'max_age_days'=>30,'observed_on'=>new Map<String,Object>{'scope'=>'2026-02-30'}}};
            for (Map<String,Object> policy : policies) {
                Map<String,Object> input = snapshot(); input.put('freshness_policy',policy);
                System.assert(ReadinessStaffReview.saveReview(JSON.serialize(input)).contains('review_unavailable'));
            }
            System.assertEquals(0,[SELECT COUNT() FROM AI_Readiness_Staff_Review__c]);
        }
    }
    @IsTest static void invalidEvidenceIsAtomicAndSanitized() {
        System.runAs(userFor('srview')) {
            List<Map<String,Object>> invalid = new List<Map<String,Object>>();
            Map<String,Object> value = snapshot(); value.put('mode','simulation'); invalid.add(value);
            value=snapshot();value.remove('mode');invalid.add(value);
            value=snapshot();value.put('version','wrong');invalid.add(value);
            value=snapshot();first(value).put('evidence_ref','FICTIONAL-sensitive@example.invalid');invalid.add(value);
            value=snapshot();first(value).put('raw','FICTIONAL-sensitive@example.invalid');invalid.add(value);
            value=snapshot();((List<Object>)value.get('reviews')).add(first(value));invalid.add(value);
            value=snapshot();((Map<String,Object>)first(value).get('actions')).put('arbitrary','yes');invalid.add(value);
            for (Map<String,Object> input : invalid) {
                String output=ReadinessStaffReview.saveReview(JSON.serialize(input));
                System.assert(output.contains('review_unavailable'));
                System.assert(!output.contains('FICTIONAL-sensitive'));
            }
            String oversized = 'x';
            while (oversized.length() <= 32768) oversized += oversized;
            System.assertEquals('{"error":"review_unavailable"}',ReadinessStaffReview.saveReview(oversized));
            System.assertEquals(0,[SELECT COUNT() FROM AI_Readiness_Staff_Review__c WITH USER_MODE]);
        }
    }
}
