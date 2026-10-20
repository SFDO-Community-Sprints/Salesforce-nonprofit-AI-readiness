public with sharing class ReadinessDemoSeed {
    public class SeedException extends Exception {}
    public static void seed(String expectedHost) {
        requireScratch(expectedHost);
        seedScenarios();
    }
    public static void seedFailures(String expectedHost) {
        requireScratch(expectedHost);
        seedFailureContacts();
    }
    @TestVisible private static void requireScratch(String expectedHost) {
        String host = URL.getOrgDomainUrl().getHost();
        if (String.isBlank(expectedHost) || host != expectedHost ||
            !host.endsWith('.scratch.my.salesforce.com') ||
            ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
            throw new SeedException('Seed refused: expected an explicitly selected scratch org.');
        }
    }
    @TestVisible private static void seedScenarios() {
        List<Object> groups = (List<Object>)JSON.deserializeUntyped(
            [SELECT Body FROM StaticResource WHERE Name='ReadinessSeedData' LIMIT 1].Body.toString());
        Savepoint boundary = Database.setSavepoint();
        try {
            for (Object value : groups) {
                Map<String,Object> scenarioData = (Map<String,Object>)value;
                String name = (String)scenarioData.get('name');
                List<Account> accounts = [SELECT Id FROM Account WHERE Name=:name];
                if (accounts.size() > 1) throw new SeedException('Ambiguous fictional seed account; no changes retained.');
                Boolean exists = !accounts.isEmpty();
                Account account = exists ? accounts[0] : new Account(Name=name);
                if (!exists) insert account;
                List<Contact> expected = new List<Contact>();
                for (Object raw : (List<Object>)scenarioData.get('contacts')) {
                    Map<String,Object> item = (Map<String,Object>)raw;
                    expected.add(new Contact(AccountId=account.Id,LastName=(String)item.get('lastName'),Email=(String)item.get('email')));
                }
                if (exists) verifyContacts([SELECT LastName,Email,AccountId FROM Contact WHERE AccountId=:account.Id],expected);
                else if (!expected.isEmpty()) insert expected;
            }
        } catch (Exception ignored) {
            Database.rollback(boundary);
            throw new SeedException('Seed failed or existing demo data differs; no changes retained.');
        }
    }
    @TestVisible private static List<Contact> failureContacts() {
        List<Contact> expected = new List<Contact>();
        for (Integer i=1;i<=60;i++) expected.add(new Contact(
            LastName='SYNTHETIC AI Failure Demo '+String.valueOf(i).leftPad(2,'0'),
            Email=i<=10 ? 'synthetic-failure-demo@example.invalid' : null));
        return expected;
    }
    @TestVisible private static void seedFailureContacts() {
        List<Contact> expected = failureContacts();
        List<Contact> existing = [SELECT LastName,Email,AccountId FROM Contact
            WHERE LastName LIKE 'SYNTHETIC AI Failure Demo %'];
        if (!existing.isEmpty()) verifyContacts(existing,expected);
        else insert expected;
    }
    private static void verifyContacts(List<Contact> existing,List<Contact> expected) {
        Map<String,Contact> byName = new Map<String,Contact>();
        for (Contact row : expected) byName.put(row.LastName,row);
        if (existing.size()!=expected.size()) throw new SeedException('Incomplete fictional seed; no changes retained.');
        for (Contact row : existing) {
            Contact match = byName.remove(row.LastName);
            if (match==null || row.Email!=match.Email || row.AccountId!=match.AccountId)
                throw new SeedException('Fictional seed differs; no changes retained.');
        }
    }
}
