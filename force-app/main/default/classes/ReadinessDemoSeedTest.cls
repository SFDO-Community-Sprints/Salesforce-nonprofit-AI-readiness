@IsTest private class ReadinessDemoSeedTest {
    @IsTest static void seedsAndRepeatsWithoutDuplicates() {
        ReadinessDemoSeed.seedScenarios();
        System.assertEquals(5,[SELECT COUNT() FROM Account]);
        System.assertEquals(34,[SELECT COUNT() FROM Contact]);
        ReadinessDemoSeed.seedScenarios();
        System.assertEquals(5,[SELECT COUNT() FROM Account]);
        System.assertEquals(34,[SELECT COUNT() FROM Contact]);
        for (Contact row : [SELECT Email FROM Contact WHERE Email != null]) System.assert(row.Email.endsWith('@example.invalid'));
    }
    @IsTest static void mismatchedExistingDataRollsBackOtherGroups() {
        Account conflicting = new Account(Name='SYNTHETIC AI Readiness pilot');
        insert conflicting;
        insert new Contact(AccountId=conflicting.Id,LastName='Existing unrelated record');
        Boolean rejected=false;
        try { ReadinessDemoSeed.seedScenarios(); } catch (ReadinessDemoSeed.SeedException expected) { rejected=true; }
        System.assert(rejected);
        System.assertEquals(1,[SELECT COUNT() FROM Account]);
        System.assertEquals(1,[SELECT COUNT() FROM Contact]);
        System.assertEquals('Existing unrelated record',[SELECT LastName FROM Contact LIMIT 1].LastName);
    }
    @IsTest static void duplicateAccountIsRejected() {
        insert new List<Account>{new Account(Name='SYNTHETIC AI Readiness poor'),new Account(Name='SYNTHETIC AI Readiness poor')};
        try { ReadinessDemoSeed.seedScenarios(); System.assert(false); } catch (ReadinessDemoSeed.SeedException expected) {}
        System.assertEquals(0,[SELECT COUNT() FROM Contact]);
    }
    @IsTest static void optionalFailuresRepeatAndRejectChanges() {
        ReadinessDemoSeed.seedFailureContacts();
        ReadinessDemoSeed.seedFailureContacts();
        System.assertEquals(60,[SELECT COUNT() FROM Contact]);
        System.assertEquals(10,[SELECT COUNT() FROM Contact WHERE Email!=null]);
        System.assertEquals(0,[SELECT COUNT() FROM Contact WHERE AccountId!=null]);
        Contact changed=[SELECT Id,Email FROM Contact LIMIT 1]; changed.Email='changed@example.invalid'; update changed;
        try { ReadinessDemoSeed.seedFailureContacts(); System.assert(false); } catch (ReadinessDemoSeed.SeedException expected) {}
        System.assertEquals(60,[SELECT COUNT() FROM Contact]);
    }
    @IsTest static void refusesWrongTargetBeforeWrites() {
        try { ReadinessDemoSeed.seed('wrong.scratch.my.salesforce.com'); System.assert(false); }
        catch (ReadinessDemoSeed.SeedException expected) {}
        try { ReadinessDemoSeed.seedFailures(null); System.assert(false); }
        catch (ReadinessDemoSeed.SeedException expected) {}
        System.assertEquals(0,[SELECT COUNT() FROM Account]);
        System.assertEquals(0,[SELECT COUNT() FROM Contact]);
    }
}
