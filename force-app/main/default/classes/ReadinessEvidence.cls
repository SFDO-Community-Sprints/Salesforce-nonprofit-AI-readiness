public with sharing class ReadinessEvidence {
    private static final List<String> CATEGORIES = new List<String>{'salesforce','integrations','logs','backups','exports'};
    private static final Map<String,List<String>> REQUIRED = new Map<String,List<String>>{'salesforce'=>new List<String>{'active_read_absent','recycle_bin_absent','agent_output_absent','retention_approval'},
'integrations'=>new List<String>{'destination_absent','sync_no_reintroduction','retention_approval'},
'logs'=>new List<String>{'stored_log_absent','new_log_no_reappearance','retention_approval'},
'backups'=>new List<String>{'restore_no_reintroduction','retention_approval'},
'exports'=>new List<String>{'export_copy_absent','retention_approval'}};
    private static final Map<String,List<String>> ACTIONS = new Map<String,List<String>>{'destination_inventory'=>new List<String>{'Privacy lead','List the systems and copies that receive this information, and name an owner for each.'},
'active_read_absent'=>new List<String>{'Salesforce admin','Check that erased information no longer appears in active Salesforce records.'},
'recycle_bin_absent'=>new List<String>{'Salesforce admin','Review approved deletion from the Recycle Bin and confirm what remains recoverable.'},
'agent_output_absent'=>new List<String>{'AI service owner','Stop affected agent use and check that erased information cannot appear in agent answers.'},
'retention_approval'=>new List<String>{'Privacy lead','Document which information may be retained, why, for how long and who approved it.'},
'destination_absent'=>new List<String>{'Integration owner','Check that the connected service removed the information covered by the request.'},
'sync_no_reintroduction'=>new List<String>{'Integration owner','Test the next synchronization and prevent erased information from being copied back.'},
'stored_log_absent'=>new List<String>{'Operations owner','Review retained logs and apply the approved removal or retention procedure.'},
'new_log_no_reappearance'=>new List<String>{'Operations owner','Test new activity and ensure erased information is not written into logs again.'},
'restore_no_reintroduction'=>new List<String>{'Backup owner','Rehearse an approved restore with fictional records and prevent erased information from becoming active again.'},
'export_copy_absent'=>new List<String>{'Data owner','Locate exported copies, contact their owners and verify the approved removal or retention outcome.'}};
    private static final List<String> TECH = new List<String>{'prerequisites','runtime_access','approval','export_block','stop_control'};
    private class InvalidEvidenceException extends Exception {}
    private static void require(Boolean valid) {
        if (!valid) throw new InvalidEvidenceException('Invalid evidence inventory');
    }
    private static Map<String,Object> objectValue(Object value) {
        require(value instanceof Map<String,Object>);
        return (Map<String,Object>)value;
    }
    private static List<Object> arrayValue(Object value) {
        require(value instanceof List<Object>);
        return (List<Object>)value;
    }
    private static void fields(Map<String,Object> value, Set<String> expected) {
        require(value.keySet().equals(expected));
    }
    private static Boolean identifier(Object value) {
        return value instanceof String && Pattern.matches('[a-z][a-z0-9_-]{0,79}', (String)value);
    }
    private static Map<String,Object> inventory(String input, String empty) {
        return objectValue(JSON.deserializeUntyped(String.isBlank(input) ? empty : input));
    }
    private static void requireReviewer() {
        if (!FeatureManagement.checkPermission('Readiness_Review_Evidence')) {
            throw new AuraHandledException('Readiness evidence review permission is required.');
        }
    }
    @AuraEnabled
    public static String evaluateErasure(String inventoryJson) {
        requireReviewer();
        try { return JSON.serialize(erasure(inventory(inventoryJson,'{"mode":"actual","systems":[],"evidence":[]}'))); }
        catch (Exception e) { throw new AuraHandledException('Invalid erasure evidence inventory'); }
    }
    public static Map<String,Object> erasure(Map<String,Object> input) {
        fields(input,new Set<String>{'mode','systems','evidence'});
        String mode=(String)input.get('mode');
        require(mode=='actual' || mode=='simulation');
        Map<String,String> systems=new Map<String,String>();
        List<String> orderedIds=new List<String>();
        for(Object raw:arrayValue(input.get('systems'))) {
            Map<String,Object> destination=objectValue(raw);
            Set<String> keys=new Set<String>{'id','category'};
            if(mode=='actual') keys.addAll(new Set<String>{'destination_ref','owner_ref','retention_policy_ref','privacy_approver_ref'});
            fields(destination,keys);
            require(identifier(destination.get('id')) && destination.get('category') instanceof String);
            String id=(String)destination.get('id'), category=(String)destination.get('category');
            require(REQUIRED.containsKey(category) && !systems.containsKey(id));
            if(mode=='actual') for(String key:keys) if(key!='category') require(identifier(destination.get(key)));
            systems.put(id,category); orderedIds.add(id);
        }
        Map<String,String> evidence=new Map<String,String>();
        for(Object raw:arrayValue(input.get('evidence'))) {
            Map<String,Object> item=objectValue(raw);
            fields(item,new Set<String>{'system_id','probe_id','result','evidence_ref','reviewer_ref'});
            for(String key:new List<String>{'system_id','probe_id','evidence_ref','reviewer_ref'}) require(identifier(item.get(key)));
            require(item.get('result') instanceof String);
            String id=(String)item.get('system_id'),probe=(String)item.get('probe_id'),result=(String)item.get('result');
            String key=id+':'+probe;
            require(systems.containsKey(id) && REQUIRED.get(systems.get(id)).contains(probe));
            require((result=='observed' || result=='failed') && !evidence.containsKey(key));
            evidence.put(key,(mode=='actual'?'reported_':'simulated_')+result);
        }
        List<Map<String,Object>> checks=new List<Map<String,Object>>();
        for(String category:CATEGORIES) {
            Boolean found=false;
            for(String id:orderedIds) if(systems.get(id)==category) {
                found=true;
                for(String probe:REQUIRED.get(category)) checks.add(new Map<String,Object>{'category'=>category,'system_id'=>id,'probe_id'=>probe,
                    'status'=>evidence.containsKey(id+':'+probe)?evidence.get(id+':'+probe):'unknown'});
            }
            if(!found) checks.add(new Map<String,Object>{'category'=>category,'system_id'=>null,'probe_id'=>'destination_inventory','status'=>'unknown'});
        }
        List<Map<String,Object>> high=new List<Map<String,Object>>(),medium=new List<Map<String,Object>>();
        Integer observed=0,failed=0,simulatedFailed=0,unknown=0;
        for(Map<String,Object> check:checks) {
            String status=(String)check.get('status'),probe=(String)check.get('probe_id');
            if(status=='reported_observed') observed++;
            if(status=='reported_failed') failed++;
            if(status=='simulated_failed') simulatedFailed++;
            if(status=='unknown') unknown++;
            if(status=='unknown' || status.endsWith('_failed')) {
                Boolean isHigh=status.endsWith('_failed') || probe=='destination_inventory';
                Map<String,Object> follow=new Map<String,Object>(check);
                follow.put('priority',isHigh?'High':'Medium'); follow.put('owner',ACTIONS.get(probe)[0]); follow.put('action',ACTIONS.get(probe)[1]);
                follow.put('basis',status=='simulated_failed'?'fictional_failure':status=='reported_failed'?'reported_failure':'missing_evidence');
                if(isHigh) high.add(follow); else medium.add(follow);
            }
        }
        high.addAll(medium);
        return new Map<String,Object>{'version'=>'erasure-evidence-coverage-v1','mode'=>mode,'decision'=>'not_assessed',
            'independently_verified'=>false,'required_checks'=>checks.size(),'reported_observations'=>observed,'reported_failures'=>failed,
            'simulated_failures'=>simulatedFailed,'follow_ups'=>high,'unknown_checks'=>unknown,'checks'=>checks,
            'limitation'=>'Coverage only. References and reviewers are reported, not independently verified. Actual destinations, retention decisions, executable probes and restore/sync tests must be verified before assessing end-to-end erasure; no compliance conclusion is made.'};
    }
    @AuraEnabled
    public static String evaluateSafeguards(String evidenceJson) {
        requireReviewer();
        try { return JSON.serialize(safeguards(inventory(evidenceJson,'{"mode":"actual","evidence":[]}'))); }
        catch(Exception e) { throw new AuraHandledException('Invalid safeguard evidence inventory'); }
    }
    public static Map<String,Object> safeguards(Map<String,Object> input) {
        fields(input,new Set<String>{'mode','evidence'});
        String mode=(String)input.get('mode'); require(mode=='actual' || mode=='simulation');
        Map<String,String> evidence=new Map<String,String>();
        for(Object raw:arrayValue(input.get('evidence'))) {
            Map<String,Object> item=objectValue(raw);
            fields(item,new Set<String>{'check_id','result','evidence_ref','reviewer_ref'});
            for(String key:new List<String>{'check_id','evidence_ref','reviewer_ref'}) require(identifier(item.get(key)));
            String id=(String)item.get('check_id');
            require(TECH.contains(id) && !evidence.containsKey(id));
            require(item.get('result') instanceof String);
            String result=(String)item.get('result'); require(result=='pass' || result=='fail');
            evidence.put(id,result);
        }
        Map<String,String> reportedChecks=new Map<String,String>();
        Integer passed=0,completed=0;
        Boolean critical=false;
        for(String key:TECH) {
            String status=evidence.containsKey(key)?evidence.get(key):'unknown';
            reportedChecks.put(key,status=='unknown'?'unknown':(mode=='actual'?'reported_':'simulated_')+status);
            if(status=='pass') passed++;
            if(status!='unknown') completed++;
            if(key!='prerequisites' && status=='fail') critical=true;
        }
        return new Map<String,Object>{'version'=>'donor-summary-demo-v1','mode'=>mode,'checks'=>reportedChecks,
            'passed'=>passed,'applicable'=>5,'score'=>(Decimal.valueOf(String.valueOf(passed))*20).setScale(1),
            'coverage'=>(Decimal.valueOf(String.valueOf(completed))*20).setScale(1),
            'decision'=>'not_assessed','independently_verified'=>false,
            'priority'=>critical?'Critical':completed<5 || passed<5?'High':null,
            'limitation'=>'Reported or simulated evidence only; no independent runtime control verification or organization readiness conclusion.'};
    }
}
