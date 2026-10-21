public with sharing class ReadinessRuntimeProbe {
    @AuraEnabled
    public static String inspect() {
        List<Object> checks = new List<Object>();
        Boolean contactRead = Schema.sObjectType.Contact.isAccessible();
        Boolean emailRead = Schema.sObjectType.Contact.fields.Email.isAccessible();
        checks.add(row('contact_read','Contact object read',contactRead ? 'pass' : 'fail','Current principal describe: Contact.isAccessible().'));
        checks.add(row('email_read','Contact email field read',emailRead ? 'pass' : 'fail','Current principal describe: Contact.Email.isAccessible().'));
        try {
            Map<String,Object> nativeResult = parse(NonprofitAIReadiness.assessScenario('organization'));
            checks.add(row('native_assessment','Native assessment execution',nativeResult.containsKey('error') ? 'fail' : (aggregateShape(nativeResult) ? 'pass' : 'fail'),
                'Executed organization assessment as the current principal; response checked for aggregate metrics/privacy contract. Staff results may cover only this principal.'));
        } catch (Exception ignored) {
            checks.add(row('native_assessment','Native assessment execution','fail','Assessment call failed; exception details withheld.'));
        }
        if (!contactRead || !emailRead) {
            Boolean denied = false;
            try {
                List<Contact> raw = [SELECT Email FROM Contact WITH USER_MODE LIMIT 1];
            } catch (QueryException ignored) { denied = true; }
            checks.add(row('raw_email_read_boundary','User-mode raw email boundary',denied ? 'pass' : 'fail',
                'Executed SELECT Email WITH USER_MODE where describe denied object or field access. No values returned by this probe.'));
        } else {
            checks.add(row('raw_email_read_boundary','User-mode raw email boundary','unknown',
                'Current principal has email read access; no denial is expected. A separately bound restricted identity is required.'));
        }
        if (!FeatureManagement.checkPermission('Readiness_Create_Follow_Up')) {
            Integer beforeDml = Limits.getDmlStatements();
            Map<String,Object> result = parse(NonprofitAIReadiness.createFollowUpTasks());
            Boolean denied = result.get('error') == 'task_creation_unavailable' && Limits.getDmlStatements() == beforeDml;
            checks.add(row('unapproved_task_action','Denied task action',denied ? 'pass' : 'fail',
                'Invoked follow-up action without its custom permission; verified sanitized denial and zero DML statements.'));
        } else {
            checks.add(row('unapproved_task_action','Denied task action','unknown',
                'Current principal has task-action permission; write action was deliberately not executed. Bind a restricted actor and approval workflow.'));
        }
        ReadinessMCP.Request request = new ReadinessMCP.Request();
        request.scenario = 'organization';
        try {
            Map<String,Object> result = parse(ReadinessMCP.assess(new List<ReadinessMCP.Request>{request})[0].output);
            Boolean permitted = FeatureManagement.checkPermission('Readiness_Run_MCP_Assessment');
            Boolean valid = permitted ? aggregateShape(result) && !result.containsKey('staff_review') && !result.containsKey('staff_summary')
                : result.size() == 1 && result.get('error') == 'assessment_unavailable';
            checks.add(row('mcp_boundary','Fixed MCP facade execution',valid ? 'pass' : 'fail',permitted
                ? 'Executed fixed organization facade and verified aggregate contract and absence of staff response keys. This does not test arbitrary APIs.'
                : 'Executed fixed facade without its permission and observed sanitized denial.'));
        } catch (Exception ignored) {
            checks.add(row('mcp_boundary','Fixed MCP facade execution','fail','Facade call failed; exception details withheld.'));
        }
        List<Object> gaps = new List<Object>{
            gap('assistant_identity','Intended assistant identity','Bind and execute these checks as the actual deployed assistant principal; current user results cannot certify another identity.'),
            gap('consequential_approval','Consequential action approval','Bind an actual consequential action and its approval workflow, then execute denied and approved cases in an isolated test org.'),
            gap('stop_recovery','Stop and recovery','Bind the deployed agent/session stop mechanism and recovery target; execute and observe interruption and recovery.'),
            gap('monitoring','Monitoring and intervention','Bind the actual runtime trace and alert sink; exercise a rejected action and verify the recorded event and human intervention.'),
            gap('export_surface','Export and external tools','Bind all exposed APIs and external tools for the intended assistant; this fixed-facade check cannot establish universal export denial.')
        };
        Boolean recorded = ReadinessOperationalLog.recordEvent('runtime_probe','inspection','pass');
        for (Object value : checks) {
            Map<String,Object> check = (Map<String,Object>)value;
            if (new Set<String>{'native_assessment','raw_email_read_boundary','unapproved_task_action','mcp_boundary'}.contains((String)check.get('id')))
                recorded = ReadinessOperationalLog.recordEvent('runtime_probe',(String)check.get('id'),(String)check.get('status')) && recorded;
        }
        return JSON.serialize(new Map<String,Object>{'version'=>'runtime-probe-v1','source'=>'executed_salesforce_calls',
            'principal'=>'current_salesforce_user','scope'=>'current_principal_and_fixed_readiness_surfaces',
            'observed_at'=>Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),'checks'=>checks,'gaps'=>gaps,
            'monitoring'=>new Map<String,Object>{'recorded'=>recorded,
                'scope'=>'sanitized_local_operations_log'},'readiness_established'=>false});
    }
    private static Map<String,Object> parse(String value) { return (Map<String,Object>)JSON.deserializeUntyped(value); }
    private static Map<String,Object> row(String id,String label,String status,String basis) {
        return new Map<String,Object>{'id'=>id,'label'=>label,'status'=>status,'basis'=>basis};
    }
    private static Map<String,Object> gap(String id,String label,String binding) {
        return new Map<String,Object>{'id'=>id,'label'=>label,'status'=>'unknown','required_binding'=>binding};
    }
    private static Boolean aggregateShape(Map<String,Object> result) {
        if (result.containsKey('error') || result.get('evidence_mode') != 'live_aggregate' || !result.containsKey('data')) return false;
        Map<String,Object> privacy = (Map<String,Object>)result.get('privacy');
        if (privacy == null || privacy.get('mode') != 'aggregate_only') return false;
        Map<String,Object> metrics = (Map<String,Object>)result.get('metrics');
        if (metrics == null) return privacy.get('suppressed') == true;
        Set<String> allowed = new Set<String>{'contacts','email_present','linked_contacts','repeated_email_rows'};
        for (String key : metrics.keySet()) {
            if (!allowed.contains(key) || !(metrics.get(key) instanceof Decimal) || (Decimal)metrics.get(key) < 0) return false;
        }
        return metrics.keySet().equals(allowed);
    }
}
