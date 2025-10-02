public class TestDataGeneratorSafe {
    public static void createTestData() {
        List<Campaign> campaigns = new List<Campaign>();
        List<Contact> contacts = new List<Contact>();
        List<Account> accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        // Step 1: Create 5 Campaigns
        for (Integer i = 1; i <= 5; i++) {
            campaigns.add(new Campaign(
                Name = 'Test Campaign ' + i,
                Status = 'Planned',
                Type = 'Email',
                StartDate = Date.today(),
                EndDate = Date.today().addDays(30)
            ));
        }
        insert campaigns;

        // Step 2: Create 5 Accounts and Contacts
        for (Integer i = 1; i <= 5; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            accounts.add(acc);
        }
        insert accounts;

        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'First' + i,
                LastName = 'Last' + i,
                Email = 'test' + i + '@example.com',
                AccountId = accounts[i].Id
            ));
        }
        insert contacts;

        // Step 3: Create 5 Opportunities
        for (Integer i = 0; i < 5; i++) {
            opportunities.add(new Opportunity(
                Name = 'Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(60),
                AccountId = contacts[i].AccountId,
                Amount = 10000 + i * 1000
            ));
        }
        insert opportunities;

        // Step 4: Add Campaign Members
        for (Integer i = 0; i < 5; i++) {
            campaignMembers.add(new CampaignMember(
                CampaignId = campaigns[i].Id,
                ContactId = contacts[i].Id,
                Status = 'Sent'
            ));
        }
        insert campaignMembers;

        System.debug('✔ Test data created: Campaigns, Contacts, Accounts, Opportunities, CampaignMembers');
    }
}