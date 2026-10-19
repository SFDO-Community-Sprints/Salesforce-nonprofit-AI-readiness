public with sharing class ReadinessStaffReview {
    private static final Set<String> ANSWERS = new Set<String>{'yes','partly','no','unknown'};
    private static final Set<String> REVIEW_FIELDS = new Set<String>{'question_id','answer','reviewer_confirmed','evidence_ref','actions','critical_failures'};
    private class InvalidEvidenceException extends Exception {}

    private static Map<String,Object> answerKey() {
        return (Map<String,Object>)JSON.deserializeUntyped([SELECT Body FROM StaticResource
            WHERE Name = 'StaffReadinessAnswerKey' LIMIT 1].Body.toString());
    }
    @AuraEnabled(cacheable=true)
    public static String getQuestions() {
        return JSON.serialize(answerKey());
    }
    @AuraEnabled
    public static String saveReview(String snapshot) {
        if (!FeatureManagement.checkPermission('Readiness_Review_Staff')) return error('review_not_permitted');
        if (snapshot == null || snapshot.length() > 32768) return error('review_unavailable');
        try {
            Map<String,Object> input = (Map<String,Object>)JSON.deserializeUntyped(snapshot);
            Map<String,Object> result = evaluate(input);
            AI_Readiness_Staff_Review__c record = new AI_Readiness_Staff_Review__c(
                Snapshot__c=JSON.serialize(input), Version__c=(String)result.get('version'));
            insert as user record;
            result.put('reviewed_at', Datetime.now());
            return JSON.serialize(result);
        } catch (Exception ignored) {
            return error('review_unavailable');
        }
    }
    @AuraEnabled
    public static String getLatestReview() {
        try {
            List<AI_Readiness_Staff_Review__c> records = [SELECT Snapshot__c, CreatedDate
                FROM AI_Readiness_Staff_Review__c WHERE OwnerId = :UserInfo.getUserId()
                WITH USER_MODE ORDER BY CreatedDate DESC, Id DESC LIMIT 1];
            if (records.isEmpty()) return 'null';
            Map<String,Object> result = evaluate((Map<String,Object>)JSON.deserializeUntyped(records[0].Snapshot__c));
            result.put('reviewed_at', records[0].CreatedDate);
            return JSON.serialize(result);
        } catch (Exception ignored) {
            return error('review_unavailable');
        }
    }
    private static String error(String code) {
        return JSON.serialize(new Map<String,Object>{'error'=>code});
    }
    private static void require(Boolean condition) {
        if (!condition) throw new InvalidEvidenceException('Invalid structured exercise evidence');
    }
    private static Boolean canonical(Object value) {
        return value instanceof String && Pattern.matches('[A-Za-z0-9_-]{1,80}', (String)value);
    }
    private static Set<String> ids(List<Object> definitions) {
        Set<String> result = new Set<String>();
        for (Object definition : definitions) result.add((String)((Map<String,Object>)definition).get('id'));
        return result;
    }
    @TestVisible
    private static Map<String,Object> evaluate(Map<String,Object> input) {
        Map<String,Object> key = answerKey();
        require(input != null && input.keySet().equals(new Set<String>{'version','mode','reviews'}));
        require(input.get('version') == key.get('version') && input.get('mode') == 'actual');
        require(input.get('reviews') instanceof List<Object>);
        List<Object> reviews = (List<Object>)input.get('reviews');
        require(reviews.size() <= 7);
        Map<String,Map<String,Object>> questions = new Map<String,Map<String,Object>>();
        Map<String,String> checks = new Map<String,String>();
        List<String> questionOrder = new List<String>();
        for (Object value : (List<Object>)key.get('questions')) {
            Map<String,Object> question = (Map<String,Object>)value;
            String qid = (String)question.get('id');
            questions.put(qid, question); checks.put(qid, 'unknown'); questionOrder.add(qid);
        }
        Set<String> seen = new Set<String>();
        List<String> critical = new List<String>();
        for (Object value : reviews) {
            require(value instanceof Map<String,Object>);
            Map<String,Object> review = (Map<String,Object>)value;
            require(review.keySet().equals(REVIEW_FIELDS));
            require(review.get('question_id') instanceof String);
            String qid = (String)review.get('question_id');
            require(questions.containsKey(qid) && !seen.contains(qid)); seen.add(qid);
            Map<String,Object> question = questions.get(qid);
            require(review.get('answer') instanceof String && ANSWERS.contains((String)review.get('answer')));
            require(review.get('reviewer_confirmed') instanceof Boolean);
            require(review.get('evidence_ref') == null || canonical(review.get('evidence_ref')));
            require(review.get('actions') instanceof Map<String,Object> && review.get('critical_failures') instanceof List<Object>);
            Map<String,Object> actions = (Map<String,Object>)review.get('actions');
            Set<String> requiredActions = ids((List<Object>)question.get('required_actions'));
            require(requiredActions.containsAll(actions.keySet()));
            Boolean failedAction = false; Boolean allYes = true;
            for (Object answer : actions.values()) {
                require(answer instanceof String && ANSWERS.contains((String)answer));
                if (answer == 'partly' || answer == 'no') failedAction = true;
                if (answer != 'yes') allYes = false;
            }
            Set<String> allowedFailures = ids((List<Object>)question.get('critical_failures'));
            Set<String> failures = new Set<String>();
            for (Object failure : (List<Object>)review.get('critical_failures')) {
                require(failure instanceof String && allowedFailures.contains((String)failure) && !failures.contains((String)failure));
                failures.add((String)failure);
            }
            if (!(Boolean)review.get('reviewer_confirmed') || review.get('evidence_ref') == null) continue;
            if (!failures.isEmpty()) {
                checks.put(qid, 'fail');
                for (String failure : failures) critical.add(qid + ':' + failure);
            } else if (review.get('answer') == 'partly' || review.get('answer') == 'no' || failedAction) {
                checks.put(qid, 'fail');
            } else if (review.get('answer') == 'yes' && actions.keySet().equals(requiredActions) && allYes) {
                checks.put(qid, 'pass');
            }
        }
        Integer passed = 0; Integer failed = 0;
        List<Object> urgent = new List<Object>(); List<Object> high = new List<Object>(); List<Object> medium = new List<Object>();
        for (String qid : questionOrder) {
            String status = checks.get(qid);
            if (status == 'pass') { passed++; continue; }
            if (status == 'fail') failed++;
            Boolean hasCritical = false;
            for (String failure : critical) if (failure.startsWith(qid + ':')) hasCritical = true;
            String priority = hasCritical ? 'Critical' : status == 'fail' ? 'High' : 'Medium';
            String nextStep = 'Demonstrate:';
            for (Object action : (List<Object>)questions.get(qid).get('required_actions')) {
                nextStep += ' ' + (String)((Map<String,Object>)action).get('criterion');
            }
            Map<String,Object> followUp = new Map<String,Object>{'question_id'=>qid,'priority'=>priority,
                'impact'=>hasCritical ? 'An observed unsafe action blocks a pilot until corrected and retested.' :
                    status == 'fail' ? 'Required staff actions were not fully demonstrated.' : 'Staff capability has not been established by confirmed evidence.',
                'next_step'=>nextStep};
            if (hasCritical) urgent.add(followUp); else if (status == 'fail') high.add(followUp); else medium.add(followUp);
        }
        urgent.addAll(high); urgent.addAll(medium); critical.sort();
        Decimal score = (Decimal.valueOf(String.valueOf(passed)) * 100 / 7).setScale(1, RoundingMode.HALF_UP);
        Decimal coverage = (Decimal.valueOf(String.valueOf(passed + failed)) * 100 / 7).setScale(1, RoundingMode.HALF_UP);
        return new Map<String,Object>{'version'=>key.get('version'),'evidence_mode'=>'reviewer_confirmed_observations',
            'staff'=>new Map<String,Object>{'checks'=>checks,'score'=>score,'coverage'=>coverage,'passed'=>passed,
                'failed'=>failed,'unknown'=>7-passed-failed,'applicable'=>7},
            'critical_failures'=>critical,'follow_up'=>urgent,
            'decision'=>!critical.isEmpty() ? 'blocked_by_observed_critical_failure' : passed == 7 ? 'staff_evidence_complete' : 'staff_readiness_not_established',
            'scope'=>'reviewer_confirmed_exercises_only',
            'limitation'=>'Reviewer-confirmed exercises only; no organization-wide training, technical control, legal compliance or pilot approval is established.'};
    }
}
