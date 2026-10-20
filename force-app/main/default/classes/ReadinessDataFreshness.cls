public with sharing class ReadinessDataFreshness {
    @AuraEnabled
    public static String assess(String policyVersion, Integer windowDays, Integer minimumRecentPercent, Integer minimumCohort) {
        Datetime asOf = utcDay(System.now());
        if (!validPolicy(policyVersion,windowDays,minimumRecentPercent,minimumCohort)
            || !validWindow(asOf.dateGmt(),windowDays)) {
            return JSON.serialize(new Map<String,Object>{'error'=>'invalid_freshness_policy'});
        }
        Integer records;
        Integer recentRecords;
        try {
            Date today = asOf.dateGmt();
            Date cutoff = today.addDays(-windowDays);
            records = [SELECT COUNT() FROM Contact WITH USER_MODE];
            recentRecords = [SELECT COUNT() FROM Contact WHERE LastActivityDate >= :cutoff
                AND LastActivityDate <= :today WITH USER_MODE];
        } catch (Exception ignored) {
            // Query errors can contain identifying data; return missing evidence instead.
            records = null;
            recentRecords = null;
        }
        return JSON.serialize(evaluate(policyVersion,windowDays,minimumRecentPercent,minimumCohort,
            asOf,records,recentRecords));
    }

    @TestVisible private static Datetime utcDay(Datetime instant) {
        return Datetime.newInstanceGmt(instant.dateGmt(),Time.newInstance(0,0,0,0));
    }

    private static Boolean validWindow(Date day,Integer days) {
        return days != null && days > 0 && days <= Date.newInstance(1,1,1).daysBetween(day);
    }

    private static Boolean validPolicy(String version,Integer days,Integer percent,Integer cohort) {
        return version != null && Pattern.matches('[a-zA-Z0-9_-]{1,80}',version)
            && days != null && days > 0 && percent != null && percent >= 0 && percent <= 100
            && cohort != null && cohort >= 5;
    }

    @TestVisible private static Map<String,Object> evaluate(String version,Integer days,Integer percent,
        Integer cohort,Datetime asOf,Integer records,Integer recentRecords) {
        if (!validPolicy(version,days,percent,cohort) || asOf == null
            || !validWindow(asOf.dateGmt(),days)
            || (records == null && recentRecords != null) || (records != null &&
                (recentRecords == null || records < 0 || recentRecords < 0 || recentRecords > records))) {
            throw new IllegalArgumentException('Invalid freshness evidence');
        }
        String status = 'unknown';
        String reason = 'missing_evidence';
        Map<String,Integer> metrics;
        if (records != null) {
            if (records < cohort) reason = 'cohort_withheld';
            else {
                status = Decimal.valueOf(String.valueOf(recentRecords)) * 100 >=
                    Decimal.valueOf(String.valueOf(records)) * percent ? 'pass' : 'fail';
                reason = 'measured';
                metrics = new Map<String,Integer>{'records'=>records,'recent_records'=>recentRecords};
            }
        }
        return new Map<String,Object>{'version'=>'data-freshness-v1','as_of'=>asOf,
            'policy'=>new Map<String,Object>{'version'=>version,'window_days'=>days,
                'minimum_recent_percent'=>percent,'minimum_cohort'=>cohort},
            'metrics'=>metrics,'freshness'=>new Map<String,Object>{
                'checks'=>new Map<String,String>{'freshness'=>status},'passed'=>status == 'pass' ? 1 : 0,
                'applicable'=>1,'score'=>status == 'pass' ? '100.0' : '0.0',
                'coverage'=>status == 'unknown' ? '0.0' : '100.0'},
            'reason'=>reason,'decision'=>'readiness_not_established',
            'scope'=>'accessible_organization_records',
            'coverage_note'=>'Only accessible Contacts are assessed. LastActivityDate within the approved window is an activity indicator, not proof that contact details are current. Missing and future activity dates do not count as recent.'};
    }
}
