@IsTest
private class ReadinessDemoScenariosTest {
    private static AI_Readiness_Staff_Review__c row(String scenario, String mode, String evidenceMode) {
        return new AI_Readiness_Staff_Review__c(Version__c='demo-scenarios-v1', Snapshot__c=JSON.serialize(
            new Map<String,Object>{'mode'=>mode,'scenario'=>scenario,
                'assessment'=>new Map<String,Object>{'evidence_mode'=>evidenceMode},
                'erasure'=>new Map<String,Object>{'decision'=>'not_assessed'}}));
    }
    @IsTest static void ownScenarioOnlyAndInvalidInputs() {
        insert row('pilot','simulation','synthetic_simulation');
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(ReadinessDemoScenarios.getScenario('pilot'));
        System.assertEquals('pilot',result.get('scenario'));
        System.assertEquals('simulation',result.get('mode'));
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('poor'));
        for (String invalid : new List<String>{null,'','Pilot','arbitrary'}) {
            System.assertEquals('{"error":"invalid_demo_scenario"}',ReadinessDemoScenarios.getScenario(invalid));
        }
    }
    @IsTest static void duplicatesFailClosed() {
        insert new List<AI_Readiness_Staff_Review__c>{row('pilot','simulation','synthetic_simulation'),
            row('pilot','simulation','synthetic_simulation')};
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
    }
    @IsTest static void realAndMalformedSnapshotsFailClosed() {
        AI_Readiness_Staff_Review__c record = row('pilot','actual','synthetic_simulation');
        insert record;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
        record.Snapshot__c = row('pilot','simulation','reviewer_confirmed_observations').Snapshot__c;
        update record;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
        record.Snapshot__c = '{invalid'; update record;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
        record.Snapshot__c = row('pilot','simulation','synthetic_simulation').Snapshot__c;
        record.Version__c = 'staff-readiness-v1'; update record;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
    }
    @IsTest static void unexpectedPayloadAndExcessRowsFailClosed() {
        AI_Readiness_Staff_Review__c record = row('pilot','simulation','synthetic_simulation');
        Map<String,Object> payload = (Map<String,Object>)JSON.deserializeUntyped(record.Snapshot__c);
        payload.put('raw_staff_evidence','private'); record.Snapshot__c=JSON.serialize(payload);
        insert record;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
        delete record;
        List<AI_Readiness_Staff_Review__c> duplicates = new List<AI_Readiness_Staff_Review__c>();
        for (Integer i=0; i<6; i++) duplicates.add(row('poor','simulation','synthetic_simulation'));
        insert duplicates;
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('poor'));
    }
    @IsTest static void anotherOwnersSnapshotIsNeverReturned() {
        User other = new User(Alias='demouser', LastName='Fictional Demo',
            Email='demo@example.invalid', Username='demo.'+UserInfo.getOrganizationId()+'.'+Datetime.now().getTime()+'@example.invalid',
            TimeZoneSidKey='Europe/Amsterdam', LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US', ProfileId=UserInfo.getProfileId());
        insert other;
        System.runAs(other) { insert row('pilot','simulation','synthetic_simulation'); }
        // Even an administrator's sharing override must not bypass explicit ownership.
        System.assertEquals('{"error":"demo_scenario_unavailable"}',ReadinessDemoScenarios.getScenario('pilot'));
    }
}
