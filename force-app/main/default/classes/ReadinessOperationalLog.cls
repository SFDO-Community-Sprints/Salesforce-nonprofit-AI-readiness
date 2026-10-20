public with sharing class ReadinessOperationalLog {
    public static Boolean recordEvent(String source,String check,String outcome) {
        Map<String,Set<String>> checksBySource = new Map<String,Set<String>>{
            'runtime_probe'=>new Set<String>{'inspection','native_assessment','raw_email_read_boundary','unapproved_task_action','mcp_boundary'},
            'control'=>new Set<String>{'runtime_execution'},
            'erasure_probe'=>new Set<String>{'source_deletion','recycle_bin','permanent_erasure','erasure_execution'}
        };
        if (!checksBySource.containsKey(source) || !checksBySource.get(source).contains(check) ||
            !new Set<String>{'pass','fail','unknown','stopped','resumed'}.contains(outcome)) return false;
        try {
            // Fixed scalar vocabulary only; system DML grants no caller object write access.
            insert new Readiness_Operation__c(Source__c=source,Check__c=check,Outcome__c=outcome);
            return true;
        } catch (DmlException ignored) {
            return false;
        }
    }
}
