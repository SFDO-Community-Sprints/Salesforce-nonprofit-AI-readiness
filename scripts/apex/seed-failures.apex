// Self-contained anonymous Apex. Fictional data only; restricted to scratch orgs.
String host = URL.getOrgDomainUrl().getHost();
if (!host.endsWith('.scratch.my.salesforce.com') ||
    ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('Demo seeding requires a scratch org.');
}
// Optional: deliberately worsens organization-wide data quality scores.
List<Contact> expected = new List<Contact>();
for (Integer i=1;i<=60;i++) expected.add(new Contact(
    LastName='SYNTHETIC AI Failure Demo '+String.valueOf(i).leftPad(2,'0'),
    Email=i<=10 ? 'synthetic-failure-demo@example.invalid' : null));
List<Contact> existing = [SELECT LastName,Email,AccountId FROM Contact
    WHERE LastName LIKE 'SYNTHETIC AI Failure Demo %'];
if (!existing.isEmpty()) {
        Map<String,Contact> byName = new Map<String,Contact>();
        for (Contact row : expected) byName.put(row.LastName,row);
        if (existing.size()!=expected.size()) throw new IllegalArgumentException('Incomplete fictional seed.');
        for (Contact row : existing) {
            Contact match = byName.remove(row.LastName);
            if (match==null || row.Email!=match.Email || row.AccountId!=match.AccountId)
                throw new IllegalArgumentException('Fictional seed differs.');
        }
} else insert expected;
System.debug('Optional fictional failures seeded or verified unchanged.');
