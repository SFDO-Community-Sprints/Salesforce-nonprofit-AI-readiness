/** Read-only inspection of deployed readiness roles, not effective user access or runtime controls. */
public with sharing class ReadinessOrgChecks {
    private static final Set<String> NAMES = new Set<String>{'Readiness_Assessor','Readiness_MCP','Readiness_Staff_Reviewer','Readiness_Staff_Reader','Readiness_Follow_Up','Readiness_Evidence_Reviewer'};
    @TestVisible private class Role {
        @TestVisible private Boolean broad = false;
        Boolean api = false;
        Boolean apiOnly = false;
        @TestVisible private List<ObjectPermissions> objects = new List<ObjectPermissions>();
        List<FieldPermissions> fields = new List<FieldPermissions>();
        Set<String> customs = new Set<String>();
        Set<String> classes = new Set<String>();
    }
    @AuraEnabled
    public static String assess() {
        Map<String,Role> roles = new Map<String,Role>();
        Boolean observed = false;
        try {
            Map<Id,String> ids = new Map<Id,String>();
            for (PermissionSet p : [SELECT Id,Name,PermissionsApiEnabled,PermissionsApiUserOnly,PermissionsViewAllData,PermissionsModifyAllData,PermissionsExportReport FROM PermissionSet WHERE Name IN :NAMES AND IsOwnedByProfile = false WITH USER_MODE]) {
                Role role = new Role();
                role.broad = p.PermissionsViewAllData || p.PermissionsModifyAllData || p.PermissionsExportReport;
                role.api = p.PermissionsApiEnabled;
                role.apiOnly = p.PermissionsApiUserOnly;
                roles.put(p.Name,role);
                ids.put(p.Id,p.Name);
            }
            Set<Id> roleIds = ids.keySet();
            for (ObjectPermissions p : [SELECT ParentId,SobjectType,PermissionsRead,PermissionsCreate,PermissionsEdit,PermissionsDelete,PermissionsViewAllRecords,PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId IN :roleIds WITH USER_MODE]) roles.get(ids.get(p.ParentId)).objects.add(p);
            for (FieldPermissions p : [SELECT ParentId,SobjectType,Field,PermissionsRead,PermissionsEdit FROM FieldPermissions WHERE ParentId IN :roleIds WITH USER_MODE]) roles.get(ids.get(p.ParentId)).fields.add(p);
            Map<Id,String> customNames = new Map<Id,String>();
            for (CustomPermission p : [SELECT Id,DeveloperName FROM CustomPermission WITH USER_MODE]) customNames.put(p.Id,p.DeveloperName);
            Map<Id,String> classNames = new Map<Id,String>();
            for (ApexClass p : [SELECT Id,Name FROM ApexClass WITH USER_MODE]) classNames.put(p.Id,p.Name);
            for (SetupEntityAccess p : [SELECT ParentId,SetupEntityId,SetupEntityType FROM SetupEntityAccess WHERE ParentId IN :roleIds WITH USER_MODE]) {
                Role role = roles.get(ids.get(p.ParentId));
                if (p.SetupEntityType == 'CustomPermission') role.customs.add(customNames.get(p.SetupEntityId));
                if (p.SetupEntityType == 'ApexClass') role.classes.add(classNames.get(p.SetupEntityId));
            }
            observed = true;
        } catch (Exception e) {
            // Never turn inaccessible setup metadata into a successful control check.
            roles.clear();
        }
        return JSON.serialize(evaluate(roles,observed));
    }
    private static Boolean positiveObjects(Role role) {
        for (ObjectPermissions p : role.objects) if (p.PermissionsRead || p.PermissionsCreate || p.PermissionsEdit || p.PermissionsDelete || p.PermissionsViewAllRecords || p.PermissionsModifyAllRecords) return true;
        return false;
    }
    private static Boolean positiveFields(Role role) {
        for (FieldPermissions p : role.fields) if (p.PermissionsRead || p.PermissionsEdit) return true;
        return false;
    }
    private static Boolean readonlyRole(Role role) {
        if (role == null || role.broad) return false;
        for (ObjectPermissions p : role.objects) if (p.PermissionsCreate || p.PermissionsEdit || p.PermissionsDelete || p.PermissionsViewAllRecords || p.PermissionsModifyAllRecords) return false;
        for (FieldPermissions p : role.fields) if (p.PermissionsEdit) return false;
        return true;
    }
    private static Boolean rawStaff(Role role) {
        if (role == null) return true;
        for (ObjectPermissions p : role.objects) if (p.SobjectType == 'AI_Readiness_Staff_Review__c' && (p.PermissionsRead || p.PermissionsCreate || p.PermissionsEdit)) return true;
        for (FieldPermissions p : role.fields) if (p.SobjectType == 'AI_Readiness_Staff_Review__c' && (p.PermissionsRead || p.PermissionsEdit)) return true;
        return false;
    }
    private static Boolean reviewer(Role role) {
        if (role == null || role.broad) return false;
        Boolean ownReview = false;
        for (ObjectPermissions p : role.objects) {
            if (p.SobjectType == 'AI_Readiness_Staff_Review__c') ownReview = p.PermissionsRead && p.PermissionsCreate;
            else if (p.PermissionsRead || p.PermissionsCreate) return false;
            if (p.PermissionsEdit || p.PermissionsDelete || p.PermissionsViewAllRecords || p.PermissionsModifyAllRecords) return false;
        }
        for (FieldPermissions p : role.fields) if (p.SobjectType != 'AI_Readiness_Staff_Review__c' && (p.PermissionsRead || p.PermissionsEdit)) return false;
        return ownReview;
    }
    private static Map<String,Object> check(String id,String label,Boolean passed,Boolean observed) {
        return new Map<String,Object>{'id'=>id,'label'=>label,'status'=>!observed ? 'unknown' : (passed ? 'pass' : 'fail'),'basis'=>observed ? 'Queried deployed permission-set grants; absent required roles fail.' : 'Setup metadata was inaccessible; no control outcome inferred.'};
    }
    @TestVisible private static Map<String,Object> summarize(List<Object> checks) {
        Integer complete = 0, passes = 0;
        for (Object item : checks) {
            String status = (String)((Map<String,Object>)item).get('status');
            if (status != 'unknown') complete++;
            if (status == 'pass') passes++;
        }
        return new Map<String,Object>{'score'=>complete == 0 ? null : (Decimal.valueOf(String.valueOf(passes)) * 100 / checks.size()).setScale(1,RoundingMode.HALF_UP),'coverage'=>(Decimal.valueOf(String.valueOf(complete)) * 100 / checks.size()).setScale(1,RoundingMode.HALF_UP),'checks'=>checks};
    }
    @TestVisible private static Map<String,Object> evaluate(Map<String,Role> roles,Boolean observed) {
        Role assessor = roles.get('Readiness_Assessor'), mcp = roles.get('Readiness_MCP'), staff = roles.get('Readiness_Staff_Reviewer'), reader = roles.get('Readiness_Staff_Reader'), follow = roles.get('Readiness_Follow_Up'), evidence = roles.get('Readiness_Evidence_Reviewer');
        Boolean taskGate = follow != null && follow.customs.contains('Readiness_Create_Follow_Up');
        for (Role role : new List<Role>{assessor,mcp,reader,staff,evidence}) if (role == null || role.customs.contains('Readiness_Create_Follow_Up')) taskGate = false;
        Boolean evidenceNarrow = evidence != null && !evidence.broad && !positiveObjects(evidence) && !positiveFields(evidence) && evidence.classes.equals(new Set<String>{'ReadinessEvidence'});
        List<Object> accessChecks = new List<Object>{
            check('assessor_read_only','Assessor grants are read only',readonlyRole(assessor),observed),
            check('mcp_api_only','MCP role is API only with no raw data or reviewer/task grants',mcp != null && !mcp.broad && mcp.api && mcp.apiOnly && !positiveObjects(mcp) && !positiveFields(mcp) && !mcp.customs.contains('Readiness_Review_Staff') && !mcp.customs.contains('Readiness_Create_Follow_Up'),observed),
            check('staff_reviewer','Staff reviewer grants create/read only on staff reviews',reviewer(staff),observed),
            check('follow_up_gate','Task custom permission is confined to follow-up role',taskGate,observed),
            check('evidence_reviewer','Evidence reviewer has only evaluator Apex and no raw data grants',evidenceNarrow,observed)};
        Boolean noDeletion = evidence != null && !evidence.broad;
        if (evidence != null) for (ObjectPermissions p : evidence.objects) if (p.PermissionsDelete || p.PermissionsModifyAllRecords) noDeletion = false;
        List<Object> privacyChecks = new List<Object>{
            check('staff_reader_raw','Staff reader has no raw staff record grants',reader != null && !reader.broad && !rawStaff(reader),observed),
            check('mcp_staff_raw','MCP has no raw staff grants',mcp != null && !mcp.broad && !rawStaff(mcp),observed),
            check('evidence_delete','Evidence reviewer has no deletion grants',noDeletion,observed)};
        return new Map<String,Object>{'version'=>'org-configuration-v1','scope'=>'deployed_readiness_roles_only','observed_at'=>Datetime.now(),'access'=>summarize(accessChecks),'privacy'=>summarize(privacyChecks),'limitations'=>new List<String>{'Permission-set configuration only; profiles, other assigned roles, sharing and effective user access are not assessed.','Privacy configuration only; runtime approvals, export blocking, stop controls and end-to-end erasure are not verified.'}};
    }
}
