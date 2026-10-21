/** Native AI readiness rubric across data, access, staff and erasure. No raw identities returned. */
public with sharing class ReadinessOrgHealth {
    private static final String SETUP='/lightning/setup/';
    public class Request { @InvocableVariable public Boolean run; }
    public class Response { @InvocableVariable public String output; }
    @InvocableMethod(label='Scan AI Readiness Health' description='Read fixed AI readiness findings. Setup checks require Security Reader. No CRM writes; sanitized runtime events only.')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> output=new List<Response>();
        if(requests==null) return output;
        String result=scan();
        for(Request request:requests) { Response row=new Response();row.output=result;output.add(row); }
        return output;
    }
    @AuraEnabled
    public static String scan() {
        return ReadinessWorkspace.decorateOrganization(scanCore());
    }
    public static String scanCore() {
        List<Object> findings=new List<Object>();
        List<Object> inventory=new List<Object>();
        if(ReadinessControl.isDisabled()) return JSON.serialize(new Map<String,Object>{'error'=>'assessment_stopped'});
        collectDataAndStaff(findings);
        Boolean allowed=FeatureManagement.checkPermission('Readiness_Read_Org_Security');
        if(allowed) {
        addCount(findings,'broad_profile','Broad data read on non-administrator profiles','Access and safeguards','High',
            'SELECT COUNT() FROM User WHERE IsActive=true AND Profile.PermissionsModifyAllData=false AND Profile.PermissionsViewAllData=true',
            '0 active users','Review broad data access on profiles without Modify All Data.','Profiles/home');
        addCount(findings,'broad_assignment','Broad data grants outside administrator profiles','Access and safeguards','High',
            'SELECT COUNT() FROM PermissionSetAssignment WHERE Assignee.IsActive=true AND Assignee.Profile.PermissionsModifyAllData=false AND (PermissionSet.PermissionsViewAllData=true OR PermissionSet.PermissionsModifyAllData=true)',
            '0 assignments','Review assigned broad data grants; retain only approved exceptions.','PermSets/home');
        addCount(findings,'guest_broad','Guest profiles with org-wide data access','Access and safeguards','Critical',
            'SELECT COUNT() FROM User WHERE IsActive=true AND UserType=\'Guest\' AND (Profile.PermissionsViewAllData=true OR Profile.PermissionsModifyAllData=true)',
            '0 active guest users','Remove org-wide data grants from guest profiles.','DigitalExperiences/home');
        addCount(findings,'guest_export','Guest profiles with report export','Access and safeguards','High',
            'SELECT COUNT() FROM User WHERE IsActive=true AND UserType=\'Guest\' AND Profile.PermissionsExportReport=true',
            '0 active guest users','Review and remove report export from guest profiles.','DigitalExperiences/home');
        } else {
            for(String id:new List<String>{'broad_profile','broad_assignment','guest_broad','guest_export'}) findings.add(finding(id,'Org access: '+id,'Access and safeguards','High','unknown','Security Reader required','Visible org-wide setup','Assign the focused Readiness Security Reader role.','PermSets/home'));
        }
        if(allowed) {
        addInventory(inventory,'active_users','Active users','SELECT COUNT() FROM User WHERE IsActive=true','User count, not proof of active use.');
        addInventory(inventory,'admin_users','Active users on administrator profiles','SELECT COUNT() FROM User WHERE IsActive=true AND Profile.PermissionsModifyAllData=true','Profiles with Modify All Data; review approved administrators.');
        addInventory(inventory,'unused_sets','Unassigned permission sets','SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile=false AND Type=\'Regular\' AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment)','Inventory only. Unassigned permission sets do not grant access and are not a security failure.');
        addInventory(inventory,'unused_roles','Roles with no active users','SELECT COUNT() FROM UserRole WHERE Id NOT IN (SELECT UserRoleId FROM User WHERE IsActive=true AND UserRoleId!=null)','Inventory only. Review before deleting; roles may be intentionally reserved.');
        }
        collectRuntime(findings);
        collectPrivacy(findings);
        return summarize(findings,inventory);
    }
    private static void addCount(List<Object> rows,String id,String label,String groupName,String severity,String query,String expected,String action,String page) {
        try { Integer count=Database.countQuery(query+' WITH USER_MODE'); rows.add(finding(id,label,groupName,severity,count==0?'pass':'fail',String.valueOf(count),expected,action,page)); }
        catch(Exception ignored) { rows.add(finding(id,label,groupName,severity,'unknown','Not available',expected,'Setup visibility is unavailable; no pass inferred.',page)); }
    }
    private static void addInventory(List<Object> rows,String id,String label,String query,String note) {
        Integer count;
        try {count=Database.countQuery(query+' WITH USER_MODE');} catch(Exception ignored) {}
        rows.add(new Map<String,Object>{'id'=>id,'label'=>label,'count'=>count,'note'=>note});
    }
    @TestVisible private static Map<String,Object> finding(String id,String label,String groupName,String severity,String status,String actual,String expected,String action,String page) {
        return new Map<String,Object>{'id'=>id,'label'=>label,'group'=>groupName,'severity'=>severity,'status'=>status,'actual'=>actual,'expected'=>expected,'action'=>action,'url'=>page=='Contact/list'?'/lightning/o/Contact/list':page==''?'/lightning/n/AI_Readiness':SETUP+page};
    }
    private static Map<String,Object> parse(String text) {return (Map<String,Object>)JSON.deserializeUntyped(text);}
    private static void collectDataAndStaff(List<Object> rows) {
        Map<String,Object> report;
        try {report=parse(NonprofitAIReadiness.assessScenario('organization'));} catch(Exception ignored) {}
        Map<String,Object> data=report==null?null:(Map<String,Object>)report.get('data');
        Map<String,Object> checks=data==null?new Map<String,Object>():(Map<String,Object>)data.get('checks');
        Map<String,Object> metrics=report==null?null:(Map<String,Object>)report.get('metrics');
        Map<String,String> labels=new Map<String,String>{'sufficient_data'=>'Representative Contact cohort','email_completeness'=>'Contact email completeness','account_linkage'=>'Contacts linked to Accounts','duplicate_indicator'=>'Repeated email indicator'};
        Map<String,String> expected=new Map<String,String>{'sufficient_data'=>'At least 10 accessible Contacts','email_completeness'=>'At least 90% with an email','account_linkage'=>'All Contacts linked to Accounts','duplicate_indicator'=>'No repeated email rows; review shared addresses'};
        for(String id:new List<String>{'sufficient_data','email_completeness','account_linkage','duplicate_indicator'}) {
            String status=checks==null||checks.get(id)==null?'unknown':(String)checks.get(id);
            String actual='Not measured or small cohort withheld';
            if(metrics!=null) {
                Decimal count=(Decimal)metrics.get('contacts');
                actual=id=='sufficient_data'?String.valueOf(count)+' Contacts':id=='duplicate_indicator'?String.valueOf(metrics.get('repeated_email_rows'))+' repeated rows':id=='account_linkage'?String.valueOf(metrics.get('linked_contacts'))+' of '+count+' linked':String.valueOf(metrics.get('email_present'))+' of '+count+' with email';
            }
            rows.add(finding(id,labels.get(id),'Data quality','Medium',status,actual,expected.get(id),'Review accessible Contact data; correct only verified information.','Contact/list'));
        }
        rows.add(finding('data_freshness','Approved data freshness policy','Data quality','Medium','unknown','No policy applied in this health scan','Explicit approved window and recent-activity threshold','Use the data freshness form with your approved policy.',''));
        Map<String,Object> review=report==null?null:(Map<String,Object>)report.get('staff_review');
        Boolean practice=review!=null&&review.get('provenance')=='seeded_practice';
        Map<String,Object> staff=review==null?null:(Map<String,Object>)review.get('staff');
        Map<String,Object> staffChecks=staff==null?new Map<String,Object>():(Map<String,Object>)staff.get('checks');
        Map<String,String> staffLabels=new Map<String,String>{'scope'=>'Approved scope and human decisions','sensitive_data'=>'Sensitive data and deletion requests','untrusted_content'=>'False claims and unsafe instructions','access'=>'Assistant access boundaries','quality'=>'Reliable information and stewardship','review'=>'Review before consequential actions','incident'=>'Detection, stopping and recovery'};
        // Use the versioned answer key IDs; never substitute a practice score for human evidence.
        List<Object> definitions=(List<Object>)parse([SELECT Body FROM StaticResource WHERE Name='StaffReadinessAnswerKey' LIMIT 1].Body.toString()).get('questions');
        for(Object value:definitions) {
            String id=(String)((Map<String,Object>)value).get('id');
            String status=practice||staffChecks.get(id)==null?'unknown':(String)staffChecks.get(id);
            Boolean critical=false;
            if(!practice&&review!=null) for(Object failure:(List<Object>)review.get('critical_failures')) if(String.valueOf(failure).startsWith(id+':')) critical=true;
            rows.add(finding('staff_'+id,staffLabels.containsKey(id)?staffLabels.get(id):id,'Staff readiness',critical?'Critical':'High',status,practice?'Seeded practice inputs only':review==null?'No confirmed review':status+' in your saved review','Confirmed observed exercise','Record the seven staff demonstrations; practice inputs do not establish competency.',''));
        }
    }
    private static void collectRuntime(List<Object> rows) {
        try {
            Map<String,Object> runtime=parse(ReadinessRuntimeProbe.inspect());
            for(Object value:(List<Object>)runtime.get('checks')) {
                Map<String,Object> check=(Map<String,Object>)value;String id=(String)check.get('id');
                if(id=='contact_read'||id=='email_read') continue;
                rows.add(finding('runtime_'+id,(String)check.get('label'),'Access and safeguards','High',(String)check.get('status'),(String)check.get('basis'),'Expected package boundary observed as current user','Review the executed verification detail; bind the intended assistant separately.',''));
            }
            for(Object value:(List<Object>)runtime.get('gaps')) {
                Map<String,Object> gap=(Map<String,Object>)value;
                rows.add(finding('runtime_'+(String)gap.get('id'),(String)gap.get('label'),'Access and safeguards','High','unknown','Not measured for intended assistant','Observed allowed and denied behavior',(String)gap.get('required_binding'),''));
            }
        } catch(Exception ignored) {
            for(String id:new List<String>{'native_assessment','raw_email_read_boundary','unapproved_task_action','mcp_boundary','assistant_identity','consequential_approval','stop_recovery','monitoring','export_surface'}) rows.add(finding('runtime_'+id,id,'Access and safeguards','High','unknown','Not available','Executed runtime evidence','Check assessment access and bind the intended assistant.',''));
        }
    }
    private static void collectPrivacy(List<Object> rows) {
        Map<String,Readiness_Operation__c> latest=new Map<String,Readiness_Operation__c>();
        try {
            for(Readiness_Operation__c event:[SELECT Check__c,Outcome__c,CreatedDate FROM Readiness_Operation__c WHERE OwnerId=:UserInfo.getUserId() AND Source__c='erasure_probe' AND Check__c IN ('source_deletion','recycle_bin') AND CreatedDate=LAST_N_DAYS:1 WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 100]) if(!latest.containsKey(event.Check__c)) latest.put(event.Check__c,event);
        } catch(Exception ignored) {}
        for(String id:new List<String>{'source_deletion','recycle_bin'}) {
            Readiness_Operation__c event=latest.get(id);
            Boolean fresh=event!=null&&event.CreatedDate>=Datetime.now().addHours(-24);
            rows.add(finding(id,id=='source_deletion'?'Last canary excluded from active reads':'Last canary permanently erased','Privacy and erasure','High',fresh?event.Outcome__c:'unknown',fresh?event.Outcome__c+' observed '+event.CreatedDate.formatGmt('yyyy-MM-dd HH:mm')+' UTC':'No canary observation within 24 hours',id=='source_deletion'?'Excluded from active reads and fresh aggregates':'Not recoverable from Recycle Bin','Run the separate confirmed scratch canary exercise; retained data is a failure, not an erasure pass.',''));
        }
        for(String id:new List<String>{'integrations','logs','backups','exports','agent_output','retention'}) rows.add(finding('privacy_'+id,'Deletion and retention: '+id,'Privacy and erasure','High','unknown','No verified destination evidence','Observed approved deletion or retention outcome','Connect the actual destination and verify its approved erasure and retention procedure.',''));
    }
    @TestVisible private static Map<String,Object> category(String id,String label,List<Object> findings) {
        Integer passed=0,failed=0,unknown=0;
        for(Object value:findings) {Map<String,Object> row=(Map<String,Object>)value;if(label!=null&&row.get('group')!=label) continue; if(row.get('status')=='pass') passed++;else if(row.get('status')=='fail') failed++;else unknown++;}
        Integer total=passed+failed+unknown,measured=passed+failed;
        Decimal score=measured==0?null:(Decimal.valueOf(passed)*100/total).setScale(1,RoundingMode.HALF_UP);
        return new Map<String,Object>{'id'=>id,'label'=>label,'score'=>score,'coverage'=>total==0?0:(Decimal.valueOf(measured)*100/total).setScale(1,RoundingMode.HALF_UP),'passed'=>passed,'failed'=>failed,'unknown'=>unknown,'total'=>total,'rating'=>measured==0?'Not checked':failed>0?'Needs attention':unknown>0?'Incomplete':'Checks met'};
    }
    public static String summarize(List<Object> findings,List<Object> inventory) {
        List<Object> categories=new List<Object>();
        List<String> labels=new List<String>{'Data quality','Access and safeguards','Staff readiness','Privacy and erasure'};
        for(String label:labels) categories.add(category(label,label,findings));
        Map<String,Object> result=category('overall',null,findings);
        Integer critical=0;
        for(Object value:findings) {Map<String,Object> row=(Map<String,Object>)value;if(row.get('severity')=='Critical'&&row.get('status')=='fail') critical++;}
        result.put('version','ai-readiness-health-v1');result.put('observedAt',Datetime.now());result.put('findings',findings);result.put('inventory',inventory);result.put('categories',categories);result.put('criticalFailures',critical);
        result.put('scope','Accessible organization Contacts, org setup visible to your Security Reader role, current-user package probes, your confirmed staff exercises, and your canary observations within 24 hours. Unknown checks earn no points; score = passed / all defined checks.');
        result.put('banner',critical>0?'Blocked: an observed critical failure requires correction and retesting.':(Integer)result.get('unknown')>0?'Incomplete: required evidence is missing. Review failed and unmeasured checks before an AI pilot.':(Integer)result.get('failed')>0?'Needs attention: correct failed checks and repeat the assessment.':'Defined checks met. Confirm scope and accountable approval before an AI pilot.');
        result.put('readinessEstablished',false);
        return JSON.serialize(result);
    }
}
