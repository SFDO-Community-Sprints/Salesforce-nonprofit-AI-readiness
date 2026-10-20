/** Runs a disposable Contact deletion observation; never claims downstream erasure. */
public with sharing class ReadinessErasureProbe {
    public class ProbeException extends Exception {}
    @TestVisible private static Boolean failAfterInsert = false;

    @AuraEnabled(cacheable=true)
    public static String targetHost() { return URL.getOrgDomainUrl().getHost(); }

    @AuraEnabled
    public static String run(String expectedHost, Boolean confirmed) {
        if (!FeatureManagement.checkPermission('Readiness_Run_Erasure_Probe'))
            throw new ProbeException('Erasure tester permission required.');
        String host = URL.getOrgDomainUrl().getHost();
        // The platform-issued scratch domain is authoritative and needs no Setup visibility grant.
        verifyTarget(expectedHost, host, host.endsWith('.scratch.my.salesforce.com'), confirmed);
        return JSON.serialize(measure());
    }

    @TestVisible private static void verifyTarget(String expectedHost, String actualHost,
                                                  Boolean sandbox, Boolean confirmed) {
        if (confirmed != true || sandbox != true || String.isBlank(expectedHost) ||
            expectedHost != actualHost || !actualHost.endsWith('.scratch.my.salesforce.com'))
            throw new ProbeException('Confirm the exact scratch org host before creating the fictional canary.');
    }

    @TestVisible private static Map<String,Object> measure() {
        if (!FeatureManagement.checkPermission('Readiness_Run_Erasure_Probe'))
            throw new ProbeException('Erasure tester permission required.');
        Map<String,Object> report = new Map<String,Object>{
            'version'=>'source-erasure-v1', 'observedAt'=>Datetime.now(),
            'scope'=>'One newly created fictional Contact; no existing records selected',
            'status'=>'failed', 'sourceActiveAbsent'=>'unknown',
            'recycleBinErased'=>'unknown', 'cleanup'=>'not_needed', 'aggregateExclusion'=>'unknown'
        };
        List<Object> external = new List<Object>();
        for (String category : new List<String>{'integrations','logs','backups','exports','agent_output'}) {
            external.add(new Map<String,Object>{'category'=>category,'status'=>'unknown',
                'required_binding'=>'Bind the actual '+category+' system to a deletion and retention verifier; Salesforce soft deletion cannot verify this destination.'});
        }
        report.put('external', external);
        Savepoint boundary = Database.setSavepoint();
        Contact canary = new Contact(LastName='SYNTHETIC Readiness erasure '+
            EncodingUtil.convertToHex(Crypto.generateAesKey(128)));
        Boolean deleted = false;
        try {
            insert as user canary;
            report.put('cleanup','pending');
            if (failAfterInsert) throw new ProbeException('Injected failure for cleanup verification.');
            Map<String,Object> binds = new Map<String,Object>{'canaryId'=>canary.Id};
            List<SObject> active = Database.queryWithBinds(
                'SELECT Id FROM Contact WHERE Id = :canaryId', binds, AccessLevel.USER_MODE);
            if (active.size()!=1) throw new ProbeException('Canary read verification failed.');
            Integer withCanary = [SELECT COUNT() FROM Contact WITH USER_MODE];
            delete as user canary;
            deleted = true;
            Integer withoutCanary = [SELECT COUNT() FROM Contact WITH USER_MODE];
            report.put('aggregateExclusion',withoutCanary == withCanary-1 ? 'pass' : 'unknown');
            report.put('cleanup','soft_deleted');
            active = Database.queryWithBinds('SELECT Id FROM Contact WHERE Id = :canaryId', binds, AccessLevel.USER_MODE);
            List<SObject> retained = Database.queryWithBinds(
                'SELECT Id, IsDeleted FROM Contact WHERE Id = :canaryId ALL ROWS', binds, AccessLevel.USER_MODE);
            report.put('sourceActiveAbsent',active.isEmpty() ? 'pass' : 'fail');
            Boolean recoverable = retained.size()==1 && (Boolean)retained[0].get('IsDeleted');
            report.put('recycleBinErased',recoverable ? 'fail' : 'unknown');
            report.put('recycleBinRecoverable',recoverable);
            report.put('status','observed');
            report.put('limitation','Soft deletion leaves a recoverable recycle-bin record. No purge or downstream erasure performed.');
        } catch (Exception ignored) {
            report.put('status','failed');
            report.put('error','Probe failed; no existing records were selected. See cleanup outcome.');
        } finally {
            if (canary.Id != null && !deleted) {
                try {
                    delete as user canary;
                    report.put('cleanup','soft_deleted');
                } catch (Exception ignored) {
                    Database.rollback(boundary);
                    report.put('cleanup','cleanup_failed_rolled_back');
                    report.put('status','failed');
                }
            }
        }
        report.put('eventRecorded',ReadinessOperationalLog.recordEvent('erasure_probe','erasure_execution',
            report.get('status') == 'observed' ? 'pass' : 'fail'));
        return report;
    }
}
