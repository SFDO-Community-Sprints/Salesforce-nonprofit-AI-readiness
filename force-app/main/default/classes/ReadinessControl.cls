/** Package-local execution stop; does not disable other org agents or integrations. */
public with sharing class ReadinessControl {
    public static Boolean isDisabled() {
        Id orgId = UserInfo.getOrganizationId();
        // Query org scope directly so recovery is observed even within the same transaction.
        List<Readiness_Control__c> controls = [SELECT Disabled__c FROM Readiness_Control__c
            WHERE SetupOwnerId = :orgId LIMIT 1];
        return !controls.isEmpty() && controls[0].Disabled__c;
    }
    public static String stopped() {
        return JSON.serialize(new Map<String,Object>{'error'=>'assessment_stopped'});
    }
    @AuraEnabled
    public static String status() {
        return JSON.serialize(new Map<String,Object>{'disabled'=>isDisabled(),'scope'=>'readiness_package_only'});
    }
    @AuraEnabled
    public static String setDisabled(Boolean disabled) {
        if (!FeatureManagement.checkPermission('Readiness_Manage_Control') || disabled == null) {
            return JSON.serialize(new Map<String,Object>{'error'=>'control_management_unavailable'});
        }
        try {
            Readiness_Control__c control = Readiness_Control__c.getOrgDefaults();
            control.SetupOwnerId = UserInfo.getOrganizationId();
            control.Disabled__c = disabled;
            // Narrow custom permission authorizes only this org-wide package control write.
            upsert control;
            Boolean logged = ReadinessOperationalLog.recordEvent('control','runtime_execution',disabled ? 'stopped' : 'resumed');
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(status());
            result.put('event_recorded',logged);
            return JSON.serialize(result);
        } catch (Exception ignored) {
            return JSON.serialize(new Map<String,Object>{'error'=>'control_management_unavailable'});
        }
    }
}
