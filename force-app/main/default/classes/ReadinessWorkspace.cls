/** Private governance inputs and sanitized, append-only assessment history. */
public with sharing class ReadinessWorkspace {
    private static final String VERSION='ai-readiness-health-v2';
    private static final Set<String> CASE_TEXT=new Set<String>{'name','status','owner','purpose','integrationUsername','allowedActions','excludedActions','value','successCriteria','risks','mitigation','handover','stopOwner','costs','gains','decisionNotes','approver','policyReference'};
    private static final Set<String> STATUSES=new Set<String>{'Draft','Proposed','In progress','Approved','Paused','Retired'};
    private static String writing;
    public static Boolean allowsWrite(String kind) {return writing==kind;}
    @AuraEnabled public static String loadWorkspace() {
        Map<String,Object> result=new Map<String,Object>{'questions'=>questions(),'canEdit'=>FeatureManagement.checkPermission('Readiness_Manage_Workspace'),'canRecord'=>FeatureManagement.checkPermission('Readiness_Record_Assessment')};
        List<Object> cases=new List<Object>(),history=new List<Object>();
        if(Readiness_Use_Case__c.SObjectType.getDescribe().isAccessible()) for(Readiness_Use_Case__c record:[SELECT Id,Name,Definition__c FROM Readiness_Use_Case__c WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 100]) cases.add(caseValue(record));
        if(Readiness_Assessment__c.SObjectType.getDescribe().isAccessible()) for(Readiness_Assessment__c record:[SELECT Id,Name,Summary__c,CreatedDate,CreatedBy.Name FROM Readiness_Assessment__c WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 30]) {
            Map<String,Object> row=parse(record.Summary__c);row.put('id',record.Id);row.put('name',record.Name);row.put('actor',record.CreatedBy.Name);history.add(row);
        }
        result.put('useCases',cases);result.put('answers',latestAnswers());result.put('history',history);
        return JSON.serialize(result);
    }
    @AuraEnabled public static String saveUseCase(String input) {
        requireEditor();Map<String,Object> source=boundedInput(input,20000),value=new Map<String,Object>();
        for(String key:CASE_TEXT) value.put(key,text(source,key,key=='name'?80:2000));
        for(String key:new List<String>{'name','owner','purpose'}) if(String.isBlank((String)value.get(key))) reject('Name, business owner and purpose are required.');
        if(String.isBlank((String)value.get('status'))) value.put('status','Proposed');
        if(!STATUSES.contains((String)value.get('status'))) reject('Choose a supported business lifecycle status.');
        List<Object> grounding=new List<Object>();Set<String> seen=new Set<String>(),objects=new Set<String>();
        Object raw=source.get('groundingFields');
        if(raw!=null&&!(raw instanceof List<Object>)) reject('Grounding fields must be a list of Object.Field identifiers.');
        List<Object> submitted=raw instanceof List<Object>?(List<Object>)raw:new List<Object>();
        if(submitted.size()>12) reject('Use at most 12 grounding fields across three objects.');
        Map<String,Schema.SObjectType> all=Schema.getGlobalDescribe();
        for(Object item:submitted) {
            String qualified=String.valueOf(item).trim();if(qualified=='') continue;
            List<String> parts=qualified.split('\\.');
            if(parts.size()!=2||!Pattern.matches('[A-Za-z][A-Za-z0-9_]*\\.[A-Za-z][A-Za-z0-9_]*',qualified)||!all.containsKey(parts[0])) reject('Use valid Object.Field grounding identifiers.');
            Schema.DescribeSObjectResult objectInfo=all.get(parts[0]).getDescribe();
            if(!objectInfo.isAccessible()||!objectInfo.isQueryable()||!objectInfo.fields.getMap().containsKey(parts[1])||!objectInfo.fields.getMap().get(parts[1]).getDescribe().isAccessible()) reject('A grounding object or field is not accessible to you.');
            String canonical=objectInfo.getName()+'.'+objectInfo.fields.getMap().get(parts[1]).getDescribe().getName();
            if(!seen.contains(canonical)) grounding.add(canonical);seen.add(canonical);objects.add(objectInfo.getName());
        }
        if(objects.size()>3) reject('Use at most three grounding objects.');
        value.put('groundingFields',grounding);
        Decimal fresh=numberValue(source,'freshDays',1,3650),minimum=numberValue(source,'minimumCompleteness',0,100);
        if(fresh!=null&&fresh!=fresh.setScale(0)) reject('Freshness days must be a whole number.');
        Boolean approved=source.get('policyApproved')==true;
        if((fresh!=null||minimum!=null)&&(!approved||String.isBlank((String)value.get('policyReference')))) reject('Thresholds require an explicitly approved policy reference.');
        value.put('freshDays',fresh);value.put('minimumCompleteness',minimum);value.put('policyApproved',approved);
        String username=(String)value.get('integrationUsername');String userId=text(source,'integrationUserId',18);
        if(!String.isBlank(username)||!String.isBlank(userId)) {
            if(!FeatureManagement.checkPermission('Readiness_Read_Org_Security')) reject('Assign Security Reader to bind an actual integration identity.');
            List<User> users;
            if(!String.isBlank(username)) users=[SELECT Id,Username FROM User WHERE Username=:username WITH USER_MODE LIMIT 1];
            else {Id intended=validatedId(userId,User.SObjectType);users=[SELECT Id,Username FROM User WHERE Id=:intended WITH USER_MODE LIMIT 1];}
            if(users.isEmpty()) reject('The intended integration user is not visible in this org.');
            value.put('integrationUserId',users[0].Id);value.put('integrationUsername',users[0].Username);
        } else {value.put('integrationUserId',null);value.put('integrationUsername','');}
        Readiness_Use_Case__c record=new Readiness_Use_Case__c(Name=(String)value.get('name'),Definition__c=JSON.serialize(value));
        String recordId=text(source,'id',18);
        writing='case';
        try {if(recordId!='') {record.Id=validatedId(recordId,Readiness_Use_Case__c.SObjectType);List<Readiness_Use_Case__c> authorized=[SELECT Id FROM Readiness_Use_Case__c WHERE Id=:record.Id WITH USER_MODE];if(authorized.isEmpty()) reject('Use case is not accessible.');update as user record;}
        else insert as user record;} finally {writing=null;}
        value.put('id',record.Id);return JSON.serialize(value);
    }
    @AuraEnabled public static String saveAnswer(String input) {
        requireEditor();Map<String,Object> source=boundedInput(input,12000),definition;
        String questionId=text(source,'questionId',80),scope=text(source,'scope',30);
        for(Object raw:questions()) {Map<String,Object> candidate=(Map<String,Object>)raw;if(candidate.get('id')==questionId&&candidate.get('scope')==scope) definition=candidate;}
        if(definition==null) reject('Choose a defined checklist question in its correct scope.');
        String answer=text(source,'answer',20);
        if(!new Set<String>{'yes','partial','no','unknown'}.contains(answer)) reject('Choose Yes, Partially, No or Not sure.');
        Map<String,Object> value=new Map<String,Object>{'questionId'=>questionId,'scope'=>scope,'answer'=>answer};
        for(String key:new List<String>{'notes','responsible','evidence'}) value.put(key,text(source,key,2000));
        Date due=dateValue(source,'dueDate'),review=dateValue(source,'reviewDate');
        if(review!=null&&review>Date.today()) reject('Review date cannot be in the future.');
        value.put('dueDate',due);value.put('reviewDate',review);
        if(answer=='yes'&&(String.isBlank((String)value.get('responsible'))||String.isBlank((String)value.get('evidence'))||review==null)) reject('A reported Yes needs a responsible person, evidence reference and review date.');
        Id caseId;
        if(scope=='implementation') {caseId=validatedId(text(source,'useCaseId',18),Readiness_Use_Case__c.SObjectType);loadCase(caseId);}
        else if(!String.isBlank(text(source,'useCaseId',18))) reject('Company and Org answers cannot be attached to an implementation.');
        value.put('useCaseId',caseId);value.put('updatedAt',Datetime.now());value.put('updatedBy',UserInfo.getName());
        Readiness_Answer__c record=new Readiness_Answer__c(Scope__c=scope,Question__c=questionId,Use_Case__c=caseId,Response__c=JSON.serialize(value));
        writing='answer';try {insert as user record;} finally {writing=null;}value.put('id',record.Id);return JSON.serialize(value);
    }
    @AuraEnabled public static String scanUseCase(String useCaseId) {
        if(ReadinessControl.isDisabled()) reject('Assessment is paused.');
        Map<String,Object> useCase=caseValue(loadCase(validatedId(useCaseId,Readiness_Use_Case__c.SObjectType)));
        Map<String,Object> baseline=parse(ReadinessOrgHealth.scanCore());List<Object> findings=new List<Object>();
        for(Object raw:(List<Object>)baseline.get('findings')) {Map<String,Object> row=(Map<String,Object>)raw;if(row.get('group')!='Data quality') findings.add(row);}
        findings.addAll(ReadinessScopedChecks.collect(useCase));findings.addAll(governanceFindings((String)useCase.get('id')));
        Map<String,Object> result=parse(ReadinessOrgHealth.summarize(findings,(List<Object>)baseline.get('inventory')));
        result.put('scopeDefinition',scopeDefinition(useCase));result.put('version',VERSION);result.put('useCaseId',useCase.get('id'));result.put('lifecycleStatus',useCase.get('status'));result.put('source','Live implementation assessment');
        result.put('scope','Selected implementation grounding data collected as you, intended-identity configuration, shared org configuration, your reported governance policies and confirmed staff exercises. Current-user probes do not prove intended assistant behavior.');
        return JSON.serialize(saveSnapshot(result,(Id)useCase.get('id')));
    }
    public static String decorateOrganization(String report) {
        Map<String,Object> source=parse(report);if(source.containsKey('error')) return report;
        List<Object> findings=(List<Object>)source.get('findings');findings.addAll(governanceFindings(null));
        Map<String,Object> result=parse(ReadinessOrgHealth.summarize(findings,(List<Object>)source.get('inventory')));
        result.put('scopeDefinition',new Map<String,Object>{'scope'=>'organization','collector'=>'health-v2'});result.put('version',VERSION);result.put('source','Live organization assessment');
        result.put('scope',String.valueOf(source.get('scope'))+' Includes your reported Company/Org policies; policy attestations do not establish runtime safeguards.');
        return JSON.serialize(saveSnapshot(result,null));
    }
    @AuraEnabled public static String loadHistory(String assessmentId) {
        Id recordId=validatedId(assessmentId,Readiness_Assessment__c.SObjectType);
        List<Readiness_Assessment__c> records=[SELECT Id,Report__c FROM Readiness_Assessment__c WHERE Id=:recordId WITH USER_MODE LIMIT 1];
        if(records.isEmpty()) reject('Assessment is not accessible.');
        Map<String,Object> report=parse(records[0].Report__c);report.put('source','Saved assessment');report.put('historySaved',true);report.put('assessmentId',records[0].Id);return JSON.serialize(report);
    }
    private static Map<String,Object> saveSnapshot(Map<String,Object> result,Id caseId) {
        result.put('historySaved',false);
        if(!FeatureManagement.checkPermission('Readiness_Record_Assessment')) {result.put('historyMessage','Readiness Assessment Recorder role is required to save scan history.');return result;}
        Map<String,Object> summary=new Map<String,Object>();
        for(String key:new List<String>{'useCaseId','scope','scopeDefinition','version','observedAt','passed','failed','unknown','coverage','score','criticalFailures','lifecycleStatus'}) summary.put(key,result.get(key));
        Map<String,Object> stored=result.clone();stored.put('historySaved',true);String encoded=JSON.serialize(stored);
        if(encoded.length()>131000) {result.put('historyMessage','Report exceeds the history storage limit; the scan is still available.');return result;}
        try {
            Readiness_Assessment__c record=new Readiness_Assessment__c(Use_Case__c=caseId,Summary__c=JSON.serialize(summary),Report__c=encoded);
            writing='assessment';try {insert as user record;} finally {writing=null;}result.put('historySaved',true);result.put('assessmentId',record.Id);
        } catch(Exception ignored) {result.put('historyMessage','History could not be saved with your access. No earlier assessment was changed.');}
        return result;
    }
    private static List<Object> latestAnswers() {
        List<Object> result=new List<Object>();if(!Readiness_Answer__c.SObjectType.getDescribe().isAccessible()) return result;Set<String> seen=new Set<String>();
        for(Readiness_Answer__c record:[SELECT Id,Scope__c,Question__c,Use_Case__c,Response__c FROM Readiness_Answer__c WITH USER_MODE ORDER BY CreatedDate DESC,Id DESC LIMIT 2000]) {
            String key=record.Scope__c+':'+record.Use_Case__c+':'+record.Question__c;if(seen.contains(key)) continue;seen.add(key);
            Map<String,Object> value=parse(record.Response__c);value.put('id',record.Id);result.add(value);
        }
        return result;
    }
    @TestVisible private static List<Object> governanceFindings(String caseId) {
        Map<String,Map<String,Object>> answers=new Map<String,Map<String,Object>>();
        try {for(Object raw:latestAnswers()) {Map<String,Object> answer=(Map<String,Object>)raw;if(answer.get('scope')!='implementation'||answer.get('useCaseId')==caseId) answers.put((String)answer.get('questionId'),answer);}} catch(Exception ignored) {}
        List<Object> result=new List<Object>();
        for(Object raw:questions()) {
            Map<String,Object> q=(Map<String,Object>)raw;if(q.get('scope')=='implementation'&&caseId==null) continue;
            Map<String,Object> answer=answers.get((String)q.get('id'));String state=answer==null?'unknown':(String)answer.get('answer');
            Boolean complete=answer!=null&&!String.isBlank((String)answer.get('responsible'))&&!String.isBlank((String)answer.get('evidence'))&&answer.get('reviewDate')!=null;
            String status=state=='yes'&&complete?'pass':state=='no'||state=='partial'?'fail':'unknown';
            String actual=answer==null?'No reported policy review':state=='yes'&&!complete?'Missing accountable review evidence':state=='yes'?'Reported policy with owner and dated evidence':state=='partial'?'Policy reported as partial':state=='no'?'Policy reported absent':'Reviewer is unsure';
            Map<String,Object> finding=new Map<String,Object>{'id'=>'governance_'+q.get('id'),'label'=>q.get('label'),'group'=>q.get('group'),'severity'=>'High','status'=>status,'actual'=>actual,'expected'=>'Accountable documented policy review; separate execution proof for safeguards','action'=>q.get('advice'),'url'=>'/lightning/n/AI_Readiness','questionId'=>q.get('id'),'checklistScope'=>q.get('scope'),'useCaseId'=>q.get('scope')=='implementation'?caseId:null,'basis'=>'reported_policy'};
            result.add(finding);
        }
        return result;
    }
    private static Map<String,Object> scopeDefinition(Map<String,Object> useCase) {
        List<String> fields=new List<String>();for(Object field:(List<Object>)useCase.get('groundingFields')) fields.add(String.valueOf(field));fields.sort();
        String identity=useCase.get('integrationUserId')==null?'unbound':String.valueOf(useCase.get('integrationUserId'));
        String binding=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(identity)));
        String policy=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(useCase.get('policyReference')==null?'none':String.valueOf(useCase.get('policyReference')))));
        return new Map<String,Object>{'groundingFields'=>fields,'identityBinding'=>binding,'freshDays'=>useCase.get('freshDays'),'minimumCompleteness'=>useCase.get('minimumCompleteness'),'policyApproved'=>useCase.get('policyApproved'),'policyBinding'=>policy,'actionBinding'=>EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(String.valueOf(useCase.get('allowedActions'))+'|'+String.valueOf(useCase.get('excludedActions')))))};
    }
    private static Readiness_Use_Case__c loadCase(Id id) {List<Readiness_Use_Case__c> records=[SELECT Id,Name,Definition__c FROM Readiness_Use_Case__c WHERE Id=:id WITH USER_MODE LIMIT 1];if(records.isEmpty()) reject('Use case is not accessible.');return records[0];}
    private static Map<String,Object> caseValue(Readiness_Use_Case__c record) {Map<String,Object> value=parse(record.Definition__c);value.put('id',record.Id);value.put('name',record.Name);return value;}
    private static void requireEditor() {if(!FeatureManagement.checkPermission('Readiness_Manage_Workspace')) reject('The separate Readiness Governance Reviewer role is required.');}
    private static void reject(String message) {throw new AuraHandledException(message);}
    private static Map<String,Object> parse(String value) {return (Map<String,Object>)JSON.deserializeUntyped(value);}
    private static Map<String,Object> boundedInput(String value,Integer maximum) {if(value==null||value.length()>maximum) reject('Input is missing or too large.');try {Map<String,Object> parsed=parse(value);if(parsed==null) reject('Structured input must be an object.');return parsed;} catch(Exception error) {reject('Provide a valid structured input.');return null;}}
    private static String text(Map<String,Object> input,String key,Integer maximum) {Object value=input.get(key);if(value==null) return '';if(!(value instanceof String)) reject('Text required for '+key+'.');String result=((String)value).trim();if(result.length()>maximum) reject(key+' is too long.');return result;}
    private static Decimal numberValue(Map<String,Object> input,String key,Decimal minimum,Decimal maximum) {Object raw=input.get(key);if(raw==null||raw=='') return null;Decimal value;try {value=Decimal.valueOf(String.valueOf(raw));} catch(Exception error) {reject('A number is required for '+key+'.');}if(value<minimum||value>maximum) reject(key+' is outside the supported range.');return value;}
    private static Date dateValue(Map<String,Object> input,String key) {String value=text(input,key,10);if(value=='') return null;try {return Date.valueOf(value);} catch(Exception error) {reject('Use an ISO date for '+key+'.');return null;}}
    private static Id validatedId(String value,Schema.SObjectType expected) {try {Id id=Id.valueOf(value);if(id.getSObjectType()!=expected) reject('Unexpected record type.');return id;} catch(Exception error) {reject('A valid record identifier is required.');return null;}}
    public static List<Object> questions() {
        List<Object> result=new List<Object>();
        addQuestion(result,'company','Responsible people','admin_owner','Who is accountable for Salesforce administration?','Staff readiness','Name the responsible administrator and record their agreed remit.');
        addQuestion(result,'company','Responsible people','privacy_owner','Who owns privacy and GDPR/AVG decisions?','Privacy and erasure','Name the privacy owner. If a DPO is not required, document the rationale and appropriate responsible person; this app does not decide the legal requirement.');
        addQuestion(result,'company','Responsible people','security_owner','Who approves access and integrations?','Access and safeguards','Record the security decision owner and approval route.');
        addQuestion(result,'company','Process ownership','data_steward','Who owns imports, deduplication and corrections?','Data quality','Name the data steward and document import verification and merging procedures.');
        addQuestion(result,'company','Process ownership','staff_process','Is staff training and output review owned?','Staff readiness','Name the training and output-review owner; complete the seven observed exercises separately.');
        addQuestion(result,'company','Privacy policies','retention_policy','Are retention and erasure responsibilities documented?','Privacy and erasure','Record approved periods and owners across Salesforce, files, history, Recycle Bin, backups and connected tools.');
        addQuestion(result,'company','Privacy policies','llm_policy','Are approved AI providers and data rules documented?','Privacy and erasure','Record corporate versus personal LLM rules, provider retention terms, prohibited data and approved protocols.');
        addQuestion(result,'org','Data stewardship','knowledge_review','Is grounding content curated and reviewed?','Data quality','Name the Knowledge/data-library owner and approved review cadence.');
        addQuestion(result,'org','Data stewardship','data_protocols','Are data entry and import protocols approved?','Data quality','Record validation, correction and import review procedures for the in-scope information.');
        addQuestion(result,'org','Access processes','offboarding','Are access requests and offboarding owned?','Access and safeguards','Record the access review and leaver deactivation owner and required response time.');
        addQuestion(result,'org','Access processes','incident_process','Is the data incident escalation process documented?','Access and safeguards','Name the incident receiver, escalation route, response duties and reporting procedure; test delivery separately.');
        addQuestion(result,'org','Privacy procedures','consent_process','Is lawful basis and outreach consent handling documented?','Privacy and erasure','Record processing purposes, lawful basis and how consent filters outreach; execution needs separate verification.');
        addQuestion(result,'org','Privacy procedures','sensitive_policy','Are sensitive-data and risky-location rules approved?','Privacy and erasure','Document sensitive/minor data classification, exclusions and temporary restrictions for risky contexts; verify technical enforcement separately.');
        addQuestion(result,'implementation','Purpose and approvals','use_case_approval','Is this AI purpose and its value approved?','Staff readiness','Name the business owner and approver, success measures, costs/gains and accepted risks.');
        addQuestion(result,'implementation','Purpose and approvals','scope_approval','Is the allowed data and action scope approved?','Access and safeguards','Document allowed objects/fields/actions, exclusions and the intended integration identity. Metadata checks are not runtime proof.');
        addQuestion(result,'implementation','Handover and safeguards','human_approval_policy','Are consequential actions routed for human approval?','Access and safeguards','Document the authorized approver and handover procedure; demonstrate blocked-before-approval behavior separately.');
        addQuestion(result,'implementation','Handover and safeguards','stop_policy','Is stopping and recovery assigned to a person?','Access and safeguards','Name who can stop the actual assistant and recover safely; pausing this package is not enough.');
        addQuestion(result,'implementation','Handover and safeguards','monitoring_policy','Are output review and incident response owned?','Staff readiness','Record who reviews logs/output, cadence, complaints, alerts and escalation; test actual alert delivery separately.');
        addQuestion(result,'implementation','Data handling','implementation_retention','Are this use case\'s data destinations and retention approved?','Privacy and erasure','Inventory prompts, outputs, integrations, exports, logs and backups with accountable destination owners and approved retention.');
        return result;
    }
    private static void addQuestion(List<Object> rows,String scope,String stage,String id,String label,String groupName,String advice) {rows.add(new Map<String,Object>{'id'=>id,'scope'=>scope,'stage'=>stage,'label'=>label,'group'=>groupName,'advice'=>advice});}
}
