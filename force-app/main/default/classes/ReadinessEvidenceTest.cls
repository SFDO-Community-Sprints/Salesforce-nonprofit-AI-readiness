@IsTest
private class ReadinessEvidenceTest {
    @TestSetup static void grantReviewer() {
        User reviewer=new User(Alias='evreview',Email='fictional@example.invalid',EmailEncodingKey='UTF-8',
            LastName='Evidence Reviewer',LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId=UserInfo.getProfileId(),
            TimeZoneSidKey='America/Los_Angeles',Username='evidence-reviewer-'+DateTime.now().getTime()+'@example.invalid');
        insert reviewer;
        PermissionSet role=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Evidence_Reviewer' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId=reviewer.Id,PermissionSetId=role.Id);
    }
    @IsTest static void reviewerPermissionIsRequired() {
        Profile profile=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1];
        String suffix=String.valueOf(DateTime.now().getTime());
        User reader=new User(Alias='evreader',Email='fictional@example.invalid',EmailEncodingKey='UTF-8',
            LastName='Evidence Reader',LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId=profile.Id,
            TimeZoneSidKey='America/Los_Angeles',Username='evidence-reader-'+suffix+'@example.invalid');
        insert reader;
        System.runAs(reader) {
            Boolean denied=false;
            try { ReadinessEvidence.evaluateErasure(null); } catch(AuraHandledException e) { denied=true; }
            System.assert(denied);
            denied=false;
            try { ReadinessEvidence.evaluateSafeguards(null); } catch(AuraHandledException e) { denied=true; }
            System.assert(denied);
        }
    }
    private static String apiErasure(String input) {
        String output;
        User reviewer = [SELECT Id FROM User WHERE Alias='evreview' LIMIT 1];
        System.runAs(reviewer) { output=ReadinessEvidence.evaluateErasure(input); }
        return output;
    }
    private static String apiSafeguards(String input) {
        String output;
        User reviewer = [SELECT Id FROM User WHERE Alias='evreview' LIMIT 1];
        System.runAs(reviewer) { output=ReadinessEvidence.evaluateSafeguards(input); }
        return output;
    }
    @IsTest static void pythonFixturesMatchNativeScorers() {
        List<Object> cases=(List<Object>)JSON.deserializeUntyped([SELECT Body FROM StaticResource WHERE Name='ReadinessEvidenceParity' LIMIT 1].Body.toString());
        for(Object raw:cases) {
            Map<String,Object> item=(Map<String,Object>)raw;
            String input=JSON.serialize(item.get('input'));
            Map<String,Object> expected=(Map<String,Object>)item.get('expected');
            if(item.get('kind')=='erasure') {
                System.assertEquals(expected,JSON.deserializeUntyped(apiErasure(input)),(String)item.get('name'));
            } else {
                Map<String,Object> actual=(Map<String,Object>)JSON.deserializeUntyped(apiSafeguards(input));
                for(String key:new List<String>{'score','coverage'}) System.assertEquals(Decimal.valueOf((String)expected.get(key)),actual.get(key),(String)item.get('name'));
                for(String key:new List<String>{'passed','applicable'}) System.assertEquals(expected.get(key),actual.get(key));
                System.assertEquals('not_assessed',actual.get('decision'));
            }
        }
    }
    private static Map<String,Object> erasure(String mode) {
        Map<String,List<String>> probes=new Map<String,List<String>>{
            'salesforce'=>new List<String>{'active_read_absent','recycle_bin_absent','agent_output_absent','retention_approval'},
            'integrations'=>new List<String>{'destination_absent','sync_no_reintroduction','retention_approval'},
            'logs'=>new List<String>{'stored_log_absent','new_log_no_reappearance','retention_approval'},
            'backups'=>new List<String>{'restore_no_reintroduction','retention_approval'},
            'exports'=>new List<String>{'export_copy_absent','retention_approval'}};
        List<Object> systems=new List<Object>(),evidence=new List<Object>();
        for(String category:probes.keySet()) {
            Map<String,Object> item=new Map<String,Object>{'id'=>category,'category'=>category};
            if(mode=='actual') item.putAll(new Map<String,Object>{'destination_ref'=>'registry_entry','owner_ref'=>'system_owner',
                'retention_policy_ref'=>'approved_policy','privacy_approver_ref'=>'privacy_lead'});
            systems.add(item);
            for(String probe:probes.get(category)) evidence.add(new Map<String,Object>{'system_id'=>category,'probe_id'=>probe,
                'result'=>'observed','evidence_ref'=>'run_01','reviewer_ref'=>'reviewer_01'});
        }
        return new Map<String,Object>{'mode'=>mode,'systems'=>systems,'evidence'=>evidence};
    }
    @IsTest static void allObservationsAreStillUnverified() {
        Map<String,Object> result=ReadinessEvidence.erasure(erasure('actual'));
        System.assertEquals('not_assessed',result.get('decision'));
        System.assertEquals(false,result.get('independently_verified'));
        System.assertEquals(14,result.get('reported_observations'));
        System.assertEquals(0,result.get('unknown_checks'));
        System.assertEquals(0,((List<Map<String,Object>>)result.get('follow_ups')).size());
        System.assert(!JSON.serialize(result).contains('registry_entry'));
        System.assert(!JSON.serialize(result).contains('reviewer_01'));
    }
    @IsTest static void simulationCannotBecomeActual() {
        Map<String,Object> input=erasure('simulation');
        Map<String,Object> result=ReadinessEvidence.erasure(input);
        System.assertEquals(0,result.get('reported_observations'));
        for(Map<String,Object> check:(List<Map<String,Object>>)result.get('checks')) System.assertEquals('simulated_observed',check.get('status'));
        input.put('mode','actual');
        assertInvalid(input);
    }
    @IsTest static void unknownDestinationsAndFailuresHavePriorities() {
        Map<String,Object> empty=(Map<String,Object>)JSON.deserializeUntyped(apiErasure(null));
        System.assertEquals(5,empty.get('unknown_checks'));
        System.assertEquals(5,((List<Object>)empty.get('follow_ups')).size());
        Map<String,Object> input=erasure('simulation');
        for(Object raw:(List<Object>)input.get('evidence')) ((Map<String,Object>)raw).put('result','failed');
        Map<String,Object> result=ReadinessEvidence.erasure(input);
        System.assertEquals(14,result.get('simulated_failures'));
        System.assertEquals(0,result.get('reported_failures'));
        for(Map<String,Object> follow:(List<Map<String,Object>>)result.get('follow_ups')) {
            System.assertEquals('High',follow.get('priority'));
            System.assertEquals('fictional_failure',follow.get('basis'));
        }
    }
    @IsTest static void referencesMustBeCanonicalAndProbesUnique() {
        Map<String,Object> input=erasure('actual');
        List<Object> items=(List<Object>)input.get('evidence');
        items.add(items[0]); assertInvalid(input);
        input=erasure('actual');
        ((Map<String,Object>)((List<Object>)input.get('evidence'))[0]).put('evidence_ref','person@example.invalid'); assertInvalid(input);
        input=erasure('actual');
        ((Map<String,Object>)((List<Object>)input.get('systems'))[0]).remove('owner_ref'); assertInvalid(input);
        input=erasure('actual'); input.put('raw','personal content'); assertInvalid(input);
        input=erasure('actual');
        ((Map<String,Object>)((List<Object>)input.get('evidence'))[0]).put('result',true); assertInvalid(input);
    }
    private static void assertInvalid(Map<String,Object> input) {
        Boolean rejected=false;
        try { apiErasure(JSON.serialize(input)); }
        catch(AuraHandledException e) { rejected=true; System.assert(!e.getMessage().contains('person@')); }
        System.assert(rejected,'Invalid or sensitive inventory must be rejected');
    }
    @IsTest static void evidenceForOneDestinationCannotCoverAnother() {
        Map<String,Object> input=erasure('actual');
        ((List<Object>)input.get('systems')).add(new Map<String,Object>{'id'=>'second_integration','category'=>'integrations',
            'destination_ref'=>'other_destination','owner_ref'=>'owner','retention_policy_ref'=>'policy','privacy_approver_ref'=>'approver'});
        Map<String,Object> result=ReadinessEvidence.erasure(input);
        System.assertEquals(3,result.get('unknown_checks'));
        System.assertEquals(14,result.get('reported_observations'));
    }
    @IsTest static void safeguardsKeepSimulationAndCriticalFailuresSeparate() {
        Map<String,Object> empty=(Map<String,Object>)JSON.deserializeUntyped(apiSafeguards(''));
        System.assertEquals(0,empty.get('coverage'));
        System.assertEquals('not_assessed',empty.get('decision'));
        List<Object> evidence=new List<Object>();
        for(String key:new List<String>{'prerequisites','runtime_access','approval','export_block','stop_control'}) {
            evidence.add(new Map<String,Object>{'check_id'=>key,'result'=>'pass','evidence_ref'=>'run_01','reviewer_ref'=>'reviewer_01'});
        }
        Map<String,Object> input=new Map<String,Object>{'mode'=>'actual','evidence'=>evidence};
        Map<String,Object> result=ReadinessEvidence.safeguards(input);
        System.assertEquals(Decimal.valueOf('100.0'),result.get('score'));
        System.assertEquals('reported_pass',((Map<String,String>)result.get('checks')).get('runtime_access'));
        System.assertEquals(false,result.get('independently_verified'));
        System.assertEquals('not_assessed',result.get('decision'));
        ((Map<String,Object>)evidence[1]).put('result','fail');
        input.put('mode','simulation'); result=ReadinessEvidence.safeguards(input);
        System.assertEquals('Critical',result.get('priority'));
        System.assertEquals('simulated_fail',((Map<String,String>)result.get('checks')).get('runtime_access'));
        evidence.add(evidence[0]);
        Boolean rejected=false;
        try { apiSafeguards(JSON.serialize(input)); } catch(AuraHandledException e) { rejected=true; }
        System.assert(rejected);
    }
}
