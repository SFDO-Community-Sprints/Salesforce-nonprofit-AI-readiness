public with sharing class ReadinessDemoScenarios {
    private static final Set<String> SCENARIOS = new Set<String>{'poor','improving','pilot','blocked','unknown'};

    @AuraEnabled
    public static String getScenario(String scenario) {
        if (!SCENARIOS.contains(scenario)) return error('invalid_demo_scenario');
        try {
            // Only fictional snapshots owned by this user are exposed; real reviews remain summary-only.
            List<AI_Readiness_Staff_Review__c> records = [SELECT Snapshot__c
                FROM AI_Readiness_Staff_Review__c WHERE OwnerId = :UserInfo.getUserId()
                AND Version__c = 'demo-scenarios-v1' LIMIT 6];
            if (records.size() > SCENARIOS.size()) return error('demo_scenario_unavailable');
            String result;
            for (AI_Readiness_Staff_Review__c record : records) {
                Map<String,Object> snapshot = (Map<String,Object>)JSON.deserializeUntyped(record.Snapshot__c);
                if (snapshot.get('scenario') != scenario) continue;
                Map<String,Object> assessment = (Map<String,Object>)snapshot.get('assessment');
                if (!snapshot.keySet().equals(new Set<String>{'mode','scenario','assessment','erasure'}) ||
                    snapshot.get('mode') != 'simulation' || assessment == null ||
                    assessment.get('evidence_mode') != 'synthetic_simulation' || result != null) {
                    return error('demo_scenario_unavailable');
                }
                result = JSON.serialize(snapshot);
            }
            return result == null ? error('demo_scenario_unavailable') : result;
        } catch (Exception ignored) {
            return error('demo_scenario_unavailable');
        }
    }
    private static String error(String code) {
        return JSON.serialize(new Map<String,Object>{'error'=>code});
    }
}
