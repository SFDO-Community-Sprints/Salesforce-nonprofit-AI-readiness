@IsTest
private class ReadinessOrgHealthTest {
    @TestSetup static void setup() {
        User reader=new User(Alias='healthrd',Email='health@example.invalid',EmailEncodingKey='UTF-8',LastName='Health Reader',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='GMT',ProfileId=UserInfo.getProfileId(),Username='health'+System.now().getTime()+'@example.invalid');
        insert reader;
        insert new PermissionSetAssignment(AssigneeId=reader.Id,PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Security_Reader'].Id);
    }
    @IsTest static void missingRoleNeverClaimsSetupPass() {
        Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgHealth.scan());
        System.assertEquals(4,((List<Object>)result.get('categories')).size());
        for(Object value:(List<Object>)result.get('findings')) {
            Map<String,Object> row=(Map<String,Object>)value;
            if(new Set<String>{'broad_profile','broad_assignment','guest_broad','guest_export'}.contains((String)row.get('id'))) System.assertEquals('unknown',row.get('status'));
        }
    }
    @IsTest static void nativeScanNoCalloutsOrCustomerWrites() {
        User reader=[SELECT Id FROM User WHERE Alias='healthrd'];
        System.runAs(reader) {
            Test.startTest();
            Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgHealth.scan());
            System.assertEquals(0,Limits.getCallouts());
            Test.stopTest();
            System.assertEquals('ai-readiness-health-v2',result.get('version'));
            System.assertEquals(false,result.get('readinessEstablished'));
            System.assertEquals(4,((List<Object>)result.get('inventory')).size());
            System.assertEquals(0,[SELECT COUNT() FROM Contact]);
            System.assertEquals(0,[SELECT COUNT() FROM Task]);
            System.assertEquals(5,[SELECT COUNT() FROM Readiness_Operation__c],'Only sanitized runtime observations are written');
        }
    }
    @IsTest static void missingEvidenceEarnsNoPoints() {
        List<Object> rows=new List<Object>{
            ReadinessOrgHealth.finding('pass','Pass','Data quality','High','pass','0','0','Review',''),
            ReadinessOrgHealth.finding('unknown','Missing','Data quality','High','unknown','Unavailable','0','Review','')};
        Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgHealth.summarize(rows,new List<Object>()));
        System.assertEquals(50,result.get('score'));
        System.assertEquals(50,result.get('coverage'));
        System.assertEquals('Incomplete',result.get('rating'));
        System.assertEquals(1,result.get('unknown'));
        Map<String,Object> empty=ReadinessOrgHealth.category('empty','Absent',rows);
        System.assertEquals(null,empty.get('score'));
    }
    @IsTest static void criticalFailureBlocksEvenWithOtherPasses() {
        List<Object> rows=new List<Object>{
            ReadinessOrgHealth.finding('pass','Pass','Data quality','High','pass','0','0','Review',''),
            ReadinessOrgHealth.finding('leak','Leak','Access and safeguards','Critical','fail','Unsafe','Denied','Fix','')};
        Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgHealth.summarize(rows,new List<Object>()));
        System.assertEquals(1,result.get('criticalFailures'));
        System.assert(((String)result.get('banner')).startsWith('Blocked:'));
        System.assertEquals(false,result.get('readinessEstablished'));
    }    @IsTest static void retainedCanaryIsNotErasurePass() {
        System.assert(ReadinessOperationalLog.recordEvent('erasure_probe','source_deletion','pass'));
        System.assert(ReadinessOperationalLog.recordEvent('erasure_probe','recycle_bin','fail'));
        Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(ReadinessOrgHealth.scan());
        Boolean retained=false;
        Integer categoryChecks=0;
        for(Object value:(List<Object>)result.get('categories')) categoryChecks+=Integer.valueOf(((Map<String,Object>)value).get('total'));
        System.assertEquals(result.get('total'),categoryChecks,'Every finding belongs to exactly one scored category');
        for(Object value:(List<Object>)result.get('findings')) {
            Map<String,Object> row=(Map<String,Object>)value;
            if(row.get('id')=='recycle_bin') {retained=true;System.assertEquals('fail',row.get('status'));}
            if(row.get('id')=='source_deletion') System.assertEquals('pass',row.get('status'));
        }
        System.assert(retained);
    }

}
