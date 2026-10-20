// Self-contained anonymous Apex. Fictional data only; deliberately pinned to this scratch org.
String expectedHost = 'data-connect-7516-dev-ed.scratch.my.salesforce.com';
String host = URL.getOrgDomainUrl().getHost();
if (host != expectedHost || !host.endsWith('.scratch.my.salesforce.com') ||
    ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('Seed refused: expected the explicitly selected scratch org.');
}
String fixtureJson = '[{"name":"SYNTHETIC AI Readiness poor","contacts":[{"lastName":"SYNTHETIC poor Donor 1","email":"poor-donor-0@example.invalid"},{"lastName":"SYNTHETIC poor Donor 2","email":null},{"lastName":"SYNTHETIC poor Donor 3","email":null},{"lastName":"SYNTHETIC poor Donor 4","email":null}]},{"name":"SYNTHETIC AI Readiness improving","contacts":[{"lastName":"SYNTHETIC improving Donor 1","email":"improving-donor-0@example.invalid"},{"lastName":"SYNTHETIC improving Donor 2","email":"improving-donor-0@example.invalid"},{"lastName":"SYNTHETIC improving Donor 3","email":"improving-donor-2@example.invalid"},{"lastName":"SYNTHETIC improving Donor 4","email":"improving-donor-3@example.invalid"},{"lastName":"SYNTHETIC improving Donor 5","email":"improving-donor-4@example.invalid"},{"lastName":"SYNTHETIC improving Donor 6","email":"improving-donor-5@example.invalid"},{"lastName":"SYNTHETIC improving Donor 7","email":"improving-donor-6@example.invalid"},{"lastName":"SYNTHETIC improving Donor 8","email":"improving-donor-7@example.invalid"},{"lastName":"SYNTHETIC improving Donor 9","email":null},{"lastName":"SYNTHETIC improving Donor 10","email":null}]},{"name":"SYNTHETIC AI Readiness pilot","contacts":[{"lastName":"SYNTHETIC pilot Donor 1","email":"pilot-donor-0@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 2","email":"pilot-donor-1@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 3","email":"pilot-donor-2@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 4","email":"pilot-donor-3@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 5","email":"pilot-donor-4@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 6","email":"pilot-donor-5@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 7","email":"pilot-donor-6@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 8","email":"pilot-donor-7@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 9","email":"pilot-donor-8@example.invalid"},{"lastName":"SYNTHETIC pilot Donor 10","email":"pilot-donor-9@example.invalid"}]},{"name":"SYNTHETIC AI Readiness blocked","contacts":[{"lastName":"SYNTHETIC blocked Donor 1","email":"blocked-donor-0@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 2","email":"blocked-donor-1@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 3","email":"blocked-donor-2@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 4","email":"blocked-donor-3@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 5","email":"blocked-donor-4@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 6","email":"blocked-donor-5@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 7","email":"blocked-donor-6@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 8","email":"blocked-donor-7@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 9","email":"blocked-donor-8@example.invalid"},{"lastName":"SYNTHETIC blocked Donor 10","email":"blocked-donor-9@example.invalid"}]},{"name":"SYNTHETIC AI Readiness unknown","contacts":[]}]';
List<Object> scenarios = (List<Object>)JSON.deserializeUntyped(fixtureJson);
Savepoint boundary = Database.setSavepoint();
try {
    for (Object value : scenarios) {
        Map<String,Object> scenarioData = (Map<String,Object>)value;
        String name = (String)scenarioData.get('name');
        List<Account> accounts = [SELECT Id FROM Account WHERE Name=:name];
        if (accounts.size()>1) throw new IllegalArgumentException('Ambiguous fictional seed account.');
        Boolean exists = !accounts.isEmpty();
        Account account = exists ? accounts[0] : new Account(Name=name);
        if (!exists) insert account;
        List<Contact> expected = new List<Contact>();
        for (Object raw : (List<Object>)scenarioData.get('contacts')) {
            Map<String,Object> item = (Map<String,Object>)raw;
            expected.add(new Contact(AccountId=account.Id,LastName=(String)item.get('lastName'),Email=(String)item.get('email')));
        }
        if (exists) {
            List<Contact> existing = [SELECT LastName,Email,AccountId FROM Contact WHERE AccountId=:account.Id];
        Map<String,Contact> byName = new Map<String,Contact>();
        for (Contact row : expected) byName.put(row.LastName,row);
        if (existing.size()!=expected.size()) throw new IllegalArgumentException('Incomplete fictional seed.');
        for (Contact row : existing) {
            Contact match = byName.remove(row.LastName);
            if (match==null || row.Email!=match.Email || row.AccountId!=match.AccountId)
                throw new IllegalArgumentException('Fictional seed differs.');
        }
        } else if (!expected.isEmpty()) insert expected;
    }
} catch (Exception ignored) {
    Database.rollback(boundary);
    throw new IllegalArgumentException('Seed failed or existing demo data differs; no changes retained.');
}
System.debug('Five fictional scenarios seeded or verified unchanged: 5 Accounts and 34 Contacts.');
