// AI Readiness Check: demo data.
// Run with:  sf apex run --file scripts/apex/seed-demo.apex --target-org air-demo
// Requires the AIR_Admin permission set on the running user.
// WARNING: deletes all existing AIR assessments and use cases, so the demo starts clean.

// Org scan first: some checks read setup data through an internal callout, which fails after DML.
Id orgScanId = AIR_ScanService.runOrgScan();

delete [SELECT Id FROM AIR_Assessment__c WHERE Id != :orgScanId];
delete [SELECT Id FROM AIR_Use_Case__c];

// A dedicated integration user for the first use case, if the org has one.
Id integrationUserId = null;
for (User u : [
    SELECT Id
    FROM User
    WHERE IsActive = TRUE AND Profile.UserLicense.Name = 'Salesforce Integration'
    LIMIT 1
]) {
    integrationUserId = u.Id;
}

List<AIR_Use_Case__c> useCases = new List<AIR_Use_Case__c>{
    new AIR_Use_Case__c(
        Name = 'Donor FAQ agent',
        Status__c = 'Approved',
        Business_Owner__c = 'Head of Supporter Care',
        Agent_User__c = integrationUserId,
        Description__c = 'An agent on the website that answers common supporter questions (Gift Aid, changing a direct debit, receipts) from Knowledge articles and hands over to supporter care when needed.',
        Added_Value__c = 'Supporters get answers outside office hours; the supporter care team spends less time on repeat questions.',
        What_We_Lose__c = 'Some personal contact with supporters, and the chance to spot vulnerable supporters early.',
        Mitigation__c = 'The agent hands over on complaints, vulnerability signals and payment issues. Monthly review of transcripts.',
        Handover_Points__c = 'Hand over to a person for complaints, bereavement, payment changes and any request about another person. The supporter is told up front that they are talking to AI.',
        Success_Criteria__c = '40% of FAQ contacts resolved without a person, satisfaction at least 4/5, no data incidents in the first 3 months.',
        Expected_Costs__c = 6000,
        Expected_Gains__c = 15000,
        Cost_Benefit_Notes__c = 'Licence and set-up costs are covered by the time saved in supporter care within the first year.',
        Data_In_Scope__c = 'Knowledge articles; the supporter\'s own contact details and recurring donation status.',
        Grounding_Fields__c = 'Contact.Email\nContact.MailingCountry\nContact.LeadSource\nAccount.Name'
    ),
    new AIR_Use_Case__c(
        Name = 'Gift aid email drafting',
        Status__c = 'Idea',
        Business_Owner__c = 'Fundraising Operations',
        Description__c = 'Draft Gift Aid declaration reminder emails for donors who gave without a declaration.',
        Added_Value__c = 'More Gift Aid claimed with less manual work.',
        Grounding_Fields__c = 'Contact.Email\nContact.MailingPostalCode\nOpportunity.Amount'
    )
};
insert useCases;

// Company checklist: about half answered; no DPO yet, so a critical failure shows.
Map<String, String> companyAnswers = new Map<String, String>{
    'C01_DPO' => 'No',
    'C02_SecurityOwner' => 'Yes',
    'C03_AdminOwner' => 'Yes',
    'C05_LlmPolicy' => 'Partially',
    'C08_StaffTraining' => 'No'
};
List<Map<String, Object>> answers = new List<Map<String, Object>>();
for (String code : companyAnswers.keySet()) {
    answers.add(new Map<String, Object>{ 'code' => code, 'answer' => companyAnswers.get(code) });
}
AIR_Controller.saveChecklist(
    'Company',
    null,
    JSON.serialize(answers),
    JSON.serialize(
        new Map<String, Object>{
            'securityOwner' => 'IT Manager',
            'adminOwner' => 'Salesforce Admin',
            'stakeholders' => 'Director of Fundraising; Board (quarterly update); implementation partner'
        }
    )
);

// Implementation checklist for the first use case, partly answered.
Map<String, String> implementationAnswers = new Map<String, String>{
    'I01_NarrowScope' => 'Yes',
    'I02_DedicatedPermSet' => 'Partially',
    'I04_Handover' => 'Yes',
    'I07_BusinessOwner' => 'Yes',
    'I10_DPIA' => 'No'
};
answers = new List<Map<String, Object>>();
for (String code : implementationAnswers.keySet()) {
    answers.add(new Map<String, Object>{ 'code' => code, 'answer' => implementationAnswers.get(code) });
}
AIR_Controller.saveChecklist('Implementation', useCases[0].Id, JSON.serialize(answers), null);

System.debug('AIR demo data created.');
